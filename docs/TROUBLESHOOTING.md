# Troubleshooting

Common issues installing and running the Agentic Workflow Kit, and how to fix
them. The guiding principle: **optional tooling degrades to a no-op, it never
hard-fails a session.** Most "problems" with memory/graph/MCP are expected
graceful degradation, not errors.

> First, re-run the doctor: `bash install/verify.sh`. It reports what landed and
> what's missing. Warnings (not failures) are normal for anything optional you
> skipped.

---

## Plugins not loading (no ECC / Ruflo agents or skills)

**Symptom:** `ecc:*` / `ruflo-*` agents or skills aren't available.

1. Confirm the plugin keys are enabled in `~/.claude/settings.json`:
   ```json
   "enabledPlugins": {
     "ecc@ecc": true,
     "ruflo-core@ruflo": true,
     "ruflo-swarm@ruflo": true,
     "ruflo-rag-memory@ruflo": true,
     "ruflo-autopilot@ruflo": true
   }
   ```
   If missing, re-run `bash install/install.sh` (Step 1 merges them
   non-destructively) or add them by hand.
2. Plugins resolve from **marketplaces**. If the marketplace isn't registered,
   add it once (the installer prints this hint in Step 1):
   ```bash
   claude marketplace add affaan-m/ECC
   claude marketplace add ruvnet/ruflo
   ```
   Then `claude marketplace list` to confirm, and restart Claude Code.
3. Routing still works without plugins — discovery-first routing falls back to
   the static registry and plain tools (see [ARCHITECTURE.md](ARCHITECTURE.md)
   §5). You lose the pre-built agents, not the workflow.

---

## MCP server not connecting

**Symptom:** Context7 / GitHub / Exa / Memory / Playwright / Sequential-Thinking /
claude-flow calls don't work.

1. List what's registered: `claude mcp list`.
2. Re-add the missing one with the exact command from
   [INSTALL.md](INSTALL.md) §3, e.g.:
   ```bash
   claude mcp add claude-flow -- npx -y ruflo@latest mcp start
   claude mcp add context7 -- npx -y @upstash/context7-mcp
   claude mcp add --transport http exa https://mcp.exa.ai/mcp
   ```
3. Most MCP servers run via `npx` — confirm Node ≥ 20 and `npx` are present
   (`node --version`, `npx --version`). A first call may be slow while `npx`
   downloads the package.
4. **Expected degradation:** a missing MCP server makes its RETRIEVE/reasoning
   step a no-op — Context7 absent → read the dependency's source; Memory absent →
   read the files. The task still completes, just colder.

---

## Hooks not firing (no warm-start, no capture)

**Symptom:** sessions don't start warm; edits aren't captured to memory.

1. Confirm the hooks are installed and executable:
   ```bash
   ls -l ~/.claude/hooks/nerve-session-start.sh ~/.claude/hooks/nerve-capture.sh
   ```
   They should be `-rwxr-xr-x`. If not: re-run the installer (Step 5 `chmod +x`s
   them) or `chmod +x ~/.claude/hooks/*.sh`.
2. Confirm the wiring is in `~/.claude/settings.json` under `hooks`
   (SessionStart / PostToolUse / Stop entries). Step 6 of the installer merges
   `claude/settings.snippet.json` additively. If the merge was skipped you'll see
   a Step 6 warning that no snippet was found.
3. **The hooks no-op by design** when: `npx` is absent, Ruflo/AgentDB isn't
   installed, the engine call times out (>5s), or `memory.enabled: false` /
   `memory.warm_start: false` in the project manifest. A silent no-op is the
   intended behavior — the hooks **never** block or fail a session. So "nothing
   happened" usually means a graceful skip, not a bug.
4. To confirm warm-start *could* work, run its manual form yourself:
   ```bash
   npx ruflo memory search --query "<repo>:<branch> recent decisions" --namespace "<ns>"
   ```

---

## Memory / Ruflo absent (graceful no-op is expected)

This is **not an error**. The self-learning layer is an accelerator that can
always be switched off or simply not installed:

- With Ruflo/AgentDB absent, all four loop phases (retrieve/judge/distill/
  consolidate) no-op and the task runs through its gates on plain tools — you just
  lose the recall speed-up.
