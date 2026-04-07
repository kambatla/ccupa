#!/bin/bash
set -euo pipefail
BRANCH="${1:?Usage: setup-worktree.sh <branch> [--existing]}"
if [[ "$BRANCH" == --* ]]; then
    echo "ERROR: First argument must be the branch name, not a flag." >&2
    exit 1
fi
EXISTING=false
for arg in "${@:2}"; do
    [[ "$arg" == "--existing" ]] && EXISTING=true
done

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

# Create the worktree
mkdir -p worktrees/
if $EXISTING; then
    git worktree add "worktrees/$BRANCH" "$BRANCH"
else
    git worktree add "worktrees/$BRANCH" -b "$BRANCH"
fi

# Symlink gitignored config files at any depth
LINKED=0
while IFS= read -r file; do
    # Skip entries inside other worktrees (worktrees/ is gitignored, so all its contents appear here)
    [[ "$file" == worktrees/* ]] && continue
    case "$(basename "$file")" in
        .env*|.tokens*|*.local|*.pem|*.key)
            if [ -f "$file" ]; then
                depth=$(awk -F/ '{print NF-1}' <<< "$file")
                prefix=$(printf '../%.0s' $(seq 1 $((depth + 2))))
                dest="worktrees/$BRANCH/$file"
                mkdir -p "$(dirname "$dest")"
                ln -sf "${prefix}${file}" "$dest"
                echo "  linked: $file"
                LINKED=$((LINKED + 1))
            fi
            ;;
    esac
done < <(git ls-files --others --ignored --exclude-standard 2>/dev/null)

[ "$LINKED" -eq 0 ] && echo "  (no config files to link)"

# Symlink plans/ if it exists
if [ -d "plans" ]; then
    ln -sf "../../plans" "worktrees/$BRANCH/plans"
    echo "  linked: plans/"
fi

echo "Worktree ready: worktrees/$BRANCH"
