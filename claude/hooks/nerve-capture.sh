#!/usr/bin/env bash
# =============================================================================
# nerve-capture.sh — PostToolUse hook (incremental CAPTURE)
# -----------------------------------------------------------------------------
# What: after a tool runs, capture the spike (an edit, or a gate result) into
#       memory so the session's progress is recorded as it happens. Reads the
#       PostToolUse event JSON from stdin.
# Why:  this feeds the "judge/distill (incremental)" rows of the hybrid auto-save
#       table in rules/memory-protocol.md — small, frequent writes that the Stop
#       hook later consolidates into one canonical lesson.
#
# Contract: FAST and NON-BLOCKING. It must never slow or fail the tool pipeline.
#   Any error, missing engine, or disabled memory -> immediate no-op + exit 0.
#   It NEVER returns a blocking exit code (always 0).
#
# MANUAL: capture a result yourself at task end:
#   npx @claude-flow/cli hooks post-edit --file "<path>"
#   npx ruflo memory store --namespace "<ns>" --key "<k>" --value "<v>"
# =============================================================================
set -euo pipefail

# A capture failure must never break the pipeline — always succeed.
trap 'exit 0' ERR

# Read the event without hanging if stdin is empty.
input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && exit 0

# Engine absent -> no-op. (jq is optional; we degrade without it.)
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

# --- Extract tool name + edited file from the event (jq optional) ------------
tool=""; file=""
if command -v jq >/dev/null 2>&1; then
  tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
  file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"
fi
# Only capture meaningful spikes: file edits/writes. Everything else -> no-op.
case "$tool" in
  Edit|Write|MultiEdit|NotebookEdit) : ;;
  *) exit 0 ;;
esac
[ -z "$file" ] && exit 0

# --- Namespace from manifest + git context -----------------------------------
NS="$(manifest_get memory.namespace)"
[ -z "$NS" ] && NS="$(manifest_get project.name)"
[ -z "$NS" ] && NS="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
[ "$BRANCH" = "HEAD" ] && BRANCH=""
QUERY_NS="$NS"; [ -n "$BRANCH" ] && QUERY_NS="$NS:$BRANCH"

# --- CAPTURE (time-boxed, backgrounded, all output swallowed) ----------------
# We background the engine call and detach it so the tool pipeline is never
# made to wait on memory I/O. Failures are invisible by design.
_run() {
  if command -v timeout >/dev/null 2>&1; then timeout 5s "$@"; else "$@"; fi
}

(
  # Path A: claude-flow's native post-edit capture (no-op if unavailable).
  _run npx @claude-flow/cli hooks post-edit --file "$file" >/dev/null 2>&1 || true
  # Path B: a lightweight ruflo spike entry keyed by file (additive).
  _run npx ruflo memory store \
    --namespace "$QUERY_NS" \
    --key "edit:$file" \
    --value "Edited $file at $(date -u +%FT%TZ)" >/dev/null 2>&1 || true
) >/dev/null 2>&1 &

exit 0
