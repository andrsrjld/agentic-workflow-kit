#!/usr/bin/env bash
# =============================================================================
# nerve-session-start.sh — SessionStart hook (the WARM START)
# -----------------------------------------------------------------------------
# What: at the start of a session, RETRIEVE the top-K relevant memories for this
#       repo + branch + (optional) epic and print a compact context block to
#       stdout. Claude injects stdout into the session, so a fresh 5-hour window
#       begins already knowing the prior decisions instead of re-reading files.
# Why:  this is the primary token-saving win of the kit — recall over re-read.
#       Implements the "retrieve" phase of rules/self-learning.md + the warm-start
#       described in rules/memory-protocol.md.
#
# Contract: CHEAP and FAST (<5s), and NEVER blocks. It no-ops + exit 0 when
#   `npx`/Ruflo is absent or times out, or when memory is disabled in the
#   manifest. It only ever prints context; it never fails a session.
#
# MANUAL: run the warm start yourself at session begin:
#   npx ruflo memory search --query "<repo>:<branch> recent decisions" --namespace "<ns>"
# =============================================================================
set -euo pipefail

# Never let an unexpected error propagate into the session — degrade silently.
trap 'exit 0' ERR

# --- Locate the shared lib (best-effort; degrade if absent) ------------------
# Generic gate scripts live at <repo>/scripts/_agentic_lib.sh once a project
# adopts the kit; the templates copy ships at ~/.agentic-workflows/templates too.
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

# Fallbacks when the lib could not be sourced (degraded mode).
if ! declare -f manifest_get >/dev/null 2>&1; then manifest_get() { printf '%s' ""; }; fi
if ! declare -f detect_integration_branch >/dev/null 2>&1; then
  detect_integration_branch() { git rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'main'; }
fi

# --- Respect the manifest memory.* switches ----------------------------------
MEM_ENABLED="$(manifest_get memory.enabled)"; MEM_ENABLED="${MEM_ENABLED:-true}"
MEM_WARM="$(manifest_get memory.warm_start)"; MEM_WARM="${MEM_WARM:-true}"
[ "$MEM_ENABLED" = "false" ] && exit 0   # memory off  -> pure no-op
[ "$MEM_WARM" = "false" ] && exit 0      # warm-start off -> pure no-op

# Engine absent -> no-op (graceful degradation, never block).
command -v npx >/dev/null 2>&1 || exit 0

# --- Build the namespace + query from git context ----------------------------
NS="$(manifest_get memory.namespace)"
[ -z "$NS" ] && NS="$(manifest_get project.name)"
if [ -z "$NS" ]; then
  # Last-resort namespace: the repo directory name.
  NS="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
fi
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
[ -z "$BRANCH" ] || [ "$BRANCH" = "HEAD" ] && BRANCH=""

TOP_K="$(manifest_get memory.top_k)"; TOP_K="${TOP_K:-8}"

# Most-specific namespace first: <ns>:<branch> if on a branch, else <ns>.
QUERY_NS="$NS"
[ -n "$BRANCH" ] && QUERY_NS="$NS:$BRANCH"
QUERY="${NS}${BRANCH:+:$BRANCH} recent decisions, proven patterns, known failure modes"

# --- RETRIEVE (time-boxed; failures swallowed) -------------------------------
# Use `timeout` when available so a stuck engine can never hang the session.
_run() {
  if command -v timeout >/dev/null 2>&1; then timeout 5s "$@"; else "$@"; fi
}

RECALL="$(_run npx ruflo memory search \
  --query "$QUERY" \
  --namespace "$QUERY_NS" \
  --limit "$TOP_K" 2>/dev/null || true)"

# Nothing recalled (engine missing, empty store, or timeout) -> stay silent.
[ -z "$RECALL" ] && exit 0

# --- Emit a compact warm-start context block ---------------------------------
printf '<nerve-warm-start ns="%s">\n' "$QUERY_NS"
printf 'Recalled top-%s prior memories for this repo%s. Recall instead of re-reading:\n' \
  "$TOP_K" "${BRANCH:+ + branch $BRANCH}"
# Trim to keep the injection compact and cheap.
printf '%s\n' "$RECALL" | head -n 40
printf '</nerve-warm-start>\n'

exit 0
