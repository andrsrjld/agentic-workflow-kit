#!/usr/bin/env bash
# =============================================================================
# Agentic Workflow Kit — installer
# -----------------------------------------------------------------------------
# Deploys this kit (the canonical source) into the user's environment:
#   ~/.claude/             rules, commands, hooks, settings (plugins + hook wiring)
#   ~/.agentic-workflows/  portable runbooks + per-project templates
#
# Design contract:
#   * IDEMPOTENT  — safe to re-run; every step checks before it writes.
#   * NON-DESTRUCTIVE — settings.json is backed up and merged, never overwritten.
#   * GRACEFUL — degrades when `claude`/`rtk` are absent (prints manual steps,
#                does not hard-fail). Only missing core prereqs (node/git) abort.
#
# Every step echoes a one-line explanation of WHAT it does and WHY, plus a
# `# MANUAL:` comment giving the hand-run fallback for anyone without this script.
#
# Re-run after editing the kit — the kit repo is the source of truth, this just
# re-syncs it into ~/.claude + ~/.agentic-workflows.
# =============================================================================
set -euo pipefail

# --- Resolve paths -----------------------------------------------------------
# The kit root is this script's parent dir (install/ lives at the repo root).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
AW_HOME="${AGENTIC_WORKFLOWS_HOME:-$HOME/.agentic-workflows}"
SETTINGS="$CLAUDE_HOME/settings.json"

