# ccupa

My personal [Claude Code](https://claude.ai/code) plugin for coding projects — defines development workflow conventions: coding standards, git practices, database patterns, deployment guides, and slash commands for the full feature development lifecycle.

## What's Included

### Skills (contextual reference material)

| Skill | Description |
|-------|-------------|
| **coding-standards** | Code patterns and testing standards for Python/FastAPI and React/TypeScript |
| **db-conventions** | Migration-first workflow, schema design, and Supabase-specific patterns |
| **git-conventions** | Commit message format, branch naming, PR structure |
| **deployment** | Local dev environment setup and Digital Ocean production deployment |

### Commands (workflow automation)

| Command | Description |
|---------|-------------|
| `/brainstorm` | Explore a problem space with critical analysis |
| `/design` | Architect a feature layer-by-layer with test cases |
| `/implement` | Execute an implementation plan (sequential or parallel agents) |
| `/bug` | Investigate, write regression test, fix, prove it works |
| `/prep-commit` | Run scoped tests, quality checks, and code review in parallel |
| `/commit` | Stage and commit following git conventions |
| `/prep-merge-pr` | Full test suites + 3 specialized reviews (correctness, quality, security) |
| `/pr` | Create a pull request with structured description |
| `/merge` | Rebase, verify, merge to main, clean up |
| `/sync-main` | Pull latest main, delete merged branches |
| `/push` | Push main to all configured remotes |

## Installation

Clone this repository and add it as a Claude Code plugin:

```bash
claude mcp add-json ccupa '{"type":"local","path":"/path/to/ccupa"}'
```

Or add the plugin path in your Claude Code settings.

## License

[MIT](LICENSE)
