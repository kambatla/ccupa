#!/bin/bash
set -euo pipefail
PROMPT="${1:?Usage: run-codex-review.sh <prompt>}"

command -v codex >/dev/null 2>&1 || { echo "ERROR: codex not found on PATH" >&2; exit 1; }

BRANCH=$(git rev-parse --abbrev-ref HEAD | tr '/' '-')
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="${TMPDIR:-/tmp}/codex-review-${BRANCH}-${TIMESTAMP}.md"

codex exec --sandbox read-only --output-last-message "$OUTPUT_FILE" "$PROMPT"

cat "$OUTPUT_FILE"
