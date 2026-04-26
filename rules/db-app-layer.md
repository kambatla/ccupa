---
description: Application-layer database access — never use raw SQL in Python code, always use RPC wrappers or ORM.
globs:
  - "**/*.py"
---

# Database Access in Application Code

Never use raw SQL in application code — use database functions + RPC wrappers or an ORM. Migration scripts are exempt.

See the `db-conventions-supabase` rule for RPC wrapper conventions and naming patterns.
