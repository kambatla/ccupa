#!/bin/bash
set -euo pipefail
BRANCH="${1:?Usage: setup-worktree.sh <branch>}"

# Ensure worktrees/ is gitignored
if ! grep -qxF 'worktrees/' .gitignore 2>/dev/null; then
    if [ -n "$(git status --porcelain)" ]; then
        echo "ERROR: Working tree is dirty. Commit or stash changes before worktree setup." >&2
        exit 1
    fi
    echo 'worktrees/' >> .gitignore
    git add .gitignore
    git commit -m "chore: ignore worktrees directory"
fi

# Create the worktree and branch
mkdir -p worktrees/
git worktree add "worktrees/$BRANCH" -b "$BRANCH"

# Symlink gitignored config files into the worktree
LINKED=0
while IFS= read -r file; do
    [[ "$file" == *"/"* ]] && continue  # skip subdirectory files
    case "$file" in
        .env*|.tokens*|*.local|*.pem|*.key)
            if [ -f "$file" ]; then
                ln -sf "../../$file" "worktrees/$BRANCH/$file"
                echo "  linked: $file"
                LINKED=$((LINKED + 1))
            fi
            ;;
    esac
done < <(git ls-files --others --ignored --exclude-standard 2>/dev/null)

[ "$LINKED" -eq 0 ] && echo "  (no config files to link)"
echo "Worktree ready: worktrees/$BRANCH"
