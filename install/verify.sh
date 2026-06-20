#!/usr/bin/env bash
# =============================================================================
# verify.sh — Agentic Workflow Kit doctor (run by install/install.sh Step 8)
# -----------------------------------------------------------------------------
# What: idempotent, READ-ONLY checks that confirm the kit landed and is wired.
#       Prints a PASS/WARN table covering prereqs, deployed rules/commands/hooks,
#       the settings.json merge, runbooks/templates, and the memory engine.
# Why:  one command answers "is my install healthy?" without changing anything.
#
# Contract: warnings are NOT failures. The doctor exits 0 even with warnings —
#   the kit degrades gracefully (no Ruflo/claude is a WARN, not an error). It
#   only exits non-zero when a HARD requirement (node>=20 or git) is missing.
#
# MANUAL: run it any time:  bash install/verify.sh
# =============================================================================
set -uo pipefail   # NOTE: no -e — a failed check must not abort the whole table.

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
AW_HOME="${AGENTIC_WORKFLOWS_HOME:-$HOME/.agentic-workflows}"
SETTINGS="$CLAUDE_HOME/settings.json"

c_bold=$'\033[1m'; c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'; c_reset=$'\033[0m'

PASS_N=0; WARN_N=0; FAIL_N=0
pass() { printf '  %s[PASS]%s %s\n' "$c_green"  "$c_reset" "$1"; PASS_N=$((PASS_N+1)); }
warn() { printf '  %s[WARN]%s %s\n' "$c_yellow" "$c_reset" "$1"; WARN_N=$((WARN_N+1)); }
fail() { printf '  %s[FAIL]%s %s\n' "$c_red"    "$c_reset" "$1"; FAIL_N=$((FAIL_N+1)); }
head() { printf '\n%s%s%s\n' "$c_bold" "$1" "$c_reset"; }

printf '%sAgentic Workflow Kit — doctor%s\n' "$c_bold" "$c_reset"
printf '  claude home: %s\n' "$CLAUDE_HOME"
printf '  workflows  : %s\n' "$AW_HOME"

# --- Hard prerequisites (the only things that can fail the doctor) -----------
head "Prerequisites"
if command -v git >/dev/null 2>&1; then pass "git present"; else fail "git not found (hard requirement)"; fi
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [ "$NODE_MAJOR" -ge 20 ]; then pass "node $(node --version) (>= 20)"
  else fail "node $(node --version) too old — need >= 20 (hard requirement)"; fi
else
  fail "node not found — need >= 20 (hard requirement)"
fi
command -v npx   >/dev/null 2>&1 && pass "npx present"        || warn "npx not found — Ruflo/claude-flow engine calls will no-op"
command -v claude >/dev/null 2>&1 && pass "claude CLI present" || warn "claude CLI not found — plugin/MCP/hook wiring is manual"
command -v rtk   >/dev/null 2>&1 && pass "rtk present (token saver)" || warn "rtk not found (optional token saver)"

# --- Global rules (7 expected) -----------------------------------------------
head "Global rules ($CLAUDE_HOME/rules/ecc/common)"
RULES_DEST="$CLAUDE_HOME/rules/ecc/common"
EXPECTED_RULES=(nervous-system memory-protocol self-learning graph-intelligence docs-source-of-truth testing routing)
if [ -d "$RULES_DEST" ]; then
  for r in "${EXPECTED_RULES[@]}"; do
    if [ -f "$RULES_DEST/$r.md" ]; then pass "rule $r.md"; else warn "rule $r.md missing (re-run install.sh Step 4)"; fi
  done
else
  warn "rules dir absent — re-run install.sh Step 4"
fi

# --- Commands (/nerve + /agentic-init) ---------------------------------------
head "Commands ($CLAUDE_HOME/commands)"
for c in nerve agentic-init; do
  if [ -f "$CLAUDE_HOME/commands/$c.md" ]; then pass "/$c command"; else warn "/$c command missing (re-run install.sh Step 5)"; fi
done

# --- Nerve hooks (3 expected) ------------------------------------------------
head "Nerve hooks ($CLAUDE_HOME/hooks)"
for h in nerve-session-start nerve-capture nerve-consolidate; do
  f="$CLAUDE_HOME/hooks/$h.sh"
  if [ -f "$f" ]; then
    if [ -x "$f" ]; then pass "hook $h.sh (executable)"; else warn "hook $h.sh present but not +x (run: chmod +x $f)"; fi
  else
    warn "hook $h.sh missing (re-run install.sh Step 5)"
  fi
done
# The guardrail ports alongside the nerve hooks; report it too.
if [ -f "$CLAUDE_HOME/hooks/guardrail.sh" ]; then pass "guardrail.sh present"; else warn "guardrail.sh missing (optional safety gate)"; fi

# --- settings.json wiring (hook events + permissions) ------------------------
head "settings.json wiring"
if [ -f "$SETTINGS" ] && command -v node >/dev/null 2>&1; then
  node -e '
    const fs = require("fs");
    let s; try { s = JSON.parse(fs.readFileSync(process.argv[1], "utf8")); } catch { console.log("WARN settings.json unreadable"); process.exit(0); }
    const hooks = s.hooks || {};
    const join = (ev) => JSON.stringify(hooks[ev] || []);
    const has = (ev, needle) => join(ev).includes(needle);
    const checks = [
      ["SessionStart", "nerve-session-start.sh"],
      ["PostToolUse",  "nerve-capture.sh"],
      ["Stop",         "nerve-consolidate.sh"],
    ];
    for (const [ev, needle] of checks) {
      console.log((has(ev, needle) ? "PASS " : "WARN ") + ev + " wires " + needle);
    }
    // PreToolUse must be PRESERVED, not added by us — just report if present.
    if (Array.isArray(hooks.PreToolUse) && hooks.PreToolUse.length) {
      console.log("PASS PreToolUse preserved (" + hooks.PreToolUse.length + " entr" + (hooks.PreToolUse.length===1?"y":"ies") + ")");
    } else {
      console.log("WARN PreToolUse empty (rtk/guardrail not wired — fine if intentional)");
    }
    const allow = (s.permissions && s.permissions.allow) || [];
    const hasPerm = (p) => allow.some(a => a.indexOf(p) !== -1);
    console.log((hasPerm("npx ruflo") ? "PASS " : "WARN ") + "permission Bash(npx ruflo*)");
    console.log((hasPerm("@claude-flow/cli") ? "PASS " : "WARN ") + "permission Bash(npx @claude-flow/cli*)");
  ' "$SETTINGS" | while IFS= read -r line; do
      case "$line" in
        PASS\ *) pass "${line#PASS }";;
        WARN\ *) warn "${line#WARN }";;
        *) warn "$line";;
      esac
    done
