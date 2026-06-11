#!/bin/bash
# PostToolUse hook: auto-format files after Claude writes them

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Require jq for JSON parsing
command -v jq > /dev/null 2>&1 || exit 0

# Extract file path from hook input
file_path=$(jq -r '.tool_input.file_path // empty' <<< "$HOOK_INPUT")

# Skip if path is empty or file does not exist
if [[ -z "$file_path" ]] || [[ ! -f "$file_path" ]]; then
  exit 0
fi

# Dispatch by file extension
ext="${file_path##*.}"

case "$ext" in
  py)
    command -v ruff > /dev/null 2>&1 || exit 0
    ruff format --quiet "$file_path" 2>/dev/null || true
    ;;
  ts|tsx|js|jsx|css|html)
    command -v prettier > /dev/null 2>&1 || exit 0
    prettier --write --log-level silent "$file_path" 2>/dev/null || true
    ;;
  *)
    exit 0
    ;;
esac

exit 0
