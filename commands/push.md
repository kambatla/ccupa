# Push Main to All Remotes

Push the main branch to every configured remote.

## Execution
Run this entire workflow as a separate Task agent (use Haiku — it's a straightforward git workflow).

## Input
"$ARGUMENTS" - Not used.

## Process

1. Verify you are on the main branch (abort if not)
2. List all configured remotes (`git remote`)
3. Push the main branch to each remote
