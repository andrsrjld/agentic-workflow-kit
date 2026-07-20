#!/usr/bin/env bash
# =============================================================================
# nerve-warm-start.sh — invoked by ../index.ts on the Pi `session_start` event
# -----------------------------------------------------------------------------
# Same RETRIEVE logic as claude/hooks/nerve-session-start.sh: print a compact
# warm-start context block to stdout so a fresh session begins already knowing
# prior decisions instead of re-reading files. No stdin/argv needed.
#
# Contract: CHEAP and FAST (<5s), and NEVER blocks. No-ops when npx/Ruflo is
#   absent or times out, or when memory is disabled in the manifest.
# =============================================================================
set -euo pipefail
trap 'exit 0' ERR

_find_lib() {
  local dir; dir="$(pwd)"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/scripts/_agentic_lib.sh" ]; then printf '%s' "$dir/scripts/_agentic_lib.sh"; return; fi
    dir="$(dirname "$dir")"
  done
  for c in "$HOME/.agentic-workflows/templates/scripts/_agentic_lib.sh"; do
    [ -f "$c" ] && { printf '%s' "$c"; return; }
  done
  printf '%s' ""
}

LIB="$(_find_lib)"
if [ -n "$LIB" ]; then
  # shellcheck source=/dev/null
  . "$LIB" 2>/dev/null || true
fi

if ! declare -f manifest_get >/dev/null 2>&1; then manifest_get() { printf '%s' ""; }; fi

MEM_ENABLED="$(manifest_get memory.enabled)"; MEM_ENABLED="${MEM_ENABLED:-true}"
MEM_WARM="$(manifest_get memory.warm_start)"; MEM_WARM="${MEM_WARM:-true}"
[ "$MEM_ENABLED" = "false" ] && exit 0
[ "$MEM_WARM" = "false" ] && exit 0

command -v npx >/dev/null 2>&1 || exit 0

NS="$(manifest_get memory.namespace)"
[ -z "$NS" ] && NS="$(manifest_get project.name)"
if [ -z "$NS" ]; then
  NS="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
fi
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
[ -z "$BRANCH" ] || [ "$BRANCH" = "HEAD" ] && BRANCH=""

TOP_K="$(manifest_get memory.top_k)"; TOP_K="${TOP_K:-8}"

QUERY_NS="$NS"
[ -n "$BRANCH" ] && QUERY_NS="$NS:$BRANCH"
QUERY="${NS}${BRANCH:+:$BRANCH} recent decisions, proven patterns, known failure modes"

_run() {
  if command -v timeout >/dev/null 2>&1; then timeout 5s "$@"; else "$@"; fi
}

RECALL="$(_run npx ruflo memory search \
  --query "$QUERY" \
  --namespace "$QUERY_NS" \
  --limit "$TOP_K" 2>/dev/null || true)"

[ -z "$RECALL" ] && exit 0

printf '<nerve-warm-start ns="%s">\n' "$QUERY_NS"
printf 'Recalled top-%s prior memories for this repo%s. Recall instead of re-reading:\n' \
  "$TOP_K" "${BRANCH:+ + branch $BRANCH}"
printf '%s\n' "$RECALL" | head -n 40
printf '</nerve-warm-start>\n'

exit 0
