# Playwright + Chromium Sandbox Template

Custom [Docker Sandbox](https://docs.docker.com/ai/sandboxes/) template that
extends `docker/sandbox-templates:copilot` and pre-installs:

- **Playwright** (Node) + Chromium browser
- **Patchright** (Python) + Chromium browser — used by `skills/southwest`
- **agent-browser** (Node) — used by `skills/google-flights`
- **Xvfb** + `xvfb-run-here` helper for headed-mode automation
- All Chromium system libs (`libnss3`, `libgbm1`, `libxkbcommon0`, fonts, …)
- **documentdb-agentic-memory** — MCP server + session-store sync daemon
  ([repo](https://github.com/xgerman/documentdb-agentic-memory))

Browsers cache under `/home/agent/.cache/ms-playwright` so the non-root `agent`
user inside the sandbox can launch them without re-downloading.

## Agentic memory wiring (optional)

The image installs both `documentdb-memory-mcp` (the 17-tool MCP server) and
`documentdb-memory` (the operator CLI) into `/usr/local/bin`. Both stay
dormant unless you set `DOCUMENTDB_URI` to a central DocumentDB / MongoDB-wire
server. When the URI is set:

- The MCP server is wired in via the repo-root `.mcp.json` and Copilot CLI
  spawns it on the first tool call.
- `/etc/profile.d/documentdb-memory.sh` starts the sync sidecar in the
  background at shell login. It mirrors the sandbox's own
  `~/.copilot/session-store.db` into the central DB every `SYNC_INTERVAL`
  (default `30s`), so sessions from the sandbox become searchable from
  anywhere else that points at the same DB.

No DocumentDB or FUSE containers ship with the sandbox — the assumption is
that you operate a central server somewhere else and point the sandbox at
it. See the [project README](https://github.com/xgerman/documentdb-agentic-memory)
for deployment options.

To enable, set in your `.env` (or in the environment you `sbx run` with):

```bash
DOCUMENTDB_URI=mongodb://user:pass@mem.example.com:10260/?tls=true&tlsInsecure=true
# DOCUMENTDB_DB=copilot_memory      # default
# MEMORY_LOG_LEVEL=info             # debug for troubleshooting
# SYNC_INTERVAL=30s                 # daemon poll cadence
```

Logs from the background sync daemon go to
`~/.cache/documentdb-memory-sync.log` inside the sandbox.

## Build & push

The sandbox runtime pulls templates from a registry — it does **not** share
your local Docker image store. You must push to a registry `sbx` can reach.

```bash
# from repo root
IMAGE=ghcr.io/xgerman/sbx-playwright:latest

docker buildx build \
  --push \
  -t "$IMAGE" \
  -f sandbox/Dockerfile \
  .
```

Note the `-f sandbox/Dockerfile .` form: the build context is the repo root
(so the `COPY sandbox/profile-documentdb-memory.sh …` step can see the
profile snippet), not `sandbox/` alone.

## Run first time

```bash
# Select allow all network traffic
sbx policy reset

# Run the sandbox for the first time
sbx run   --template ghcr.io/xgerman/sbx-playwright:latest  copilot
```

You can cut down on Internet sides and only use the ones
needed.

## Run subsequent
```bash
sbx run copilot-travel-hacking-toolkit
```
## Switching agent variants

Edit the first line of `Dockerfile`:

```dockerfile
FROM docker/sandbox-templates:copilot          # default
# FROM docker/sandbox-templates:claude-code
# FROM docker/sandbox-templates:codex
# FROM docker/sandbox-templates:gemini
# FROM docker/sandbox-templates:opencode
# FROM docker/sandbox-templates:shell          # agent-agnostic
# FROM docker/sandbox-templates:copilot-docker # + Docker-in-sandbox
```

Then rebuild and pass the matching `--agent <variant>` to `sbx run`.

## Notes

- First `sbx run` pulls the image from the registry and caches it locally;
  subsequent runs are fast.
- If you change the Dockerfile, bump the tag (`:v2`, `:2025-04-29`, …) so
  `sbx` re-pulls — `:latest` won't auto-refresh once cached.
- On ARM64 (Apple Silicon, Graviton), Chrome for Testing isn't available so
  `agent-browser install` fails. The Dockerfile works around this by symlinking
  Playwright's Chromium into `~/.agent-browser/browsers/chrome`. On amd64 the
  native install succeeds and the symlink is a harmless no-op.
