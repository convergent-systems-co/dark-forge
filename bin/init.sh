#!/bin/bash
# .ai/bin/init.sh — Run once after adding the .ai submodule to a project.
# Creates symlinks, detects platform, and optionally installs all dependencies.
#
# Usage:
#   bash .ai/bin/init.sh                          # Symlinks only (existing behavior)
#   bash .ai/bin/init.sh --install-deps           # Symlinks + Python venv + dependencies
#   bash .ai/bin/init.sh --refresh                # Re-apply structural setup after submodule update
#   bash .ai/bin/init.sh --check-branch-protection  # Query branch protection status (machine-readable)
#   bash .ai/bin/init.sh --verify                 # Verify installation is complete and correct
#   bash .ai/bin/init.sh --dry-run                # Show what would be done without making changes
#   bash .ai/bin/init.sh --debug                  # Verbose output for troubleshooting
#
# This script is idempotent — safe to run multiple times.
# Modular scripts live in governance/bin/; this file orchestrates them.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # .ai/bin/
AI_DIR="$(dirname "$SCRIPT_DIR")"                             # .ai/
PROJECT_ROOT="$(dirname "$AI_DIR")"                           # project root
VENV_DIR="$AI_DIR/.venv"
INSTALL_DEPS=false
REFRESH_MODE=false
CHECK_BRANCH_PROTECTION=false
VERIFY_MODE=false
export DRY_RUN="${DRY_RUN:-false}"
export DEBUG="${DEBUG:-false}"
export PYTHON_MIN_MAJOR=3
export PYTHON_MIN_MINOR=12

LIB_DIR="$AI_DIR/governance/bin"

# --- Parse arguments ---

for arg in "$@"; do
  case "$arg" in
    --install-deps) INSTALL_DEPS=true ;;
    --refresh) REFRESH_MODE=true ;;
    --check-branch-protection) CHECK_BRANCH_PROTECTION=true ;;
    --verify) VERIFY_MODE=true ;;
    --dry-run) DRY_RUN=true ;;
    --debug) DEBUG=true ;;
    --help|-h)
      echo "Usage: bash .ai/bin/init.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --install-deps              Install Python virtual environment and dependencies"
      echo "  --refresh                   Re-apply structural setup (skip submodule check)"
      echo "  --check-branch-protection   Query if default branch requires PRs"
      echo "  --verify                    Verify installation is complete and correct"
      echo "  --dry-run                   Show what would be done without making changes"
      echo "  --debug                     Verbose output for troubleshooting"
      echo "  --help, -h                  Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: bash .ai/bin/init.sh [--install-deps] [--refresh] [--check-branch-protection] [--verify] [--dry-run] [--debug]"
      exit 1
      ;;
  esac
done

# Export shared variables for modular scripts
export AI_DIR PROJECT_ROOT VENV_DIR DRY_RUN DEBUG

# --- Early exit: --check-branch-protection ---

if [ "$CHECK_BRANCH_PROTECTION" = "true" ]; then
  exec bash "$LIB_DIR/check-branch-protection.sh"
fi

# --- Early exit: --verify ---

if [ "$VERIFY_MODE" = "true" ]; then
  exec bash "$LIB_DIR/verify-installation.sh"
fi

# --- Platform detection ---

detect_platform() {
  local os; os="$(uname -s)"
  case "$os" in
    Darwin) echo "macOS" ;; Linux) echo "Linux" ;; *) echo "$os" ;;
  esac
}

PLATFORM="$(detect_platform)"
echo "Platform: $PLATFORM"
echo ""

# --- Source shared library ---
source "$LIB_DIR/lib/common.sh"

# --- Step 1: Python detection ---
export PYTHON_CMD="" PYTHON_OK=false
source "$LIB_DIR/check-python.sh"
export PYTHON_CMD PYTHON_OK

# --- Step 2: Submodule freshness + integrity ---
export REFRESH_MODE
source "$LIB_DIR/update-submodule.sh"

# --- Step 3: Symlinks ---
source "$LIB_DIR/create-symlinks.sh"

# --- Step 4-6: Submodule-context setup (workflows, emissions, directories) ---
IS_SUBMODULE=false
if [ -f "$PROJECT_ROOT/.gitmodules" ] && grep -q '\.ai' "$PROJECT_ROOT/.gitmodules" 2>/dev/null; then
  IS_SUBMODULE=true
fi

if [ "$IS_SUBMODULE" = "true" ]; then
  source "$LIB_DIR/setup-workflows.sh"
  source "$LIB_DIR/validate-emissions.sh"
  source "$LIB_DIR/setup-directories.sh"
else
  echo "  Skipping template/workflow/directory setup (not a submodule context)"
fi

# --- Migration warning: project.yaml location ---
if [ -f "$AI_DIR/project.yaml" ] && [ ! -f "$PROJECT_ROOT/project.yaml" ]; then
  echo ""
  echo "  [MIGRATE] project.yaml found at .ai/project.yaml (legacy location)"
  echo "            The preferred location is now the project root: ./project.yaml"
  echo "            Move it with: mv .ai/project.yaml project.yaml"
  echo "            Both locations are read; root takes precedence."
fi
echo ""

# --- Step 7: Dependency installation ---
if [ "$INSTALL_DEPS" = "true" ]; then
  source "$LIB_DIR/install-deps.sh"
else
  echo ""
  if [ "$PYTHON_OK" = "true" ]; then
    if [ -d "$VENV_DIR" ]; then
      echo "  [OK] Virtual environment exists at .ai/.venv"
    else
      echo "  [INFO] No virtual environment found. Run with --install-deps to create one."
    fi
  fi
fi

# --- Step 8: Repository configuration ---
if [ "$PYTHON_OK" = "true" ]; then
  echo ""
  source "$LIB_DIR/setup-repo-config.sh"
  source "$LIB_DIR/setup-codeowners.sh"
else
  echo ""
  echo "  [SKIP] Repository configuration requires Python for YAML parsing"
fi

# --- Done ---
echo ""
if [ "$REFRESH_MODE" = "true" ]; then
  echo "Refresh complete."
else
  echo "Done."
  echo ""
  echo "Next steps:"
  if [ "$INSTALL_DEPS" = "false" ] && [ ! -d "$VENV_DIR" ]; then
    echo "  0. Install dependencies:     bash .ai/bin/init.sh --install-deps"
  fi
  echo "  1. Copy a language template:  cp .ai/governance/templates/python/project.yaml project.yaml"
  echo "  2. Customize personas and conventions in project.yaml"
  echo "  3. Set governance profile:    governance.policy_profile: default"
  if [ -d "$VENV_DIR" ]; then
    echo ""
    echo "To activate the virtual environment:"
    echo "  source .ai/.venv/bin/activate"
  fi
fi
