# Session Learn

**Model: Opus** — reasoning about session patterns and proposing convention changes requires deep judgment.

Reflect on the current session and propose improvements to permissions, conventions, and workflows.

## Input
"$ARGUMENTS" - Optional focus area (e.g., "permissions", "testing patterns").

## Process

### Step 1: Review Session
Analyze the conversation for:
- Permission patterns that needed runtime approval — use the permission review procedure (`skills/permissions/review.md`) to scan for approval prompts and extract patterns
- Repeated user corrections (conventions that should be codified)
- New patterns that emerged (naming, structure, workflow)
- Workflow friction (steps that were slow, confusing, or frequently skipped)

### Step 2: Categorize Proposals
Group findings by target:

| Target | Examples |
|--------|----------|
| `.claude/settings.local.json` | New permission patterns to allow |
| Project `CLAUDE.md` | New conventions, essential commands, project-specific rules |
| Plugin skills | Pattern updates, new sub-files |
| Plugin commands | Workflow adjustments, step changes |

Most proposals should target the project's `CLAUDE.md` or `.claude/settings.local.json` — these are project-specific and low-risk. Plugin-level changes (skills/, commands/) affect all projects using the plugin and should be rare.

### Step 3: Present Proposals
For each proposal, show:
- **What:** the specific change
- **Why:** session evidence (what happened that motivates this)
- **Impact:** what improves if adopted

User approves or rejects each proposal individually.

**Plugin-level proposals** require separate explicit confirmation with a warning: "This change affects all projects using the plugin."

### Step 4: Apply Approved Changes
For each approved change:
1. Read the target file's current contents
2. Merge the change into the existing content (e.g., append to `permissions.allow` array, not overwrite it)
3. Write the updated file

### Step 5: Summary
List what was changed and where.
