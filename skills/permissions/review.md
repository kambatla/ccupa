# Permission Review

Run this procedure after a command completes. Goal: capture patterns that were approved at runtime so they don't require approval next time.

## Procedure

### 1. Scan for Runtime Approvals

Scan the conversation history for tool approval prompts where the user granted permission at runtime. These appear as permission prompts showing the tool name and pattern, followed by the user's approval.

Extract the tool name and pattern from each approval (e.g., `Bash(cd backend && ruff*)` from a prompt about running ruff).

**Caveat:** In long sessions, earlier approvals may have been compressed out of context. This procedure captures what's visible — it won't catch everything.

### 2. Categorize

For each extracted pattern, classify as:

| Category | Action |
|----------|--------|
| Already in `permissions.allow` | No action needed |
| User-approved at runtime | Recommend adding to settings |

### 3. Recommend

**If nothing to recommend:** skip silently.

**If patterns to recommend:**
1. Show a table:

| Pattern | How it was used |
|---------|-----------------|
| `Bash(cd backend && ruff*)` | Backend quality checks |

2. Offer to add them to `.claude/settings.local.json`
3. If user approves, write the updated file

**Do NOT recommend removals** based on a single run — a pattern unused in one session may be needed in the next.
