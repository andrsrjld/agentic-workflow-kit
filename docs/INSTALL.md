# Installation

The human install tutorial for the Agentic Workflow Kit. It walks you through
prerequisites, the plugins and MCP servers the workflow uses, the one-command
install, and a manual fallback for every step. It is accurate to what
`install/install.sh` and `install/verify.sh` actually do — nothing here invents a
flag the scripts don't have.

> **Mental model.** This repo is the **canonical source**. `install/install.sh`
> deploys it into `~/.claude` (rules, commands, hooks, settings) and
> `~/.agentic-workflows` (runbooks, templates). You edit the kit → re-run the
> installer → it re-syncs. The kit is the source of truth, not your `~/.claude`.

---

## 1. Prerequisites

| Tool | Required? | Why | Get it |
|------|-----------|-----|--------|
| **Node.js ≥ 20** | **Required** (hard) | The portable engine runs through `npx`; the installer aborts below 20 | <https://nodejs.org> |
| **git** | **Required** (hard) | Repo detection, branch model, the installer aborts without it | system package manager |
| **npm or pnpm** | Recommended | Gate scripts install/build deps; `pnpm` preferred, `npm` is fine | ships with Node / `npm i -g pnpm` |
| **npx** | Recommended | Drives Ruflo + claude-flow engine calls; absent → those calls warn, don't fail | ships with npm |
| **claude CLI** | Optional | Auto-registers plugins + MCP servers; absent → installer prints MANUAL commands instead | <https://claude.com/claude-code> |
| **rtk** | Optional | Token-saving proxy (60–90% on dev ops); absent → just skipped | see [RTK](#6-rtk-optional-token-saver) |

The hard requirements are **Node ≥ 20** and **git** — `install.sh` Step 0 calls
`die` (aborts) if either is missing or Node is too old. Everything else degrades
to a warning plus a manual fallback.

```bash
node --version    # must be v20+
git --version
npx --version     # recommended
claude --version  # optional
```

---

## 2. Get the plugins (ECC + Ruflo)

The kit's rules auto-load, but the **agents and skills** come from two plugins:
**ECC** (reviewers, resolvers, skills) and **Ruflo** (core/swarm/memory/autopilot
families). `install.sh` Step 1 merges these plugin keys into
`~/.claude/settings.json` `enabledPlugins`:

```
ecc@ecc · ruflo-core@ruflo · ruflo-swarm@ruflo · ruflo-rag-memory@ruflo · ruflo-autopilot@ruflo
```

Plugins resolve from **marketplaces**. If a marketplace isn't registered, add it
once (the installer prints this same hint in Step 1):

```bash
claude marketplace add affaan-m/ECC      # ECC plugin marketplace
claude marketplace add ruvnet/ruflo       # Ruflo plugin marketplace
```

> **Accuracy note.** The two `claude marketplace add ...` lines above are quoted
> verbatim from the `info` hint in `install.sh` Step 1
> (`affaan-m/ECC` and `ruvnet/ruflo`). The enabled-plugin keys are from the
> installer's `PLUGINS_JSON`. Confirm the marketplace slugs against your Claude
> Code version if `claude marketplace list` doesn't show them after adding.

**MANUAL fallback** (Step 1 without the installer): edit `~/.claude/settings.json`
and add each key under `enabledPlugins`, e.g.

```json
{
  "enabledPlugins": {
    "ecc@ecc": true,
    "ruflo-core@ruflo": true,
    "ruflo-swarm@ruflo": true,
    "ruflo-rag-memory@ruflo": true,
    "ruflo-autopilot@ruflo": true
  }
}
```

The installer does this as a **non-destructive merge** (it backs up
`settings.json` → `settings.json.bak` first and never clobbers existing keys).

---

## 3. Register MCP servers

`install.sh` Step 2 registers the MCP servers the workflow uses. Most ship with
the **ECC plugin** (enabled in Step 2 above); only **claude-flow** is added
directly, because it is the Ruflo memory/swarm engine behind the self-learning
loop.

| Server | Role in the workflow |
|--------|----------------------|
| **context7** | Live library/API docs before implementing (`graph-intelligence` RETRIEVE) |
| **github** | Issue/PR queries, file contents |
| **exa** | Web research when Context7 + GitHub are insufficient |
| **memory** | Cross-session pattern/decision storage |
| **playwright** | Browser QA / E2E gate |
| **sequential-thinking** | Deep multi-step reasoning at L3 escalation |
| **claude-flow** | Ruflo engine: memory recall, swarm, hooks (added directly by the installer) |

With the `claude` CLI present, the installer registers claude-flow and tells you
the rest ship with the ECC plugin:

```bash
claude mcp add claude-flow -- npx -y ruflo@latest mcp start
claude mcp list    # verify everything is registered
```

**MANUAL fallback** (Step 2 without the installer, or without the ECC plugin) —
these are the exact commands `install.sh` prints when `claude` is absent:

```bash
claude mcp add claude-flow -- npx -y ruflo@latest mcp start
claude mcp add context7 -- npx -y @upstash/context7-mcp
claude mcp add github -- npx -y @modelcontextprotocol/server-github
claude mcp add memory -- npx -y @modelcontextprotocol/server-memory
claude mcp add playwright -- npx -y @playwright/mcp --extension
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
# exa is an HTTP server:
claude mcp add --transport http exa https://mcp.exa.ai/mcp
```

> Everything MCP-related degrades gracefully: if a server isn't registered, the
> RETRIEVE/reasoning step that would use it becomes a no-op and the workflow
> falls back to plain inspection (see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)).

