# Custom Docker Sandbox template with Playwright + Chromium pre-installed.
#
# Docs: https://docs.docker.com/ai/sandboxes/customize/templates/
#
# Base variant matches the agent you'll launch with `sbx run --agent ...`.
# Default = copilot (GitHub Copilot CLI). Swap the FROM line to one of:
#   docker/sandbox-templates:claude-code
#   docker/sandbox-templates:codex
#   docker/sandbox-templates:gemini
#   docker/sandbox-templates:opencode
#   docker/sandbox-templates:shell           (agent-agnostic)
#   docker/sandbox-templates:<variant>-docker (adds Docker-in-sandbox)
FROM docker/sandbox-templates:copilot

# --- system deps for Chromium (must be root) -----------------------------------
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
        libnss3 \
        libatk1.0-0t64 \
        libatk-bridge2.0-0t64 \
        libcups2t64 \
        libdrm2 \
        libxkbcommon0 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxrandr2 \
        libgbm1 \
        libpango-1.0-0 \
        libcairo2 \
        libasound2t64 \
        libx11-xcb1 \
        libxshmfence1 \
        fonts-liberation \
        fonts-noto-color-emoji \
        xvfb \
        xauth \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Global Node tools: Playwright + agent-browser (both used by skills/).
# Installed globally as root so every shell session can resolve them on PATH.
RUN npm install -g playwright@latest agent-browser@latest

# Python browser-automation lib used by the `southwest` skill.
# Use --break-system-packages because the base image's python is PEP 668-managed.
RUN pip3 install --no-cache-dir --break-system-packages patchright

# --- browsers cache under agent's $HOME so they're visible at runtime ---------
USER agent
ENV PLAYWRIGHT_BROWSERS_PATH=/home/agent/.cache/ms-playwright

RUN npx --yes playwright install chromium \
    && python3 -m patchright install chromium \
    && agent-browser install || true

# Convenience: a tiny xvfb wrapper for headed-mode automation (used by Patchright).
# Usage:  xvfb-run-here python3 my_script.py
USER root
RUN cat > /usr/local/bin/xvfb-run-here <<'EOF' \
 && chmod +x /usr/local/bin/xvfb-run-here
#!/usr/bin/env bash
set -euo pipefail
Xvfb :99 -screen 0 1440x900x24 -nolisten tcp &
XVFB_PID=$!
trap 'kill $XVFB_PID 2>/dev/null || true' EXIT
export DISPLAY=:99
sleep 1
exec "$@"
EOF

USER agent
WORKDIR /home/agent
