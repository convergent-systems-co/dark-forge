#!/usr/bin/env python3
"""Generate a machine-readable prompt catalog from *.prompt.md files.

Scans a prompts directory recursively for ``*.prompt.md`` files, parses
YAML frontmatter from each, computes SHA-256 content hashes, and writes
a JSON catalog validated against ``governance/schemas/prompt-catalog.schema.json``.

Requires Python 3.9+ and PyYAML (``pip install pyyaml``).

Usage::

    python bin/generate-prompt-catalog.py
    python bin/generate-prompt-catalog.py --prompts-dir prompts/ --output catalog/prompt-catalog.json
    python bin/generate-prompt-catalog.py --validate
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_PROMPTS_DIR = REPO_ROOT / "prompts"
DEFAULT_OUTPUT = REPO_ROOT / "catalog" / "prompt-catalog.json"
SCHEMA_PATH = REPO_ROOT / "governance" / "schemas" / "prompt-catalog.schema.json"
CATALOG_VERSION = "1.0.0"

# Valid frontmatter status values (matches schema enum)
VALID_STATUSES = {"concept", "beta", "production"}

# ---------------------------------------------------------------------------
# YAML frontmatter parsing
# ---------------------------------------------------------------------------


def parse_frontmatter(content: str) -> dict:
    """Extract YAML frontmatter from a markdown file.

    Expects content delimited by ``---`` fences at the start of the file.
    Uses PyYAML for robust parsing.  Falls back to regex extraction if
    PyYAML is unavailable.
    """
    match = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return {}

    yaml_text = match.group(1)

    try:
        import yaml  # noqa: F811

        parsed = yaml.safe_load(yaml_text)
        return parsed if isinstance(parsed, dict) else {}
    except ImportError:
        # Fallback: simple key-value regex extraction
        return _regex_parse_yaml(yaml_text)


def _regex_parse_yaml(text: str) -> dict:
    """Minimal YAML extraction using regex (no PyYAML dependency)."""
    result: dict = {}
    for line in text.splitlines():
        m = re.match(r'^(\w[\w_-]*):\s*(.+)$', line)
        if m:
            key = m.group(1).strip()
            val = m.group(2).strip().strip("\"'")
            # Attempt list detection (inline [a, b, c])
            if val.startswith("[") and val.endswith("]"):
                val = [v.strip().strip("\"'") for v in val[1:-1].split(",") if v.strip()]
            result[key] = val
    return result


# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------


def git_last_modified(file_path: Path) -> str | None:
    """Return the ISO 8601 timestamp of the last git commit touching *file_path*.

    Returns ``None`` if not in a git repo or the file is untracked.
    """
    try:
        result = subprocess.run(
            ["git", "log", "-1", "--format=%aI", "--", str(file_path)],
            capture_output=True,
            text=True,
            cwd=REPO_ROOT,
            timeout=10,
        )
        ts = result.stdout.strip()
        if ts:
            # Normalize to UTC ISO 8601 for consistency
            dt = datetime.fromisoformat(ts).astimezone(timezone.utc)
            return dt.strftime("%Y-%m-%dT%H:%M:%SZ")
    except (subprocess.SubprocessError, OSError, ValueError):
        pass
    return None


def fs_last_modified(file_path: Path) -> str:
    """Return the ISO 8601 timestamp of the file's mtime."""
    mtime = os.path.getmtime(file_path)
    dt = datetime.fromtimestamp(mtime, tz=timezone.utc)
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


# ---------------------------------------------------------------------------
# Core catalog logic
# ---------------------------------------------------------------------------


def compute_sha256(file_path: Path) -> str:
    """Return the SHA-256 hex digest of a file's contents."""
    h = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def derive_id(file_path: Path, prompts_dir: Path) -> str:
    """Derive a unique prompt ID from the relative file path.

    Example: ``prompts/global/summarize.prompt.md`` -> ``global/summarize``
    """
    rel = file_path.relative_to(prompts_dir)
    # Remove the .prompt.md suffix
    stem = str(rel).replace(".prompt.md", "")
    # Normalize separators
    return stem.replace("\\", "/").lower()


def build_prompt_entry(file_path: Path, prompts_dir: Path) -> dict:
    """Build a single prompt catalog entry from a ``*.prompt.md`` file."""
    content = file_path.read_text(encoding="utf-8")
    fm = parse_frontmatter(content)

    prompt_id = derive_id(file_path, prompts_dir)
    name = fm.get("name", file_path.stem.replace(".prompt", "").replace("-", " ").title())
    description = fm.get("description", "")
    status = fm.get("status", "concept")
    if status not in VALID_STATUSES:
        status = "concept"

    tags = fm.get("tags", [])
    if isinstance(tags, str):
        tags = [t.strip() for t in tags.split(",") if t.strip()]

    model = fm.get("model", None)
    if model == "":
        model = None

    rel_path = str(file_path.relative_to(REPO_ROOT)).replace("\\", "/")
    content_hash = compute_sha256(file_path)

    # Prefer git timestamp, fall back to filesystem
    last_modified = git_last_modified(file_path) or fs_last_modified(file_path)

    return {
        "id": prompt_id,
        "name": str(name),
        "description": str(description),
        "status": status,
        "tags": list(tags),
        "model": model,
        "file_path": rel_path,
        "content_hash": content_hash,
        "last_modified": last_modified,
    }


