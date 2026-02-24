# Commit Changes

Create a well-formatted git commit following project conventions.

## Execution
Run this entire workflow as a separate Task agent (use Sonnet — grouping changes by intent requires judgment).

## Input
"$ARGUMENTS" - Optional context about what was changed.

## Required Permissions
For unattended execution, add to `.claude/settings.local.json`. Run `/setup` to configure.
- `Bash(git *)`

Note: `/prep-commit` (called in Step 1 if not already run) handles its own permission preflight.

## Process

1. **Check if `/prep-commit` was already run** in this conversation:
   - If yes, skip to step 2
   - If no, run `/prep-commit` first (pass `$ARGUMENTS` through, including `--bugfix` if present). Only proceed to step 2 if all checks pass.

2. **Inspect state:**
   - Run `git status` to see all changed files
   - Run `git diff` and `git diff --staged` to review changes
   - Run `git log --oneline -5` to see recent commit style

3. **Analyze commit scope:**
   - Review the diffs to determine whether all changes serve a single intent or span unrelated concerns
   - **Split signals:** changes would need "and" to describe in one subject, different "why"s behind different files, independent subsystems touched for independent reasons
   - **Don't-split signals:** a feature + its tests, a refactor + formatting it causes, multiple files changed for the same motivation
   - If **mixed**: propose groups to the user — list files and a draft subject for each group, then wait for approval before proceeding
   - If **cohesive**: proceed as a single group

4. **Stage and commit per group:**
   - For each group (in logical order — infra before feature, refactor before new code):
     1. Stage specific files by name (not `git add -A`)
     2. Warn if `.env`, credentials, or build artifacts are about to be staged
     3. Draft commit message following git-conventions skill: `<type>: <description>`, focus on "why" not "what", imperative mood
     4. Commit using HEREDOC format. Do NOT include AI attribution.

5. **Verify:**
   - Run `git log --oneline -N` (where N = number of commits created) to confirm all commits
   - Run `git status` to confirm clean working tree
