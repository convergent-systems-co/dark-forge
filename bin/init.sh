#!/bin/bash
# .ai/bin/init.sh — Run once after adding the .ai submodule to a project.
# Creates symlinks, detects platform, and optionally installs all dependencies.
#
# Two installation paths:
#   Path 1 (Primary):   init.md — interactive, AI-assisted (agentic bootstrap)
#   Path 2 (Fallback):  init.sh — non-interactive, CI/script (this file)
#
# Usage:
#   bash .ai/bin/init.sh                          # Symlinks only (existing behavior)
#   bash .ai/bin/init.sh --quick                  # Add submodule (HTTPS) + full init (replaces quick-install.sh)
#   bash .ai/bin/init.sh --install-deps           # Symlinks + Python venv + dependencies
#   bash .ai/bin/init.sh --mcp                    # Also install MCP server for IDE integration
#   bash .ai/bin/init.sh --refresh                # Re-apply structural setup after submodule update
#   bash .ai/bin/init.sh --uninstall              # Clean removal of governance artifacts
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
QUICK_MODE=false
INSTALL_MCP=false
UNINSTALL_MODE=false
export DRY_RUN="${DRY_RUN:-false}"
export DEBUG="${DEBUG:-false}"
export PYTHON_MIN_MAJOR=3
export PYTHON_MIN_MINOR=9

LIB_DIR="$AI_DIR/governance/bin"

# Default submodule URL (HTTPS — works across orgs without SSH key setup)
SUBMODULE_URL="https://github.com/SET-Apps/ai-submodule.git"
SUBMODULE_PATH=".ai"

# --- Parse arguments ---

for arg in "$@"; do
  case "$arg" in
    --install-deps) INSTALL_DEPS=true ;;
    --refresh) REFRESH_MODE=true ;;
    --check-branch-protection) CHECK_BRANCH_PROTECTION=true ;;
    --verify) VERIFY_MODE=true ;;
    --quick) QUICK_MODE=true ;;
    --mcp) INSTALL_MCP=true ;;
    --uninstall) UNINSTALL_MODE=true ;;
    --dry-run) DRY_RUN=true ;;
    --debug) DEBUG=true ;;
    --help|-h)
      echo "Usage: bash .ai/bin/init.sh [OPTIONS]"
      echo ""
      echo "Installation paths:"
      echo "  (no flags)                  Standard init — symlinks, workflows, directories"
      echo "  --quick                     Add submodule (HTTPS) + full init (replaces quick-install.sh)"
      echo "  --install-deps              Also install Python virtual environment and dependencies"
      echo "  --mcp                       Also install MCP server for IDE integration"
      echo ""
      echo "Maintenance:"
      echo "  --refresh                   Re-apply structural setup (skip submodule check)"
      echo "  --verify                    Verify installation is complete and correct"
      echo "  --uninstall                 Clean removal of governance artifacts from project"
      echo ""
      echo "Diagnostics:"
      echo "  --check-branch-protection   Query if default branch requires PRs"
      echo "  --dry-run                   Show what would be done without making changes"
      echo "  --debug                     Verbose output for troubleshooting"
      echo "  --help, -h                  Show this help message"
      echo ""
      echo "For interactive AI-assisted setup, tell your assistant:"
      echo "  \"Read and execute .ai/governance/prompts/init.md\""
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: bash .ai/bin/init.sh [--quick] [--install-deps] [--mcp] [--refresh] [--uninstall] [--verify] [--dry-run] [--debug]"
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

# --- Early exit: --uninstall ---