else
  warn "settings.json or node missing — cannot verify hook wiring"
fi

# --- Runbooks + templates ----------------------------------------------------
head "Runbooks + templates ($AW_HOME)"
if [ -d "$AW_HOME/templates" ]; then pass "templates/ deployed"; else warn "templates/ missing (re-run install.sh Step 7)"; fi
if [ -f "$AW_HOME/templates/scripts/_agentic_lib.sh" ]; then pass "_agentic_lib.sh template present"; else warn "_agentic_lib.sh template missing"; fi
if [ -f "$AW_HOME/templates/agentic/config.yml" ]; then pass "config.yml manifest template present"; else warn "config.yml manifest template missing"; fi
if compgen -G "$AW_HOME/*.md" >/dev/null 2>&1; then pass "runbooks (*.md) deployed"; else warn "no runbooks in $AW_HOME (re-run install.sh Step 7)"; fi

# --- Memory engine (graceful note when absent) -------------------------------
head "Memory engine (optional accelerator)"
if command -v npx >/dev/null 2>&1; then
  pass "npx available — Ruflo/claude-flow can be invoked on demand"
  warn "engine reachability not probed here (would cost a network call); hooks degrade to no-op if absent"
else
  warn "npx absent — memory hooks will no-op; the workflow still runs on plain tools"
fi

# --- Summary -----------------------------------------------------------------
head "Summary"
printf '  %s%d PASS%s · %s%d WARN%s · %s%d FAIL%s\n' \
  "$c_green" "$PASS_N" "$c_reset" "$c_yellow" "$WARN_N" "$c_reset" "$c_red" "$FAIL_N" "$c_reset"

if [ "$FAIL_N" -gt 0 ]; then
  printf '  %sDoctor found %d hard failure(s) — fix the prerequisites above.%s\n' "$c_red" "$FAIL_N" "$c_reset"
  exit 1
fi
printf '  %sInstall healthy%s (warnings are optional/degradable, not failures).\n' "$c_green" "$c_reset"
exit 0
