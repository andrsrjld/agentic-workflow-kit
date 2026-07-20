#!/usr/bin/env bash
# =============================================================================
# nerve-capture.sh — invoked by ../index.ts on the Pi `tool_execution_start`
# event, for the `edit`/`write` tools only
# -----------------------------------------------------------------------------
# Adapted from claude/hooks/nerve-capture.sh: same incremental CAPTURE, but
# `pi.exec()` has no stdin (spawned with stdio "ignore" for stdin), so this
# takes the file path and tool name as plain CLI args instead of parsing a
# PostToolUse JSON event. No jq dependency needed as a result.
#
# Usage: nerve-capture.sh <file-path> <tool-name>
#
# Contract: FAST and NON-BLOCKING; never a blocking exit code (always 0).
# =============================================================================
set -euo pipefail
trap 'exit 0' ERR

file="${1:-}"
[ -z "$file" ] && exit 0

command -v npx >/dev/null 2>&1 || exit 0

_find_lib() {
  local dir; dir="$(pwd)"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/scripts/_agentic_lib.sh" ]; then printf '%s' "$dir/scripts/_agentic_lib.sh"; return; fi
    dir="$(dirname "$dir")"
  done
  [ -f "$HOME/.agentic-workflows/templates/scripts/_agentic_lib.sh" ] && \
    printf '%s' "$HOME/.agentic-workflows/templates/scripts/_agentic_lib.sh"
}
LIB="$(_find_lib)"
[ -n "${LIB:-}" ] && { . "$LIB" 2>/dev/null || true; }
if ! declare -f manifest_get >/dev/null 2>&1; then manifest_get() { printf '%s' ""; }; fi

MEM_ENABLED="$(manifest_get memory.enabled)"; MEM_ENABLED="${MEM_ENABLED:-true}"
[ "$MEM_ENABLED" = "false" ] && exit 0

NS="$(manifest_get memory.namespace)"
[ -z "$NS" ] && NS="$(manifest_get project.name)"
[ -z "$NS" ] && NS="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
[ "$BRANCH" = "HEAD" ] && BRANCH=""
QUERY_NS="$NS"; [ -n "$BRANCH" ] && QUERY_NS="$NS:$BRANCH"

_run() {
  if command -v timeout >/dev/null 2>&1; then timeout 5s "$@"; else "$@"; fi
}

(
  _run npx @claude-flow/cli hooks post-edit --file "$file" >/dev/null 2>&1 || true
  _run npx ruflo memory store \
    --namespace "$QUERY_NS" \
    --key "edit:$file" \
    --value "Edited $file at $(date -u +%FT%TZ)" >/dev/null 2>&1 || true
) >/dev/null 2>&1 &

exit 0