- The **durability rule** means nothing is lost: durable decisions are written to
  the epic's Automation Log in git, not only to memory.
- To deliberately disable it, set `memory.enabled: false` in
  `.agentic/config.yml` for a pure no-op everywhere.

If you *want* memory and it's missing, install the engine
(`npx -y ruflo@latest …` is what the claude-flow MCP server runs) and confirm
`npx` works.

---

## GateGuard blocking a Write / Edit / Bash

**Symptom:** the first Write/Edit to a new path, or the first Bash, is blocked by
a PreToolUse hook demanding justification.

GateGuard is intentional — it blocks the **first** action against each new target
and asks you to state four facts. To comply, briefly state:

1. the user request,
2. what the file or command produces,
3. the path it writes to,
4. why it's needed,

then **retry the identical Write/Edit/Bash**. It passes on the second attempt.
This is **per-target, one-time**. Do **not** try to disable the gate.

If a *guardrail* (not GateGuard) blocks a genuinely-reviewed exception, the
manifest provides a recovery env var: `guardrail.override_env` (default
`AGENTIC_OVERRIDE`). Setting it `=1` bypasses a guardrail block **for a reviewed
exception only** — never to push past production-deploy / force-push / destructive
-DB / secret guardrails, which are non-negotiable.

---

## settings.json merge conflicts

**Symptom:** worried the installer will clobber your existing hooks or settings.

It won't — the merge is **non-destructive by construction**:

- Step 1 copies `settings.json` → `settings.json.bak` **before** touching it.
- Plugin keys are added only if absent (no overwrite).
- Hook entries are merged **per-event and deduped by JSON identity**, so your
  existing **PreToolUse** (the `rtk` rewrite hook) and project `guardrail.sh`
  entries are preserved, and re-running adds nothing twice.
- Permissions are a string-list union.

To revert any settings change, restore `~/.claude/settings.json.bak`. If you
hand-edited `settings.json` and broke its JSON, the Node merge step will fail
loudly — fix the JSON (a stray comma/brace) and re-run.

---

## Manifest auto-detect picked wrong values

**Symptom:** wrong package manager, branch, monorepo tool, or tenancy in
`.agentic/config.yml`.

The manifest **always wins over auto-detection** — set the field explicitly and
the detection fallback is ignored:

- Wrong package manager → set `package_manager: pnpm` (etc.).
- Wrong integration branch → set `branches.integration: development`.
- Tenant checks firing on a single-tenant app → set `tenant.scope_fields: []`.
- Wrong monorepo tool → set `monorepo.tool: none` (or the right one).

See the full field table in [ADOPTION-GUIDE.md](ADOPTION-GUIDE.md#manifest-reference--agenticconfigyml).
Machine-specific overrides (that you don't want committed) go in
`.agentic/config.local.yml`, which is deep-merged on top.

---

## verify.sh warnings

`install/verify.sh` (the doctor, also run as install Step 8) reports **warnings**
for optional pieces — they don't mean the install failed:

| Warning | Meaning | Action |
|---------|---------|--------|
| `claude CLI not found` | plugin/MCP auto-registration was skipped | run the MANUAL `claude mcp add …` / marketplace commands, or ignore if running model-agnostic |
| `rtk not found` | the optional token-saver isn't installed | optional — install per its README if you want it |
| an MCP server missing | not registered | re-add it ([INSTALL.md](INSTALL.md) §3) if you need that source |
| a rule/command/hook missing | a copy step was skipped | re-run `bash install/install.sh` |

A warning is informational; only a hard **FATAL** (missing Node ≥ 20 or git)
stops the installer. If verify reports a *missing copied file* (rule, command,
hook, template), re-running the installer is the fix — it's idempotent.

---

## Still stuck?

- Re-run the installer — it's idempotent and re-syncs everything from the kit
  (the source of truth).
- Read the relevant runbook directly:
  `~/.agentic-workflows/nerve-runbook.md`,
  `~/.agentic-workflows/bootstrap-new-project.md`,
  `~/.agentic-workflows/ADOPTION-GUIDE.md`.
- See [INSTALL.md](INSTALL.md), [ADOPTION-GUIDE.md](ADOPTION-GUIDE.md),
  [ARCHITECTURE.md](ARCHITECTURE.md).