# --- Pretty output -----------------------------------------------------------
c_bold=$'\033[1m'; c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'; c_reset=$'\033[0m'
step() { printf '\n%s==> %s%s\n' "$c_bold" "$1" "$c_reset"; }
info() { printf '    %s\n' "$1"; }
ok()   { printf '    %s✔%s %s\n' "$c_green" "$c_reset" "$1"; }
warn() { printf '    %s!%s %s\n' "$c_yellow" "$c_reset" "$1"; }
die()  { printf '\n%sFATAL:%s %s\n' "$c_red" "$c_reset" "$1" >&2; exit 1; }

printf '%s\n' "${c_bold}Agentic Workflow Kit — installer${c_reset}"
info "kit source : $SCRIPT_DIR"
info "claude home: $CLAUDE_HOME"
info "workflows  : $AW_HOME"

# =============================================================================
# Step 0 — Prerequisites
# What: verify the runtime tools the kit needs. Why: the portable engine is
#       driven by `npx`; node>=20 and git are hard requirements, the rest warn.
# MANUAL: install Node 20+ (https://nodejs.org), git, and npm/pnpm yourself.
# =============================================================================
step "Step 0 — Checking prerequisites"

command -v git >/dev/null 2>&1 || die "git not found — install git and re-run."
ok "git present"

if ! command -v node >/dev/null 2>&1; then
  die "node not found — install Node.js >= 20 (the npx engine needs it) and re-run."
fi
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
if [ "$NODE_MAJOR" -lt 20 ]; then
  die "node $(node --version) is too old — the kit needs Node >= 20."
fi
ok "node $(node --version)"

command -v npx >/dev/null 2>&1 && ok "npx present" || warn "npx not found — Ruflo/claude-flow engine calls will not run."

if command -v pnpm >/dev/null 2>&1; then ok "pnpm present"
elif command -v npm >/dev/null 2>&1; then warn "pnpm not found — falling back to npm (fine for most projects)."
else warn "neither pnpm nor npm found — gate scripts that install deps may fail."; fi

HAVE_CLAUDE=0
if command -v claude >/dev/null 2>&1; then
  HAVE_CLAUDE=1
  ok "claude CLI present ($(claude --version 2>/dev/null | head -1))"
else
  warn "claude CLI not found — plugin/MCP steps will print MANUAL commands instead of running."
fi

# =============================================================================
# Step 1 — Enable plugins (non-destructive settings.json merge)
# What: add the ECC + Ruflo plugins to enabledPlugins. Why: the rules auto-load
#       and the agents/skills come from these plugins.
# MANUAL: edit ~/.claude/settings.json and add the keys under "enabledPlugins".
# =============================================================================
step "Step 1 — Enabling plugins in settings.json"

mkdir -p "$CLAUDE_HOME"
if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.bak"
  ok "backed up settings.json -> settings.json.bak"
else
  echo '{}' > "$SETTINGS"
  info "no settings.json found — created an empty one"
fi

# Merge the plugin keys without clobbering any existing setting.
PLUGINS_JSON='["ecc@ecc","ruflo-core@ruflo","ruflo-swarm@ruflo","ruflo-rag-memory@ruflo","ruflo-autopilot@ruflo"]'
node -e '
  const fs = require("fs");
  const f = process.argv[1];
  const want = JSON.parse(process.argv[2]);
  const s = JSON.parse(fs.readFileSync(f, "utf8"));
  s.enabledPlugins = s.enabledPlugins || {};
  let added = [];
  for (const k of want) { if (s.enabledPlugins[k] !== true) { s.enabledPlugins[k] = true; added.push(k); } }
  fs.writeFileSync(f, JSON.stringify(s, null, 2) + "\n");
  console.log(added.length ? "    enabled: " + added.join(", ") : "    all plugins already enabled");
' "$SETTINGS" "$PLUGINS_JSON"
ok "plugins merged into enabledPlugins"
info "note: plugins resolve from marketplaces (ecc, ruflo). If a marketplace is"
info "      missing, add it once: claude marketplace add affaan-m/ECC ; claude marketplace add ruvnet/ruflo"

# =============================================================================
# Step 2 — Register MCP servers
# What: add the MCP servers the workflow uses. Why: Context7 (docs), GitHub,
#       Exa (web), Memory, Playwright (E2E), Sequential-Thinking (reasoning),
#       and claude-flow (the Ruflo memory/swarm engine behind self-learning).
# MANUAL: run each `claude mcp add ...` command printed below by hand.
# =============================================================================
step "Step 2 — Registering MCP servers"

# Server name  ->  add-command arguments (everything after `claude mcp add <name>`)
add_mcp() {
  local name="$1"; shift
  if [ "$HAVE_CLAUDE" -eq 0 ]; then
    warn "claude absent — MANUAL: claude mcp add $name $*"
    return 0
  fi
  if claude mcp list 2>/dev/null | grep -q "^$name\b\|[: ]$name:"; then
    ok "$name already registered"
    return 0
  fi
  if claude mcp add "$name" "$@" >/dev/null 2>&1; then
    ok "registered $name"
  else
    warn "could not auto-register $name — MANUAL: claude mcp add $name $*"
  fi
}

# claude-flow is the only non-plugin server we add directly (Ruflo engine).
# The plugin:ecc:* servers ship with the ECC plugin enabled in Step 1; we still
# print their manual form for environments where the plugin is unavailable.
add_mcp claude-flow -- npx -y ruflo@latest mcp start

if [ "$HAVE_CLAUDE" -eq 1 ]; then
  info "context7/github/exa/memory/playwright/sequential-thinking ship with the ECC"
  info "plugin (Step 1). Verify with: claude mcp list"
else
  info "MANUAL (only needed without the ECC plugin):"
  info "  claude mcp add context7 -- npx -y @upstash/context7-mcp"
  info "  claude mcp add github -- npx -y @modelcontextprotocol/server-github"
  info "  claude mcp add memory -- npx -y @modelcontextprotocol/server-memory"
  info "  claude mcp add playwright -- npx -y @playwright/mcp --extension"
  info "  claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking"
  info "  (exa is an HTTP server: claude mcp add --transport http exa https://mcp.exa.ai/mcp)"
fi

# =============================================================================
# Step 3 — RTK (token-saving proxy)
# What: check for the optional `rtk` binary. Why: it transparently rewrites
#       common dev commands to save tokens via a PreToolUse hook.
# MANUAL: install rtk per its README, then it self-wires the PreToolUse hook.
# =============================================================================
step "Step 3 — RTK token-saver (optional)"
if command -v rtk >/dev/null 2>&1; then
  ok "rtk present ($(rtk --version 2>/dev/null | head -1))"
  info "its PreToolUse hook (rtk hook claude) is preserved by Step 6's merge."
else
  warn "rtk not found — optional. Install it to save 60-90% tokens on dev ops."
  info "MANUAL: see the kit docs/INSTALL.md 'RTK' section for the install pointer."
fi

# =============================================================================
# Step 4 — Deploy global rules
# What: copy rules/*.md into the ECC auto-load dir. Why: any .md there loads
#       into every Claude session automatically — the nervous-system, learning,
#       routing, testing, and docs-format rules become globally active.
# MANUAL: cp rules/*.md ~/.claude/rules/ecc/common/
# =============================================================================
step "Step 4 — Deploying global rules"
RULES_DEST="$CLAUDE_HOME/rules/ecc/common"
mkdir -p "$RULES_DEST"
if compgen -G "$SCRIPT_DIR/rules/*.md" >/dev/null; then
  cp "$SCRIPT_DIR"/rules/*.md "$RULES_DEST"/
  ok "copied $(ls "$SCRIPT_DIR"/rules/*.md | wc -l | tr -d ' ') rules -> $RULES_DEST"
else
  warn "no rules found in $SCRIPT_DIR/rules — skipping"
fi

# =============================================================================
# Step 5 — Deploy commands + hooks
# What: copy /nerve + /agentic-init commands and the nerve + guardrail hooks.
# Why: commands are the Claude frontends; hooks drive warm-start, capture,
#      consolidate, and the safety guardrail. Hooks are made executable.
# MANUAL: cp claude/commands/* ~/.claude/commands/ ; cp claude/hooks/* ~/.claude/hooks/ ; chmod +x ~/.claude/hooks/*.sh
# =============================================================================
step "Step 5 — Deploying commands, hooks, persona, gotchas"
mkdir -p "$CLAUDE_HOME/commands" "$CLAUDE_HOME/hooks"
if compgen -G "$SCRIPT_DIR/claude/commands/*" >/dev/null; then
  cp -R "$SCRIPT_DIR"/claude/commands/* "$CLAUDE_HOME/commands/"
  ok "copied commands -> $CLAUDE_HOME/commands"
else
  warn "no commands found in $SCRIPT_DIR/claude/commands — skipping"
fi
if compgen -G "$SCRIPT_DIR/claude/hooks/*" >/dev/null; then
  cp -R "$SCRIPT_DIR"/claude/hooks/* "$CLAUDE_HOME/hooks/"
  chmod +x "$CLAUDE_HOME"/hooks/*.sh 2>/dev/null || true
  ok "copied hooks -> $CLAUDE_HOME/hooks (chmod +x applied)"
else
  warn "no hooks found in $SCRIPT_DIR/claude/hooks — skipping"
fi
# Deploy top-level .md files (persona.md, gotchas.md) — referenced via @file in CLAUDE.md.
# MANUAL: cp claude/*.md ~/.claude/
for _md in "$SCRIPT_DIR"/claude/*.md; do
  [ -f "$_md" ] || continue
  cp "$_md" "$CLAUDE_HOME/$(basename "$_md")"
  ok "deployed $(basename "$_md") -> $CLAUDE_HOME"
done

# =============================================================================
# Step 6 — Merge hook wiring + permissions into settings.json
# What: additively merge claude/settings.snippet.json (SessionStart/PostToolUse/
#       Stop hook entries + permissions). Why: warm-start/capture/consolidate
#       hooks must fire — WITHOUT dropping the existing PreToolUse (rtk) hook or
#       any other configured hook/permission.
# MANUAL: hand-merge claude/settings.snippet.json into ~/.claude/settings.json.
# =============================================================================
step "Step 6 — Merging hook wiring + permissions (non-destructive)"
SNIPPET="$SCRIPT_DIR/claude/settings.snippet.json"
if [ -f "$SNIPPET" ]; then
  node -e '
    const fs = require("fs");
    const [, settingsPath, snippetPath] = process.argv;  // node -e: args start at argv[1]
    const s = JSON.parse(fs.readFileSync(settingsPath, "utf8"));
    const snip = JSON.parse(fs.readFileSync(snippetPath, "utf8"));

    // --- Merge hooks additively, per event, dedup by JSON identity. ---
    s.hooks = s.hooks || {};
    const snipHooks = snip.hooks || {};
    for (const event of Object.keys(snipHooks)) {
      const existing = Array.isArray(s.hooks[event]) ? s.hooks[event] : [];
      const seen = new Set(existing.map(e => JSON.stringify(e)));
      const additions = (snipHooks[event] || []).filter(e => !seen.has(JSON.stringify(e)));
      s.hooks[event] = existing.concat(additions);
    }

    // --- Merge permissions.allow additively (string list union). ---
    if (snip.permissions && Array.isArray(snip.permissions.allow)) {
      s.permissions = s.permissions || {};
      const cur = Array.isArray(s.permissions.allow) ? s.permissions.allow : [];
      const set = new Set(cur);
      for (const p of snip.permissions.allow) set.add(p);
      s.permissions.allow = Array.from(set);
    }

    fs.writeFileSync(settingsPath, JSON.stringify(s, null, 2) + "\n");
    const events = Object.keys(snipHooks).join(", ") || "(none)";
    console.log("    merged hook events: " + events);
  ' "$SETTINGS" "$SNIPPET"
  ok "settings.json hooks + permissions merged (existing PreToolUse/rtk preserved)"
else
  warn "no settings.snippet.json at $SNIPPET — skipping hook wiring"
fi

# =============================================================================
# Step 7 — Deploy templates + runbooks
# What: copy templates/ and agentic-workflows/* into ~/.agentic-workflows.
# Why: /agentic-init reads templates to scaffold projects; the runbooks are the
#      model-agnostic specs Claude/Codex/npx all follow.
# MANUAL: cp -R templates ~/.agentic-workflows/ ; cp agentic-workflows/* ~/.agentic-workflows/
# =============================================================================
step "Step 7 — Deploying templates + runbooks"
mkdir -p "$AW_HOME"
if [ -d "$SCRIPT_DIR/templates" ]; then
  cp -R "$SCRIPT_DIR/templates" "$AW_HOME/"
  ok "copied templates -> $AW_HOME/templates"
else
  warn "no templates dir — skipping"
fi
if compgen -G "$SCRIPT_DIR/agentic-workflows/*" >/dev/null; then
  cp "$SCRIPT_DIR"/agentic-workflows/* "$AW_HOME/"
  ok "copied runbooks -> $AW_HOME"
else
  warn "no runbooks in $SCRIPT_DIR/agentic-workflows — skipping"
fi
# The ADOPTION-GUIDE is authored under docs/ but also belongs in ~/.agentic-workflows
# so the portable engine can read it without the kit repo checked out.
if [ -f "$SCRIPT_DIR/docs/ADOPTION-GUIDE.md" ]; then
  cp "$SCRIPT_DIR/docs/ADOPTION-GUIDE.md" "$AW_HOME/ADOPTION-GUIDE.md"
  ok "copied ADOPTION-GUIDE.md -> $AW_HOME"
fi

# =============================================================================
# Step 8 — Verify
# What: run the doctor. Why: confirm everything landed and is wired.
# =============================================================================
step "Step 8 — Verifying the install"
if [ -x "$SCRIPT_DIR/install/verify.sh" ]; then
  bash "$SCRIPT_DIR/install/verify.sh" || warn "verify reported warnings — review the table above."
else
  warn "verify.sh not found/executable — run: bash $SCRIPT_DIR/install/verify.sh"
fi

step "Done"
info "Next: open any project and run  /agentic-init  then  /nerve \"<task>\""
info "Edit the kit and re-run this installer to push changes — the kit is the source of truth."