---

## 4. Run the installer

From the kit repo root:

```bash
git clone <this-repo> agentic-workflow-kit && cd agentic-workflow-kit
bash install/install.sh
```

The installer is **idempotent, non-destructive, and graceful** — safe to re-run,
backs up `settings.json` before merging, and degrades (prints MANUAL steps) when
`claude`/`rtk` are absent. Here is exactly what each step does, with its manual
equivalent:

| Step | What it does | MANUAL fallback |
|------|--------------|-----------------|
| **0 — Prerequisites** | Verify git + Node ≥ 20 (hard); warn on missing npx/pnpm/claude | Install Node 20+, git, npm/pnpm yourself |
| **1 — Enable plugins** | Back up `settings.json` → `.bak`; merge the 5 plugin keys into `enabledPlugins` (non-destructive) | Edit `~/.claude/settings.json`, add keys under `enabledPlugins` (see §2) |
| **2 — MCP servers** | `claude mcp add claude-flow …`; note that context7/github/exa/memory/playwright/sequential-thinking ship with ECC | Run each `claude mcp add …` by hand (see §3) |
| **3 — RTK** | Detect optional `rtk`; preserve its PreToolUse hook | Install rtk per its README; it self-wires its hook |
| **4 — Global rules** | `cp rules/*.md ~/.claude/rules/ecc/common/` so they auto-load in every session | `cp rules/*.md ~/.claude/rules/ecc/common/` |
| **5 — Commands + hooks** | Copy `/nerve` + `/agentic-init` commands and the nerve/guardrail hooks; `chmod +x` the hooks | `cp claude/commands/* ~/.claude/commands/ ; cp claude/hooks/* ~/.claude/hooks/ ; chmod +x ~/.claude/hooks/*.sh` |
| **6 — Hook wiring** | Merge `claude/settings.snippet.json` (SessionStart/PostToolUse/Stop hooks + permissions) into `settings.json` **additively**, preserving the existing PreToolUse (rtk) + project `guardrail.sh` | Hand-merge `claude/settings.snippet.json` into `~/.claude/settings.json` |
| **7 — Templates + runbooks** | `cp -R templates ~/.agentic-workflows/`; copy `agentic-workflows/*` runbooks; copy `docs/ADOPTION-GUIDE.md` → `~/.agentic-workflows/` | `cp -R templates ~/.agentic-workflows/ ; cp agentic-workflows/* ~/.agentic-workflows/` |
| **8 — Verify** | Run `install/verify.sh` (the doctor) | `bash install/verify.sh` |

> **Step 7 detail.** The installer copies `docs/ADOPTION-GUIDE.md` into
> `~/.agentic-workflows/` so the portable engine can read it without the kit repo
> checked out. That is why the adoption guide is written to be self-contained.

When it finishes you'll see:

```
==> Done
    Next: open any project and run  /agentic-init  then  /nerve "<task>"
```

---

## 5. Verify the install

```bash
bash install/verify.sh
```

