# Nerve Runbook — model-agnostic `/nerve` algorithm

This runbook is the **canonical, harness-independent specification** of the
`/nerve` brain. Any model or runner (Claude Code, Codex, Pi, a plain `npx`
script) executes these steps. The Claude `/nerve` command, a Codex `AGENTS.md`
entry, and a Pi `/skill:nerve` are thin frontends over this prose; nothing here
requires Claude-only tools.

> **Graceful degradation is mandatory.** Every memory/graph/recommendation call
> below is best-effort. If the tool, network, or `.agentic/config.yml` manifest
> is absent, skip that step and continue — never block the task. A no-op is a
> valid outcome for any optional step.

---

## Inputs

- `TASK` — the raw task/enhancement string the user dropped.
- `.agentic/config.yml` (optional) — the project manifest. Read these keys when
  present: `project.name`, `memory.*`, `gates.*`, `branches.*`, `tenant.scope_fields`,
  `protected_paths`, `conventions.*`. Fall back to auto-detection when absent.

Resolve the **memory namespace** once: `memory.namespace` if set, else
`project.name`, else the git repo basename. Resolve the **branch** via
`git rev-parse --abbrev-ref HEAD` (default `main` on error). Memory keys are
`<namespace>[:<branch>][:<epic>]`.

## Optional loop preflight

`/nerve` remains the task engine. When it is invoked by a configured loop, the
loop is its **control plane**: it supplies one bounded task, a run id, and the
operating limits; it never replaces the L1/L2/L3 algorithm below.

When `loop.enabled: true` in `.agentic/config.yml`, before triage or editing:

1. Read `loop.constraints_file`, `loop.state_file`, and the most recent entries
   in `loop.run_log`. Treat constraints as binding.
2. Exit report-only and record `outcome: paused` if `loop.kill_switch` exists.
3. Sum today's `tokens_estimate` entries in the run log. If the configured
   daily cap is reached, record `outcome: budget-exhausted` and do not make an
   edit. At 80% of the cap, switch the current run to report-only.
4. Run `bash scripts/loop-readiness.sh` when that project script exists. An
   invalid enabled configuration is an escalation, not an opportunity to guess.
5. Enforce `max_attempts_per_item` mechanically in the loop ledger/run log.
   After the limit, set the relevant task or epic to `blocked` and hand off.

The kit certifies only **L1 report-only** and **L2 assisted** loops. An L2 loop
creates one isolated worktree per fix attempt and uses a separate verifier; it
may prepare a local patch but cannot push, open a PR, merge, deploy, or mutate
third-party systems without explicit human approval. L3 unattended mutation is
out of scope for this kit.

---

## The three layers

| Layer | Role | Enters when |
|-------|------|-------------|
| **L1 — Sense / Reflex** | Classify the spike; do trivial work directly | Always, first |
| **L2 — Coordinate** | Route to a pre-built agent + MCP tools + skills | L1 can't resolve in one step |
| **L3 — Escalate** | Human + deepest model + Sequential Thinking | Ambiguity, conflict, high risk, or 3-retry block |

---

## Algorithm

### L1 — SENSE (classify the spike)

1. Classify `TASK` into one capability:
   `review · build-fix · security · architecture · research · coding · docs · memory · test · deploy`.
2. Estimate complexity/risk (trivial / standard / high). Signals: number of files,
   touches `protected_paths`, touches auth/payments/tenant data, ambiguous scope.
3. **Reflex shortcut.** If the task is a single-file, low-risk transform (rename,
   typo, comment, obvious one-liner) → do it directly with an editor, run the
   relevant gate, then jump to JUDGE. Do **not** spin up agents for trivia.

### RETRIEVE (warm the context — unified over 3 sources)

Query all available sources before reasoning; merge what returns; ignore what fails:

- **Memory (decisions/patterns)** — recall top-K relevant past learnings:
  - CLI: `npx ruflo memory search --query "<TASK>" --namespace "<namespace>"`
  - or: `npx @claude-flow/cli@latest memory search --query "<TASK>" --namespace patterns`
  - or MCP: `agentdb_pattern-search` / `agentdb_semantic-route` / `agentdb_hierarchical-recall`.
- **Graph (structure)** — if `graphify-out/graph.json` exists, query it for "which
  files relate to / where is X used". Rebuild cadence is `graphify . --update`.
- **Docs (truth)** — read the relevant `/docs` source-of-truth file(s) and the
  active epic `Automation Log` for prior decisions on this work.
- **External docs (APIs)** — for library-specific work, fetch current docs
  (Context7 MCP, or vendor docs) before implementing.

