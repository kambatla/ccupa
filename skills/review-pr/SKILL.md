---
description: "Run code reviews, tests, and quality checks on a PR; fix issues; post results as PR comment"
disable-model-invocation: true
---

# Review PR

Wraps `/review-branch` — runs the full review workflow, then posts a structured comment on the PR. This is the gate before `/merge`.

## Input
"$ARGUMENTS" - Optional PR number. If empty, auto-detect from current branch.

## Process

### Step 0: PR Detection
1. Check for uncommitted changes via `git status`. If there are staged or unstaged changes, stop:
   > Uncommitted changes detected. Commit them first before running `/review-pr`.
2. Auto-detect the PR via `gh pr view --json number,url` on the current branch
3. If `$ARGUMENTS` contains a PR number, use that instead
4. If no PR exists on the current branch, stop:
   > No PR found on this branch. Run `/pr` first, or use `/review-branch` to review without a PR.
5. Save the PR number and URL for the comment step

### Step 1: Run Review Branch
Follow the `/review-branch` workflow in full (see `skills/review-branch/SKILL.md`). It handles uncommitted-changes guard, setup, parallel checks, and the fix-verify loop, and leaves a structured Review Results summary in the conversation.

### Step 2: Post PR Comment
Using the Review Results summary from Step 1, post it as a comment on the PR:

```bash
gh pr comment {PR_NUMBER} --body "$(cat <<'EOF'
{Review Results block from Step 1, verbatim}
EOF
)"
```

### Step 3: Report
Report to the conversation:
- Link to the PR comment
- Any unfixed issues remaining

## Note on GH Actions re-trigger
When the review fix loop pushes fix commits, the push can re-trigger CI workflows. The GH Actions workflow should guard against recursive triggers (e.g., skip if the commit message matches `fix: address * review findings`). This is not a skill concern but document the risk for consuming projects.
