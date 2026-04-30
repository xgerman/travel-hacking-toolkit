# Playwright + Chromium Sandbox Template

Custom [Docker Sandbox](https://docs.docker.com/ai/sandboxes/) template that
extends `docker/sandbox-templates:copilot` and pre-installs:

- **Playwright** (Node) + Chromium browser
- **Patchright** (Python) + Chromium browser — used by `skills/southwest`
- **agent-browser** (Node) — used by `skills/google-flights`
- **Xvfb** + `xvfb-run-here` helper for headed-mode automation
- All Chromium system libs (`libnss3`, `libgbm1`, `libxkbcommon0`, fonts, …)

Browsers cache under `/home/agent/.cache/ms-playwright` so the non-root `agent`
user inside the sandbox can launch them without re-downloading.

## Build & push

The sandbox runtime pulls templates from a registry — it does **not** share
your local Docker image store. You must push to a registry `sbx` can reach.

```bash
# from repo root
IMAGE=ghcr.io/xgerman/sbx-playwright:latest

docker buildx build \
  --push \
  -t "$IMAGE" \
  sandbox/
```

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
