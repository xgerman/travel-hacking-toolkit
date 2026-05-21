# Custom Docker Sandbox with Playwright + Chromium pre-installed.
# Docs: https://docs.docker.com/ai/sandboxes/customize/templates/
#
# Swap FROM to: claude-code | codex | gemini | opencode | shell
# Append -docker for Docker-in-sandbox (e.g. copilot-docker).

# ---------------------------------------------------------------------------
# Stage 1: builder for documentdb-agentic-memory
#
# We compile better-sqlite3's native bindings here, then COPY only the
# resulting dist/ + production node_modules/ into the final sandbox image.
# This keeps git + the C++ toolchain (~400 MB of headers, gcc, perl, …)
# out of the runtime layer.
#
# Pinning to node:20-bookworm-slim matters: it shares the NODE_MODULE_VERSION
# (115) with the Node 20 binary inside docker/sandbox-templates:copilot, so
# the `.node` ABI binary compiled here loads cleanly there. Bumping either
# side past Node 20 requires updating the other to match.
# ---------------------------------------------------------------------------
FROM node:20-bookworm-slim AS memory-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        git python3 make g++ ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --depth 1 https://github.com/xgerman/documentdb-agentic-memory.git . \
    && npm install --no-audit --no-fund \
    && npm run build \
    && npm prune --omit=dev

# ---------------------------------------------------------------------------
# Stage 2: the actual sandbox
# ---------------------------------------------------------------------------
FROM docker/sandbox-templates:copilot

USER root

# System deps for Chromium + Xvfb, global Node/Python tools — single layer.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libnss3 libatk1.0-0t64 libatk-bridge2.0-0t64 libcups2t64 libdrm2 \
        libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
        libgbm1 libpango-1.0-0 libcairo2 libasound2t64 libx11-xcb1 \
        libxshmfence1 fonts-liberation fonts-noto-color-emoji \
        xvfb xauth ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g playwright@latest agent-browser@latest \
    && pip3 install --no-cache-dir --break-system-packages patchright

# Drop in the pre-built documentdb-agentic-memory tree from the builder
# stage. The bins declared in its package.json (documentdb-memory-mcp,
# documentdb-memory) are exposed via /usr/local/bin symlinks so they
# resolve for both the `agent` user's shell and any subprocess the
# Copilot CLI spawns (e.g. the MCP server itself).
COPY --from=memory-builder /build/dist          /opt/documentdb-memory/dist
COPY --from=memory-builder /build/node_modules  /opt/documentdb-memory/node_modules
COPY --from=memory-builder /build/package.json  /opt/documentdb-memory/package.json
RUN ln -sf /opt/documentdb-memory/dist/server/index.js /usr/local/bin/documentdb-memory-mcp \
    && ln -sf /opt/documentdb-memory/dist/cli/index.js   /usr/local/bin/documentdb-memory

# Profile snippet that auto-starts the session-history sync daemon in the
# background at shell login, but only if the user has set DOCUMENTDB_URI.
# Idempotent via a PID file so re-sourcing /etc/profile (or opening a new
# shell) does not spawn duplicates.
COPY sandbox/profile-documentdb-memory.sh /etc/profile.d/documentdb-memory.sh
RUN chmod +x /etc/profile.d/documentdb-memory.sh

# Download browsers as `agent` so they're accessible at runtime.
USER agent
ENV PLAYWRIGHT_BROWSERS_PATH=/home/agent/.cache/ms-playwright
RUN npx --yes playwright install chromium \
    && python3 -m patchright install chromium

# agent-browser's built-in `install` only ships Chrome for Testing (amd64).
# On ARM64 (e.g. Apple Silicon / Graviton) it fails, so we create a symlink
# from its expected cache dir to the Playwright Chromium we already downloaded.
# On amd64 we still try the native install; the symlink is a harmless no-op.
RUN agent-browser install 2>/dev/null \
    || { mkdir -p /home/agent/.agent-browser/browsers \
      && CHROME=$(find "$PLAYWRIGHT_BROWSERS_PATH" -name chrome -type f | head -1) \
      && [ -n "$CHROME" ] \
      && ln -sf "$CHROME" /home/agent/.agent-browser/browsers/chrome; }

# xvfb-run-here: tiny wrapper for headed-mode automation (Patchright / SW skill).
USER root
RUN printf '#!/usr/bin/env bash\nset -euo pipefail\nXvfb :99 -screen 0 1440x900x24 -nolisten tcp &\nXVFB_PID=$!\ntrap '\''kill $XVFB_PID 2>/dev/null || true'\'' EXIT\nexport DISPLAY=:99\nsleep 1\nexec "$@"\n' \
      > /usr/local/bin/xvfb-run-here && chmod +x /usr/local/bin/xvfb-run-here

USER agent
WORKDIR /home/agent
