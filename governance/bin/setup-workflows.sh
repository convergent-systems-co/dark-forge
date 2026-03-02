#!/bin/bash
# governance/bin/setup-workflows.sh — Issue templates, governance workflow copies, GOALS.md template.
# Only runs in submodule context (consuming repo has .gitmodules with .ai entry).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
resolve_ai_dir

# Requires PYTHON_CMD from caller (or empty string)
PYTHON_CMD="${PYTHON_CMD:-}"

IS_SUBMODULE=false
if [ -f "$PROJECT_ROOT/.gitmodules" ] && grep -q '\.ai' "$PROJECT_ROOT/.gitmodules" 2>/dev/null; then
  IS_SUBMODULE=true
fi

if [ "$IS_SUBMODULE" != "true" ]; then
  echo "  Skipping template/workflow setup (not a submodule context)"
  return 0 2>/dev/null || exit 0
fi

# --- Issue templates ---
TEMPLATE_SRC="$AI_DIR/.github/ISSUE_TEMPLATE"
TEMPLATE_DST="$PROJECT_ROOT/.github/ISSUE_TEMPLATE"
if [ -d "$TEMPLATE_SRC" ]; then
  mkdir -p "$TEMPLATE_DST"
  for tmpl in "$TEMPLATE_SRC"/*.yml; do
    [ -f "$tmpl" ] || continue
    TMPL_NAME=$(basename "$tmpl")
    if [ ! -f "$TEMPLATE_DST/$TMPL_NAME" ]; then
      run_cmd "Copy issue template $TMPL_NAME" cp "$tmpl" "$TEMPLATE_DST/$TMPL_NAME"
      echo "  Copied issue template $TMPL_NAME"
    else
      echo "  Issue template $TMPL_NAME already exists, skipping"
    fi
  done
fi

# --- Governance workflows ---
WORKFLOW_SRC="$AI_DIR/.github/workflows"
WORKFLOW_DST="$PROJECT_ROOT/.github/workflows"
if [ -d "$WORKFLOW_SRC" ]; then
  mkdir -p "$WORKFLOW_DST"
  # Read workflow lists from config.yaml if Python is available
  REQUIRED_WORKFLOWS="dark-factory-governance.yml"
  OPTIONAL_WORKFLOWS=""
  if [ -n "$PYTHON_CMD" ]; then
    CONFIG_WORKFLOWS=$("$PYTHON_CMD" -c "
import yaml, os, sys

def deep_merge(base, override):
    result = dict(base)
    for k, v in override.items():
        if k in result and isinstance(result[k], dict) and isinstance(v, dict):
            result[k] = deep_merge(result[k], v)
        elif k in result and isinstance(result[k], list) and isinstance(v, list):
            result[k] = result[k] + v
        else:
            result[k] = v
    return result

config = {}
for f in sys.argv[1:]:
    if os.path.exists(f):
        with open(f) as fh:
            data = yaml.safe_load(fh) or {}
            config = deep_merge(config, data)

wf = config.get('workflows', {})
if isinstance(wf, dict):
    req = wf.get('required', ['dark-factory-governance.yml'])
    opt = wf.get('optional', [])
else:
    req = config.get('workflows_to_copy', ['dark-factory-governance.yml'])
    opt = []
print('REQUIRED=' + ' '.join(req))
print('OPTIONAL=' + ' '.join(opt))
" "$AI_DIR/config.yaml" "$AI_DIR/project.yaml" "$PROJECT_ROOT/project.yaml" 2>/dev/null)
    if [ -n "$CONFIG_WORKFLOWS" ]; then
      REQUIRED_WORKFLOWS=$(echo "$CONFIG_WORKFLOWS" | grep '^REQUIRED=' | sed 's/^REQUIRED=//')
      OPTIONAL_WORKFLOWS=$(echo "$CONFIG_WORKFLOWS" | grep '^OPTIONAL=' | sed 's/^OPTIONAL=//')
    fi
  fi

  # --- Detect consuming repo's default branch ---
  DEFAULT_BRANCH="main"
  if command -v gh &>/dev/null; then
    # Extract owner/repo from git remote
    REMOTE_URL=$(git -C "$PROJECT_ROOT" remote get-url origin 2>/dev/null || true)
    if [ -n "$REMOTE_URL" ]; then
      OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's#.*(github\.com[:/])##; s/\.git$//')
      if [ -n "$OWNER_REPO" ]; then
        DETECTED_BRANCH=$(gh api "repos/$OWNER_REPO" --jq '.default_branch' 2>/dev/null || true)
        if [ -n "$DETECTED_BRANCH" ]; then
          DEFAULT_BRANCH="$DETECTED_BRANCH"
        fi
      fi
    fi
  fi

  # --- Helper: copy workflow file only if content changed ---
  copy_with_diff() {
    local src="$1" dst="$2"
    if [ -L "$dst" ]; then
      # Replace existing symlink with a real copy
      rm -f "$dst"
    fi
    if [ -f "$dst" ] && diff -q "$src" "$dst" &>/dev/null; then
      return 1  # no change needed
    fi
    cp "$src" "$dst"
    return 0  # file was copied
  }

  # --- Helper: patch branch triggers to match consuming repo's default branch ---
  patch_branch_triggers() {
    local file="$1" branch="$2"
    if [ "$branch" != "main" ]; then
      sed -i.bak "s/branches: \\[main\\]/branches: [${branch}]/" "$file"
      rm -f "${file}.bak"
    fi
  }

  # Copy required workflows (warn if source is missing)
  for wf_name in $REQUIRED_WORKFLOWS; do
    if [ -f "$WORKFLOW_SRC/$wf_name" ]; then
      if copy_with_diff "$WORKFLOW_SRC/$wf_name" "$WORKFLOW_DST/$wf_name"; then
        patch_branch_triggers "$WORKFLOW_DST/$wf_name" "$DEFAULT_BRANCH"
        echo "  Copied $wf_name (default branch: $DEFAULT_BRANCH)"
      else
        echo "  Workflow $wf_name already up to date"
      fi
    else
      log_warn "Required workflow $wf_name not found in .ai/.github/workflows/"
    fi
  done

  # Copy optional workflows (skip silently if source is missing)
  for wf_name in $OPTIONAL_WORKFLOWS; do
    if [ -f "$WORKFLOW_SRC/$wf_name" ]; then
      if copy_with_diff "$WORKFLOW_SRC/$wf_name" "$WORKFLOW_DST/$wf_name"; then
        patch_branch_triggers "$WORKFLOW_DST/$wf_name" "$DEFAULT_BRANCH"
        echo "  Copied $wf_name (optional, default branch: $DEFAULT_BRANCH)"
      else
        echo "  Workflow $wf_name already up to date (optional)"
      fi
    fi
  done
fi

# --- GOALS.md ---
GOALS_TEMPLATE="$AI_DIR/governance/templates/GOALS.md"
GOALS_DST="$PROJECT_ROOT/GOALS.md"
if [ -f "$GOALS_TEMPLATE" ]; then
  if [ -f "$GOALS_DST" ]; then
    echo "  GOALS.md already exists, skipping"
  else
    run_cmd "Create GOALS.md" cp "$GOALS_TEMPLATE" "$GOALS_DST"
    echo "  Created GOALS.md from template"
  fi
else
  log_warn "GOALS.md template not found at $GOALS_TEMPLATE"
fi
