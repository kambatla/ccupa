---
description: Application-layer database access — never use raw SQL in Python code, always use RPC wrappers or ORM.
globs:
  - "**/*.py"
---

# Database Access in Application Code

Never use raw SQL queries in application code. Always use database functions + RPC wrappers or an ORM. This does not apply to migration scripts, which use SQL by design.

**Why:**
- SQL injection risk — parameterized queries in RPC wrappers handle escaping correctly by default
- RPC wrappers provide built-in retry logic, connection pooling, and structured error types

See the `db-conventions-supabase` rule for RPC wrapper conventions and naming patterns.
