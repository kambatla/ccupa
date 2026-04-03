#!/bin/bash
set -euo pipefail
WORKTREE_PATH="${1:?Usage: teardown-worktree.sh <worktree-path> <branch>}"
BRANCH="${2:?Usage: teardown-worktree.sh <worktree-path> <branch>}"

git worktree remove --force "$WORKTREE_PATH"
git branch -d "$BRANCH"
echo "Removed worktree $WORKTREE_PATH and deleted branch $BRANCH"
