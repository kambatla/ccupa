# Ralph Wiggum Plugin Help

Please explain the following to the user:

## What is Ralph?

An iterative loop: the same prompt is fed to Claude repeatedly. Each iteration sees previous work in files and git history, building incrementally toward the goal.

## Commands

### /ralph \<PROMPT\> [OPTIONS]

Start a Ralph loop.

**Options:**
- `--max-iterations <n>` — stop after N iterations
- `--completion-promise <text>` — phrase Claude must output to exit the loop

**Example:**
```
/ralph "Fix the token refresh logic in auth.ts. Output <promise>FIXED</promise> when all tests pass." --completion-promise "FIXED" --max-iterations 10
```

### /ralph stop

Cancel an active loop (removes the loop state file).

## Completion Promises

To signal completion, Claude outputs a `<promise>` tag:
```
<promise>TASK COMPLETE</promise>
```
Without this (or `--max-iterations`), Ralph runs until manually stopped.

## When to use

Good for well-defined tasks with clear success criteria that benefit from iteration. Not for tasks requiring human judgment, one-shot operations, or unclear success criteria.

## Learn More

- Original technique: https://ghuntley.com/ralph/
- Ralph Orchestrator: https://github.com/mikeyobrien/ralph-orchestrator
