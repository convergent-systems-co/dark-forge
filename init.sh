#!/bin/bash
# .ai/init.sh — Run once after adding the .ai submodule to a project.
# Creates symlinks defined in config.yaml so all AI tools pick up shared config.
#
# Usage:
#   bash .ai/init.sh
#
# This script is idempotent — safe to run multiple times.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Initializing .ai submodule symlinks..."

# instructions.md -> CLAUDE.md, copilot-instructions, .cursorrules
for target in "CLAUDE.md" ".cursorrules"; do
  if [ ! -L "$PROJECT_ROOT/$target" ] || [ "$(readlink "$PROJECT_ROOT/$target")" != ".ai/instructions.md" ]; then
    ln -sf .ai/instructions.md "$PROJECT_ROOT/$target"
    echo "  Linked $target -> .ai/instructions.md"
  else
    echo "  $target already linked"
  fi
done

# GitHub Copilot instructions
mkdir -p "$PROJECT_ROOT/.github"
COPILOT_TARGET=".github/copilot-instructions.md"
if [ ! -L "$PROJECT_ROOT/$COPILOT_TARGET" ] || [ "$(readlink "$PROJECT_ROOT/$COPILOT_TARGET")" != "../.ai/instructions.md" ]; then
  ln -sf ../.ai/instructions.md "$PROJECT_ROOT/$COPILOT_TARGET"
  echo "  Linked $COPILOT_TARGET -> .ai/instructions.md"
else
  echo "  $COPILOT_TARGET already linked"
fi

# MCP server config -> .vscode/mcp.json
mkdir -p "$PROJECT_ROOT/.vscode"
MCP_TARGET=".vscode/mcp.json"
if [ ! -L "$PROJECT_ROOT/$MCP_TARGET" ] || [ "$(readlink "$PROJECT_ROOT/$MCP_TARGET")" != "../.ai/mcp/vscode.json" ]; then
  ln -sf ../.ai/mcp/vscode.json "$PROJECT_ROOT/$MCP_TARGET"
  echo "  Linked $MCP_TARGET -> .ai/mcp/vscode.json"
else
  echo "  $MCP_TARGET already linked"
fi

echo "Done. Symlinks created."
echo ""
echo "Next steps:"
echo "  1. Copy a language template:  cp .ai/templates/python/project.yaml .ai/project.yaml"
echo "  2. Customize personas and conventions in project.yaml"
echo "  3. Set governance profile:    governance.policy_profile: default"
