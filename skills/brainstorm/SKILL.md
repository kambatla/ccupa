---
description: "Explore problem space, challenge assumptions, and recommend direction"
disable-model-invocation: true
---

# Feature Brainstorming

## Input
"$ARGUMENTS" - If empty, ask what problem to solve. Otherwise, use as starting point.

## Process

Work sequentially. Complete each phase and get confirmation before moving to the next.

### Phase 1: Problem Understanding
1. Understand the problem context and which user workflows it affects
2. Ask clarifying questions
3. Suggest good workarounds if available

### Phase 2: Solution Exploration
1. Identify canonical approaches and alternatives
2. If only one viable approach exists, state it directly. When comparing 2+ non-trivial approaches, create a forked foreground sub-agent to evaluate tradeoffs and return a compact verdict: decision + rationale (2–3 sentences) + key tradeoff accepted. Record only the verdict.

### Phase 3: Recommendation
1. Present the recommendation (fork verdict or direct derivation) with rationale
2. Identify constraints and assumptions — confirm with user
3. Note affected areas (high-level only)
4. Summarize agreed-upon direction

## Approach
- Challenge assumptions aggressively; push back on solutions looking for problems
- Call out feature creep and over-engineering

## Next Steps
- `/design` to architect the solution
- Plan mode directly for smaller items
