<!-- upstream: https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum -->
---
description: "Manage Ralph Wiggum iterative loops: start a loop, stop it, or get help"
argument-hint: "<PROMPT> [--max-iterations N] [--completion-promise TEXT] | stop | help"
disable-model-invocation: true
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/skills/ralph/setup-ralph-loop.sh:*)", "Bash(test -f .claude/ralph-loop.local.md:*)", "Bash(rm .claude/ralph-loop.local.md)", "Read(.claude/ralph-loop.local.md)"]
---

```!
ARGS="$ARGUMENTS"
if [ "$ARGS" = "stop" ]; then
    cat "${CLAUDE_SKILL_DIR}/cancel.md"
elif [ -z "$ARGS" ] || [ "$ARGS" = "help" ]; then
    cat "${CLAUDE_SKILL_DIR}/help.md"
else
    "${CLAUDE_PLUGIN_ROOT}/skills/ralph/setup-ralph-loop.sh" $ARGS
    cat "${CLAUDE_SKILL_DIR}/loop.md"
fi
```
