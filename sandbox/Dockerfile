# Custom Docker Sandbox with Playwright + Chromium pre-installed.
# Docs: https://docs.docker.com/ai/sandboxes/customize/templates/
#
# Swap FROM to: claude-code | codex | gemini | opencode | shell
# Append -docker for Docker-in-sandbox (e.g. copilot-docker).
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
