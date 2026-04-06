---
description: "Stage, group, and commit changes per git conventions"
disable-model-invocation: true
---

# Commit Changes

Create a well-formatted git commit following project conventions.

## Input
"$ARGUMENTS" - Optional context about what was changed.

## Execution
Run as a Haiku sub-agent — this is a leaf workflow with no further sub-agents.

## Prerequisites
`/prep-commit` must have been run in this conversation. If not, stop and tell the user:
> Run `/prep-commit` first, then re-run `/commit`.

## Required Permissions
For unattended execution, add to `.claude/settings.local.json`. Run `/setup` to configure.
- `Bash(git *)`

## Process

1. **Inspect state:**
   - Run `git status` to see all changed files
   - Run `git diff` and `git diff --staged` to review changes
   - Run `git log --oneline -5` to see recent commit style

2. **Analyze commit scope:**
   - Review the diffs to determine whether all changes serve a single intent or span unrelated concerns
   - **Split signals:** changes would need "and" to describe in one subject, different "why"s behind different files, independent subsystems touched for independent reasons
   - **Don't-split signals:** a feature + its tests, a refactor + formatting it causes, multiple files changed for the same motivation
   - If **mixed**: propose groups to the user — list files and a draft subject for each group, then wait for approval before proceeding
   - If **cohesive**: proceed as a single group

3. **Stage and commit per group:**
   - For each group (in logical order — infra before feature, refactor before new code):
     1. Stage specific files by name (not `git add -A`)
     2. Warn if `.env`, credentials, or build artifacts are about to be staged
     3. Draft commit message following git-conventions skill: `<type>: <description>`, focus on "why" not "what", imperative mood
     4. Commit using HEREDOC format. Do NOT include AI attribution.

4. **Verify:**
   - Run `git log --oneline -N` (where N = number of commits created) to confirm all commits
   - Run `git status` to confirm clean working tree
