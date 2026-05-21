# shellcheck shell=sh
# /etc/profile.d/documentdb-memory.sh
#
# Auto-start the documentdb-agentic-memory session-history sync daemon in
# the background once per sandbox boot, IFF the user has provided a
# DOCUMENTDB_URI. If the var is unset (or the daemon is already running)
# this snippet is a silent no-op, so the sandbox stays usable in either
# mode.
#
# The MCP server itself (documentdb-memory-mcp) is NOT started here —
# Copilot CLI spawns it on stdio via .mcp.json when a tool call arrives.

documentdb_memory_sync_start() {
    [ -n "${DOCUMENTDB_URI:-}" ] || return 0
    command -v documentdb-memory >/dev/null 2>&1 || return 0

    pidfile="${TMPDIR:-/tmp}/documentdb-memory-sync.pid"
    logfile="${HOME}/.cache/documentdb-memory-sync.log"

    if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null; then
        return 0
    fi

    mkdir -p "$(dirname "$logfile")" 2>/dev/null || true
    nohup documentdb-memory sessions sync --watch \
        --interval "${SYNC_INTERVAL:-30s}" \
        >>"$logfile" 2>&1 &
    echo $! >"$pidfile" 2>/dev/null || true
    disown 2>/dev/null || true
}

documentdb_memory_sync_start
