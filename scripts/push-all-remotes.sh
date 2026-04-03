#!/bin/bash
set -euo pipefail

BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
    echo "ERROR: Not on main branch (current: $BRANCH). Aborting." >&2
    exit 1
fi

REMOTES=$(git remote)
if [ -z "$REMOTES" ]; then
    echo "No remotes configured." >&2
    exit 1
fi

for remote in $REMOTES; do
    echo "Pushing to $remote..."
    git push "$remote" "$BRANCH"
done

echo "Done. Pushed $BRANCH to all remotes."