def scan_prompts(prompts_dir: Path) -> list[dict]:
    """Recursively scan for ``*.prompt.md`` files and build catalog entries."""
    entries = []
    if not prompts_dir.exists():
        return entries

    for file_path in sorted(prompts_dir.rglob("*.prompt.md")):
        if not file_path.is_file():
            continue
        try:
            entry = build_prompt_entry(file_path, prompts_dir)
            entries.append(entry)
        except Exception as exc:
            print(f"  WARNING: skipping {file_path}: {exc}", file=sys.stderr)
    return entries


def build_catalog(prompts_dir: Path) -> dict:
    """Build the full prompt catalog dictionary."""
    prompts = scan_prompts(prompts_dir)
    return {
        "version": CATALOG_VERSION,
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "prompt_count": len(prompts),
        "prompts": prompts,
    }


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------


def validate_catalog(catalog: dict) -> bool:
    """Validate the catalog against the JSON schema.

    Uses ``jsonschema`` if available; otherwise performs basic structural
    checks that cover the required fields and types.
    """
    if not SCHEMA_PATH.exists():
        print(f"  WARNING: schema not found at {SCHEMA_PATH}, skipping validation", file=sys.stderr)
        return True

    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))

    try:
        import jsonschema

        jsonschema.validate(instance=catalog, schema=schema)
        print("  Catalog validates against schema.")
        return True
    except ImportError:
        # Fallback: basic structural validation
        return _basic_validate(catalog, schema)
    except Exception as exc:
        print(f"  VALIDATION ERROR: {exc}", file=sys.stderr)
        return False


def _basic_validate(catalog: dict, schema: dict) -> bool:
    """Minimal validation without jsonschema package."""
    errors: list[str] = []

    for field in schema.get("required", []):
        if field not in catalog:
            errors.append(f"Missing required top-level field: {field}")

    if not isinstance(catalog.get("version"), str):
        errors.append("'version' must be a string")
    if not isinstance(catalog.get("generated_at"), str):
        errors.append("'generated_at' must be a string")
    if not isinstance(catalog.get("prompt_count"), int):
        errors.append("'prompt_count' must be an integer")
    if not isinstance(catalog.get("prompts"), list):
        errors.append("'prompts' must be an array")
    else:
        prompt_required = ["id", "name", "description", "status", "tags", "model", "file_path", "content_hash", "last_modified"]
        for i, entry in enumerate(catalog["prompts"]):
            for field in prompt_required:
                if field not in entry:
                    errors.append(f"prompts[{i}]: missing required field '{field}'")
            if "content_hash" in entry:
                h = entry["content_hash"]
                if not isinstance(h, str) or not re.match(r"^[0-9a-f]{64}$", h):
                    errors.append(f"prompts[{i}]: 'content_hash' must be 64-char hex SHA-256")
            if "status" in entry and entry["status"] not in VALID_STATUSES:
                errors.append(f"prompts[{i}]: 'status' must be one of {VALID_STATUSES}")

    if errors:
        for e in errors:
            print(f"  VALIDATION ERROR: {e}", file=sys.stderr)
        return False

    print("  Catalog passes basic structural validation.")
    return True


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate a machine-readable prompt catalog from *.prompt.md files."
    )
    parser.add_argument(
        "--prompts-dir",
        type=Path,
        default=DEFAULT_PROMPTS_DIR,
        help=f"Directory to scan for *.prompt.md files (default: {DEFAULT_PROMPTS_DIR.relative_to(REPO_ROOT)})",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Output JSON file path (default: {DEFAULT_OUTPUT.relative_to(REPO_ROOT)})",
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate the generated catalog against the JSON schema and exit with non-zero on failure.",
    )
    args = parser.parse_args()

    # Resolve relative paths against repo root
    prompts_dir = args.prompts_dir
    if not prompts_dir.is_absolute():
        prompts_dir = REPO_ROOT / prompts_dir
    output = args.output
    if not output.is_absolute():
        output = REPO_ROOT / output

    print(f"Scanning: {prompts_dir}")
    catalog = build_catalog(prompts_dir)
    print(f"  Found {catalog['prompt_count']} prompt(s)")

    # Ensure output directory exists
    output.parent.mkdir(parents=True, exist_ok=True)

    # Write catalog
    output.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
    print(f"  Written: {output}")

    # Validate
    if args.validate:
        if not validate_catalog(catalog):
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
