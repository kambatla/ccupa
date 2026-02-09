# Commit Changes

Create a well-formatted git commit following project conventions.

## Execution
Run this entire workflow as a separate Task agent (use Haiku — it's a straightforward git workflow).

## Input
"$ARGUMENTS" - Optional context about what was changed.

## Process

1. **Check if `/prep-commit` was already run** in this conversation:
   - If yes, skip to step 2
   - If no, run `/prep-commit` first (pass `$ARGUMENTS` through, including `--bugfix` if present). Only proceed to step 2 if all checks pass.

2. **Inspect state:**
   - Run `git status` to see all changed files
   - Run `git diff` and `git diff --staged` to review changes
   - Run `git log --oneline -5` to see recent commit style

3. **Stage changes:**
   - Stage specific files by name (not `git add -A`)
   - Warn if `.env`, credentials, or build artifacts are about to be staged

4. **Draft commit message:**
   - Follow git-conventions skill: `<type>: <description>`
   - Focus on "why" not "what"
   - Use imperative mood

5. **Commit:**
   - Use HEREDOC format for the commit message
   - Do NOT include AI attribution

6. **Verify:**
   - Run `git status` after commit to confirm success
