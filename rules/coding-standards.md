---
description: General coding principles — fix all failures regardless of origin, treat tests as contract verification. Applies to all files (intentionally unscoped).
---

# Coding Standards

## Fix All Failures, Not Just Yours

When a check fails (lint, type error, test), fix it — even if the issue predates the current session. If the issue is on the current branch, it's yours.

## Tests Are Contract Verification

When a test fails, diagnose before acting:

1. **Is the contract still relevant?** If no one depends on it, delete or update the test. Log what you deleted and why.
2. **Is the violation intentional?** If the contract changed deliberately, update the test.
3. **Is the violation a bug?** Fix the code — not the test.

**Default:** Assume step 3 — the contract matters and the code is wrong.