Carry the merged recall forward as a compact context block.

### DECIDE TIER

- Trivial + low-risk → already handled in L1 reflex.
- Standard → **L2**.
- High-risk / ambiguous / conflicting recall → **L3** first (clarify), then L2.

### L2 — COORDINATE (discovery-first routing)

1. **Ask for a recommendation** (best-effort): `guidance_recommend` / `hooks_route`
   (MCP) or `npx @claude-flow/cli@latest hooks route --task "<TASK>"`.
2. **Prefer pre-built agents/skills**, in this order:
   - **ECC** reviewers/resolvers for generic quality: `ecc:react-reviewer`,
     `ecc:typescript-reviewer`, `ecc:security-reviewer`, `ecc:database-reviewer`,
     `ecc:react-build-resolver`, `ecc:build-error-resolver`, etc.
   - **Ruflo** families for discovery/coordination: `ruflo-core:coder/researcher/reviewer`,
     `ruflo-swarm:architect/coordinator`, `ruflo-rag-memory:memory-specialist`.
   - **Custom project agents** ONLY for project-specific behavior (tenant scoping,
     local conventions, repo gates) — e.g. `code-agent`, `review-qa-agent`,
     `security-agent`.
3. **Or invoke an organ command** when the task is already epic/task shaped:
   `/agentic-start` (raw drop → shape), `/task-work` (one task → PR),
   `/epic-loop` (whole epic). `/nerve` orchestrates these; it does not replace them.
4. Implement the minimal, convention-following change. Respect `protected_paths`
   and `conventions.*`. Honor `tenant.scope_fields` if non-empty.

### RUN GATES

Run the gates named in `gates.*` (skip any that are absent):

```
bash <gates.qa>         # default scripts/qa.sh    — lint + static
bash <gates.test>       # default scripts/test.sh   — install + build/type-check + unit
bash <gates.security>   # default scripts/security-check.sh — secrets/env/DB/audit
```

Collect each PASS/FAIL verdict. A gate failure routes back to implementation
(max 3 retries — see Escalate).

### JUDGE (label the trajectory)

Use the gate verdicts as the success label:

- CLI: `npx @claude-flow/cli@latest hooks post-task --task-id "<id>" --success <true|false> --store-results true`
- or MCP: `agentdb_feedback` / `hooks_intelligence_trajectory-end`.

`success = (all run gates passed)`.

### DISTILL (extract the reusable learning)

Capture the minimal lesson — what the task was, what approach worked or failed,
the reusable pattern — as ONE compact record:

- CLI: `npx ruflo memory store --namespace "<namespace>" --key "<short-slug>" --value "<lesson>"`
- or MCP: `agentdb_context-synthesize`.

### CONSOLIDATE (merge into long-term memory)

Dedup + decay-manage so memory doesn't bloat or forget:

- CLI: `npx @claude-flow/cli@latest memory store --namespace patterns --key "<slug>" --value "<lesson>"`
- or MCP: `agentdb_consolidate` / `agentdb_hierarchical-store`.

**Durability rule.** Memory is a fast cache, NOT the system of record. Also append
the distilled decision to the active epic's `Automation Log` (or the relevant
tracked doc) so it survives even when memory is wiped.

### L3 — ESCALATE

Enter L3 when: scope is ambiguous, recalled decisions conflict, the change is
high-risk (auth/payments/tenant data/`protected_paths`), or gates failed 3 times.

- Ask the human a focused question (one decision at a time).
- Use deepest-model + Sequential-Thinking MCP for the reasoning.
- On a hard block after 3 retries: set the epic/task `status: blocked`, record
  `reason · logs · recommended action`, and stop. Do not loop forever.

---

## Guardrails (never bypass)

- DEV deploy only — never production from an autonomous run.
- No force-push, no destructive DB (`DROP`/`TRUNCATE`/`migrate reset --force`),
  no `rm -rf` on dangerous paths, no committed secrets/`.env`.
- These are enforced independently by the `guardrail.sh` PreToolUse hook; `/nerve`
  must not attempt to work around them.

## Quick reference (engine commands)

| Phase | Ruflo CLI | claude-flow CLI | MCP |
|-------|-----------|-----------------|-----|
| retrieve | `ruflo memory search` | `memory search` | `agentdb_pattern-search` |
| route | — | `hooks route` | `guidance_recommend` / `hooks_route` |
| judge | — | `hooks post-task --success` | `agentdb_feedback` |
| distill | `ruflo memory store` | — | `agentdb_context-synthesize` |
| consolidate | — | `memory store --namespace patterns` | `agentdb_consolidate` |