if [ "$UNINSTALL_MODE" = "true" ]; then
  echo "Uninstalling Dark Factory governance artifacts..."
  echo ""

  # Remove symlinks
  for link in "$PROJECT_ROOT/CLAUDE.md" "$PROJECT_ROOT/.github/copilot-instructions.md"; do
    if [ -L "$link" ]; then
      if [ "$DRY_RUN" = "true" ]; then
        echo "  [DRY-RUN] Would remove symlink: $link"
      else
        rm "$link"
        echo "  [OK] Removed symlink: $link"
      fi
    fi
  done

  # Remove .claude/commands symlink or directory
  COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"
  if [ -L "$COMMANDS_DIR" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "  [DRY-RUN] Would remove symlink: $COMMANDS_DIR"
    else
      rm "$COMMANDS_DIR"
      echo "  [OK] Removed symlink: $COMMANDS_DIR"
    fi
  fi

  # Remove governance directories
  for dir in "$PROJECT_ROOT/.governance"; do
    if [ -d "$dir" ]; then
      if [ "$DRY_RUN" = "true" ]; then
        echo "  [DRY-RUN] Would remove directory: $dir"
      else
        echo "  [WARN] .governance/ directory preserved (contains state). Remove manually if desired:"
        echo "         rm -rf $dir"
      fi
    fi
  done

  # Remove venv
  if [ -d "$VENV_DIR" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "  [DRY-RUN] Would remove virtual environment: $VENV_DIR"
    else
      rm -rf "$VENV_DIR"
      echo "  [OK] Removed virtual environment: $VENV_DIR"
    fi
  fi

  echo ""
  echo "Uninstall complete."
  echo ""
  echo "To fully remove the submodule:"
  echo "  git submodule deinit .ai"
  echo "  git rm .ai"
  echo "  rm -rf .git/modules/.ai"
  exit 0
fi

# --- Quick mode: add submodule first ---

if [ "$QUICK_MODE" = "true" ]; then
  # Must be in a git repository
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "[ERROR] Not inside a git repository. Run 'git init' first."
    exit 1
  fi

  # Re-resolve PROJECT_ROOT for quick mode (we're in the project root, not .ai/)
  if [ ! -d "$SUBMODULE_PATH" ]; then
    echo "Adding $SUBMODULE_PATH as git submodule (HTTPS)..."
    if [ "$DRY_RUN" = "true" ]; then
      echo "  [DRY-RUN] Would run: git submodule add $SUBMODULE_URL $SUBMODULE_PATH"
    else
      git submodule add "$SUBMODULE_URL" "$SUBMODULE_PATH"
      echo "[OK] Submodule added."
    fi
  else
    echo "[OK] $SUBMODULE_PATH already exists."
  fi

  # After adding submodule, re-resolve paths
  if [ -d "$SUBMODULE_PATH" ]; then
    AI_DIR="$(cd "$SUBMODULE_PATH" && pwd)"
    LIB_DIR="$AI_DIR/governance/bin"
    VENV_DIR="$AI_DIR/.venv"
    export AI_DIR VENV_DIR
  fi

  echo ""
  # Fall through to normal init
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

# --- Step 9: MCP server installation (opt-in) ---
if [ "$INSTALL_MCP" = "true" ]; then
  echo ""
  MCP_INSTALL_SCRIPT="$AI_DIR/mcp-server/install.sh"
  if [ -f "$MCP_INSTALL_SCRIPT" ]; then
    echo "Installing MCP server for IDE integration..."
    # Check if MCP server is built
    if [ -f "$AI_DIR/mcp-server/dist/index.js" ]; then
      bash "$MCP_INSTALL_SCRIPT" --governance-root "$PROJECT_ROOT"
    else
      echo "  [INFO] MCP server not built. Building..."
      if command -v npm &>/dev/null; then
        (cd "$AI_DIR/mcp-server" && npm install --silent && npm run build --silent)
        bash "$MCP_INSTALL_SCRIPT" --governance-root "$PROJECT_ROOT"
      else
        echo "  [SKIP] npm not found. Install Node.js to use the MCP server."
        echo "         Then run: cd .ai/mcp-server && npm install && npm run build"
        echo "         Then run: bash .ai/mcp-server/install.sh --governance-root ."
      fi
    fi
  else
    echo "  [SKIP] MCP server install script not found at $MCP_INSTALL_SCRIPT"
  fi
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
  if [ "$INSTALL_MCP" = "false" ]; then
    echo "  4. Install MCP server:       bash .ai/bin/init.sh --mcp"
  fi
  if [ -d "$VENV_DIR" ]; then
    echo ""
    echo "To activate the virtual environment:"
    echo "  source .ai/.venv/bin/activate"
  fi
fi
