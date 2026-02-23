---
name: coding-standards
description: Code patterns, conventions, and testing standards. Routes to language-specific files for Python/FastAPI or React/TypeScript. Use when writing new code, reviewing code, or making architectural decisions.
---

# Coding Standards Skill

This skill defines how code is written and tested. Follow these patterns for consistency.

## When to Use This Skill

Claude should invoke this skill when:
- Writing new components, endpoints, hooks, or services
- Writing or reviewing tests
- Reviewing code for pattern compliance
- Deciding how to structure new functionality
- Unsure about naming, error handling, or file placement

## Fix All Failures, Not Just Yours

When a check fails (lint, type error, test), fix it — even if the issue predates the current session. Context loss from `/clear` or `/compact` doesn't change ownership; if the issue is on the current branch, it's yours. Pre-existing issues that go unfixed erode signal quality and make every subsequent check less trustworthy.

## Tests Are Contract Verification

Tests verify that code meets its contractual obligations to users or other parts of the system. Each test should have a clear contract it's verifying — if there's no identifiable contract, the test shouldn't exist.

When a test fails, a contract is violated. Diagnose before acting:

1. **Is the contract still relevant?** If it's a legacy obligation no one depends on, delete or update the test. Log which tests you deleted/updated and why so the user can review.
2. **Is the violation intentional?** If the contract changed deliberately (e.g., a new return type), update the test to match the new contract.
3. **Is the violation a bug?** If the contract is important and unexpectedly broken, fix the code — not the test.

**Default:** If the situation is ambiguous, assume step 3 — the contract matters and the code is wrong.

## Language-Specific Files

| File | Use When |
|------|----------|
| `python.md` | Writing backend code (FastAPI, pytest, Python) |
| `react-typescript.md` | Writing frontend code (React, TypeScript, vitest) |

Each file covers both **coding standards** and **testing patterns** for its language.
