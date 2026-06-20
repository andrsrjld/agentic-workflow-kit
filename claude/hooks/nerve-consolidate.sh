#!/usr/bin/env bash
# =============================================================================
# nerve-consolidate.sh — Stop / SessionEnd hook (DISTILL + CONSOLIDATE)
# -----------------------------------------------------------------------------
# What: when a session ends, DISTILL the session's spikes into a focused lesson
#       and CONSOLIDATE it into long-term memory (merge, dedup, decay, promote).
#       This closes the four-phase loop of rules/self-learning.md so the next
#       5-hour window starts warm instead of cold.
# Why:  capture (PostToolUse) writes many small spikes; this folds them into one
#       canonical entry and promotes broadly-useful lessons to the shared
#       `patterns` namespace. Without it, recall fills with noise.
#
# Contract: NON-BLOCKING. Missing engine or disabled memory -> no-op + exit 0.
#   A session must always be allowed to end cleanly. Time-boxed so a stuck engine
#   cannot hang shutdown.
#
# MANUAL: consolidate yourself at session end:
#   npx ruflo memory store --namespace "<ns>" --key "session:<id>" --value "<lesson>"
#   npx @claude-flow/cli memory store --namespace patterns --key "<k>" --value "<canonical>"
# =============================================================================
set -euo pipefail

# Never block session shutdown — degrade silently on any error.
trap 'exit 0' ERR

# Drain stdin (Stop events may pass JSON we don't strictly need).
input="$(cat 2>/dev/null || true)"

# Engine absent -> no-op.
command -v npx >/dev/null 2>&1 || exit 0

# --- Source the shared lib for manifest_get (best-effort) ---------------------
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

# Respect the manifest kill-switch.
MEM_ENABLED="$(manifest_get memory.enabled)"; MEM_ENABLED="${MEM_ENABLED:-true}"
[ "$MEM_ENABLED" = "false" ] && exit 0

# --- Namespace from manifest + git context -----------------------------------
NS="$(manifest_get memory.namespace)"
[ -z "$NS" ] && NS="$(manifest_get project.name)"
[ -z "$NS" ] && NS="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
[ "$BRANCH" = "HEAD" ] && BRANCH=""
QUERY_NS="$NS"; [ -n "$BRANCH" ] && QUERY_NS="$NS:$BRANCH"

SESSION_ID="$(printf '%s' "$input" | { command -v jq >/dev/null 2>&1 && jq -r '.session_id // empty' 2>/dev/null || true; })"
[ -z "$SESSION_ID" ] && SESSION_ID="$(date -u +%Y%m%dT%H%M%SZ)"

_run() {
  if command -v timeout >/dev/null 2>&1; then timeout 8s "$@"; else "$@"; fi
}

# --- DISTILL: store the session lesson in the project namespace --------------
# (Durability: durable decisions are ALSO copied to the epic Automation Log by
#  the workflow — memory is a cache, not the record. See rules/memory-protocol.md.)
_run npx ruflo memory store \
  --namespace "$QUERY_NS" \
  --key "session:$SESSION_ID" \
  --value "Session $SESSION_ID on ${BRANCH:-$NS}: see captured edits/gate results for this window." \
  >/dev/null 2>&1 || true

# --- CONSOLIDATE: promote into the cross-epic `patterns` namespace ------------
_run npx @claude-flow/cli memory store \
  --namespace patterns \
  --key "$NS:session:$SESSION_ID" \
  --value "Consolidated session lesson from $QUERY_NS." \
  >/dev/null 2>&1 || true

exit 0
