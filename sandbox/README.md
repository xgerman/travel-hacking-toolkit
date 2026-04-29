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
  --platform linux/amd64 \
  --push \
  -t "$IMAGE" \
  sandbox/
```

> Use `linux/amd64` even on Apple Silicon — Docker Sandboxes runs amd64 microVMs.

## Run

```bash
sbx run \
  --template ghcr.io/xgerman/sbx-playwright:latest \
  --agent copilot \
  --allow-domains \
    registry.npmjs.org,\
    cdn.playwright.dev,\
    playwright.azureedge.net,\
    playwright.download.prss.microsoft.com,\
    storage.googleapis.com,\
    fonts.gstatic.com,\
    fonts.googleapis.com
```

Add whatever target sites your automation hits (e.g. `southwest.com`,
`google.com`, `flights.google.com`). Or use `--allow-all` while iterating.

Inside the sandbox:

```bash
# quick smoke test
node -e "(async()=>{const{chromium}=require('playwright');\
const b=await chromium.launch();const p=await b.newPage();\
await p.goto('https://example.com');console.log(await p.title());\
await b.close();})()"

# headed mode (Patchright / undetected)
xvfb-run-here python3 -c "from patchright.sync_api import sync_playwright; \
import sys; \
p=sync_playwright().start(); b=p.chromium.launch(headless=False); \
pg=b.new_page(); pg.goto('https://example.com'); print(pg.title()); b.close()"
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
- `agent-browser install` is run with `|| true` because some sub-installers
  expect interactive prompts; re-run it inside the sandbox if you hit a
  missing-component error.
