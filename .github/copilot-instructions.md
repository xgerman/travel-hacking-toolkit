# Copilot Instructions

## Project Overview

Travel Hacking Toolkit — an AI agent toolkit for travel planning with points, miles, award flights, and cash comparison. Ships 44 skills and 6 MCP servers for Claude Code, OpenCode, and Codex. Not a traditional application — it's a curated knowledge base and tool collection that AI coding agents consume at runtime.

## Build & Test

```bash
# Full smoke test (static checks + agent invocations if CLIs installed)
bash scripts/smoke-test.sh

# Static checks only (fast, use while iterating)
bash scripts/smoke-test.sh --quick

# Check for table drift without fixing it
bash scripts/gen-skill-tables.sh --check
```

There is no traditional build step. The smoke test validates:
- Shell script syntax (setup.sh, setup-keys.sh, setup.ps1, setup-keys.ps1)
- Skill frontmatter validity (every `skills/*/SKILL.md` must have `name` + `description`)
- CLAUDE.md stays under 40k chars
- Docker images exist on ghcr.io
- Data files within declared TTL
- README.md and llms.txt tables match generated output (no drift)
- Plugin manifest validation via `claude plugin validate`
- `agents/travel-hacker.md` in sync with CLAUDE.md

CI runs `bash scripts/smoke-test.sh --quick` on push/PR to main.

## Architecture

### Skills System (progressive disclosure)

Each skill lives in `skills/<name>/SKILL.md`. The agent loads only `name` and `description` from frontmatter on every session. The full SKILL.md body is read only when the agent decides to use that skill. This keeps the agent's context lean.

Skills are grouped by category: `orchestration`, `flights`, `portals`, `hotels`, `loyalty`, `destinations`, `reference`.

### Data Pipeline

`scripts/skill-meta.tsv` → `scripts/sync-skill-frontmatter.py` → `skills/*/SKILL.md` frontmatter → `scripts/gen-skill-tables.sh` → README.md + llms.txt tables.

The TSV is the source of truth for managed frontmatter fields (`category`, `summary`, `api_key`, `docker_image`). The `name` and `description` fields are owned by each skill's SKILL.md directly.

### Agent Config Files

- `CLAUDE.md` — Claude Code agent instructions (canonical source)
- `AGENTS.md` — Codex/OpenCode agent instructions (kept in sync with CLAUDE.md via `scripts/sync-agent.sh`)
- `agents/travel-hacker.md` — Subagent definition (must stay in sync with CLAUDE.md)
- `.mcp.json` — Claude Code MCP server config
- `opencode.json` — OpenCode MCP server config

### Reference Data

`data/*.json` files contain curated datasets (transfer partners, sweet spots, hotel properties, alliance maps). Skills read these at runtime. Some have TTLs checked by the smoke test.

## Key Conventions

### Skill Frontmatter Rules

Frontmatter values **must not** contain colons (`:`), single quotes (`'`), double quotes (`"`), or backticks (`` ` ``). OpenCode's parser breaks on them. The sync script enforces this.

```yaml
# BAD — colon in value
summary: Amex MR portal: flights, hotels, IAP discounts.

# GOOD
summary: Amex MR portal for flights, hotels, IAP discounts.
```

### Generated Tables Are Read-Only

The skill tables in README.md and llms.txt are generated. Never edit them by hand. Edit the source (TSV or skill frontmatter), then regenerate:

```bash
python3 scripts/sync-skill-frontmatter.py   # push TSV → frontmatter
bash scripts/gen-skill-tables.sh            # push frontmatter → README + llms.txt
```

### Adding a New Skill

1. Create `skills/<name>/SKILL.md` with required frontmatter (`name`, `description`, `category`, `summary`)
2. Add a row to `scripts/skill-meta.tsv` (tab-separated)
3. Run `python3 scripts/sync-skill-frontmatter.py && bash scripts/gen-skill-tables.sh`
4. Run `bash scripts/smoke-test.sh --quick` — all checks must pass

### Docker Skills

Browser-automation skills (Southwest, Chase, Amex, AA, TicketsAtWork) use Docker images based on `ghcr.io/borski/patchright-docker`. Images must be public on ghcr.io and listed in setup scripts.

### MCP Servers

Seven MCP servers are configured (`.mcp.json` / `opencode.json`):
- **Free, no keys:** Skiplagged, Kiwi, Trivago, Ferryhopper, Airbnb
- **Requires key:** LiteAPI (`LITEAPI_API_KEY`)
- **DocumentDB Memory:** persistent agent memory via `documentdb-memory-mcp`. Requires `DOCUMENTDB_URI` (DB defaults to `copilot_memory`).

### Environment Variables

All keys (API keys, DocumentDB URI, etc.) live in `.env` at the repo root. Source it at session start: `source .env`. The file `.env.example` documents all supported keys. The minimum viable setup is `SEATS_AERO_API_KEY` + `SERPAPI_API_KEY`. Never commit secrets.

### Keeping Configs in Sync

After modifying CLAUDE.md, run `bash scripts/sync-agent.sh` to propagate changes to `agents/travel-hacker.md`. The smoke test catches drift.