`verify.sh` is the doctor — Step 8 runs it automatically, but you can re-run it
any time. It confirms the rules landed in `~/.claude/rules/ecc/common/`, the
commands + hooks are present and executable, the plugin keys and hook wiring are
in `settings.json`, and the templates/runbooks are in `~/.agentic-workflows/`.
Warnings (not errors) are expected for optional pieces you skipped (no `claude`,
no `rtk`, an MCP server you didn't register). See
[TROUBLESHOOTING.md](TROUBLESHOOTING.md) for reading the doctor output.

---

## 6. RTK (optional token-saver)

RTK is an optional CLI proxy that transparently rewrites common dev commands to
save 60–90% of the tokens they'd otherwise cost, via a **PreToolUse** hook. The
installer (Step 3) only **detects** it — it never installs it for you — and Step
6's merge **preserves** its hook if present.

- If `rtk` is on your PATH, you'll see `✔ rtk present (…)` and a note that its
  `rtk hook claude` PreToolUse hook is preserved by the settings merge.
- If not, you'll see a warning that it's optional. Install it per its own README,
  after which it self-wires its PreToolUse hook. Nothing else in the kit depends
  on RTK.

---

## 7. Model-agnostic / Codex / npx-only path

The kit is **model-agnostic**: the Claude slash-commands (`/nerve`,
`/agentic-init`) are thin frontends over portable runbooks. If you run Codex,
another harness, or plain scripts, you use the same workflow through the runbooks
and the `npx` engine — no Claude-only tools required.

1. **Still run `install.sh`.** Steps 4–7 (rules, runbooks, templates) are
   harness-independent and land in `~/.claude` + `~/.agentic-workflows`. The
   `claude`-specific steps (1–2) just print MANUAL notes when `claude` is absent
   — that's fine.
2. **Read the runbooks, not the slash-commands.** The canonical, prose specs are:
   - `~/.agentic-workflows/nerve-runbook.md` — the `/nerve` brain algorithm.
   - `~/.agentic-workflows/bootstrap-new-project.md` — the `/agentic-init`
     (new | existing | maintenance) algorithm.
   - `~/.agentic-workflows/loop-runbook.md` — the optional bounded loop control
     plane for `/nerve`.
   - `~/.agentic-workflows/ADOPTION-GUIDE.md` — the full zero→agentic guide.
3. **Codex** uses an `AGENTS.md` entry as its frontend over the same runbooks (it
   translates "`/task-work EPIC-009 1`" into concrete steps rather than pretending
   to run a Claude-only command). Copy `templates/codex/` into `.codex/` when
   bootstrapping a Codex project; it includes the loop triage and verifier adapters.
4. **Pi** (pi.dev) natively supports the same `AGENTS.md` auto-load convention
   plus Agent Skills in the identical `SKILL.md` format. Copy `templates/pi/`
   into `.pi/` (project) or `~/.pi/agent/` (global) when bootstrapping a Pi
   project; it gives explicit `/skill:nerve` and `/skill:agentic-init` entry
   points. Pi has no sub-agents, so an L2 loop's checker runs as a second,
   separate `pi` CLI session rather than an in-process verifier.
5. **npx-only.** Every engine phase has a portable CLI form
   (`npx ruflo memory …`, `npx @claude-flow/cli hooks …`) documented in
   [ARCHITECTURE.md](ARCHITECTURE.md) and the runbooks. With memory/Ruflo absent,
   all of it no-ops cleanly and the workflow runs on bash + git alone.

---

## 8. Uninstall / re-sync

- **Re-sync after editing the kit.** The kit repo is the source of truth. After
  you change a rule, command, hook, or template, just **re-run the installer** —
  it re-copies into `~/.claude` + `~/.agentic-workflows`. It's idempotent, so
  re-running is safe.
- **Restore settings.** Step 1 backs up `~/.claude/settings.json` to
  `settings.json.bak` before merging. To revert the settings merge, restore that
  backup.
- **Full uninstall** (manual; the kit ships no uninstaller): remove the kit's
  files from `~/.claude` and `~/.agentic-workflows` —
  `~/.claude/rules/ecc/common/{nervous-system,self-learning,graph-intelligence,memory-protocol,agent-routing,testing-taxonomy,docs-source-of-truth}.md`,
  `~/.claude/commands/{nerve,agentic-init}.md`,
  `~/.claude/hooks/nerve-*.sh`, and `~/.agentic-workflows/`. Then remove the
  plugin keys + nerve hook entries you added to `settings.json` (or restore
  `settings.json.bak`). Per-project adoption lives in each repo's `.agentic/`,
  `.claude/`, `/docs`, and gate scripts — delete those to de-adopt a single repo.

---

## Next

- [ADOPTION-GUIDE.md](ADOPTION-GUIDE.md) — take any project from zero to fully
  agentic (`/agentic-init` modes).
- [ARCHITECTURE.md](ARCHITECTURE.md) — how the nervous system + self-learning loop
  actually work.
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — when something doesn't load.
