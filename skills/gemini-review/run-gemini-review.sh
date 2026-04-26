#!/bin/bash
set -euo pipefail
PROMPT="${1:?Usage: run-gemini-review.sh <prompt> [diff-command]}"
DIFF_CMD="${2:-git diff --cached}"

command -v gemini >/dev/null 2>&1 || { echo "ERROR: gemini not found on PATH" >&2; exit 1; }

BRANCH=$(git rev-parse --abbrev-ref HEAD | tr '/' '-')
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="${TMPDIR:-/tmp}/gemini-review-${BRANCH}-${TIMESTAMP}.md"

# Embed the diff so gemini needs no shell tool access (plan mode stays read-only)
DIFF=$(eval "$DIFF_CMD")

FULL_PROMPT="${PROMPT}

<diff>
${DIFF}
</diff>"

gemini -p "$FULL_PROMPT" --approval-mode plan --output-format text --skip-trust > "$OUTPUT_FILE"

cat "$OUTPUT_FILE"
