#!/usr/bin/env bash
# =============================================================================
# nerve-consolidate.sh — invoked by ../index.ts on the Pi `session_shutdown`
# event
# -----------------------------------------------------------------------------
# Adapted from claude/hooks/nerve-consolidate.sh: same DISTILL + CONSOLIDATE,
# but takes an optional session identifier as a CLI arg instead of parsing it
# from a Stop-event JSON payload (`pi.exec()` has no stdin).
#
# Usage: nerve-consolidate.sh [session-id]
#
# Contract: NON-BLOCKING. Missing engine or disabled memory -> no-op + exit 0.
#   Time-boxed so a stuck engine cannot hang session shutdown.
# =============================================================================
set -euo pipefail
trap 'exit 0' ERR

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

SESSION_ID="${1:-}"
[ -z "$SESSION_ID" ] && SESSION_ID="$(date -u +%Y%m%dT%H%M%SZ)"
# A session file path makes a noisy memory key — keep just the basename.
SESSION_ID="$(basename "$SESSION_ID")"

_run() {
  if command -v timeout >/dev/null 2>&1; then timeout 8s "$@"; else "$@"; fi
}

_run npx ruflo memory store \
  --namespace "$QUERY_NS" \
  --key "session:$SESSION_ID" \
  --value "Session $SESSION_ID on ${BRANCH:-$NS}: see captured edits/gate results for this window." \
  >/dev/null 2>&1 || true

_run npx @claude-flow/cli memory store \
  --namespace patterns \
  --key "$NS:session:$SESSION_ID" \
  --value "Consolidated session lesson from $QUERY_NS." \
  >/dev/null 2>&1 || true

exit 0
