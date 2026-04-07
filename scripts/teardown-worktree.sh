#!/bin/bash
set -euo pipefail
WORKTREE_PATH="${1:?Usage: teardown-worktree.sh <worktree-path>}"

# Commit any uncommitted changes to tracked files as WIP before removing.
# Uses -u (tracked files only) to avoid staging symlinks like plans/ or other local artifacts.
if [ -n "$(git -C "$WORKTREE_PATH" status --porcelain)" ]; then
    git -C "$WORKTREE_PATH" add -u
    if [ -n "$(git -C "$WORKTREE_PATH" diff --cached --name-only)" ]; then
        git -C "$WORKTREE_PATH" commit -m "wip: save before worktree removal"
        echo "Committed uncommitted changes as WIP"
    fi
fi

UNTRACKED=$(git -C "$WORKTREE_PATH" ls-files --others --exclude-standard)
if [ -n "$UNTRACKED" ]; then
    echo "Warning: the following untracked files will be lost:" >&2
    echo "$UNTRACKED" >&2
fi

git worktree remove --force "$WORKTREE_PATH"
echo "Removed worktree $WORKTREE_PATH"
