---
description: The centralized brain — sense a task, retrieve context, route to the best pre-built agent or organ command, run gates, then learn from the result.
argument-hint: "<task>"
---

# /nerve "$ARGUMENTS"

`/nerve` is the front door of the agentic nervous system. It is a **thin frontend**
over the model-agnostic spec in `~/.agentic-workflows/nerve-runbook.md` — read that
runbook for the authoritative algorithm; this command adapts it to Claude Code.

It also operates under the global rules auto-loaded from
`~/.claude/rules/ecc/common/*.md` (nervous-system, self-learning, graph-intelligence,
memory-protocol, agent-routing, testing-taxonomy). Follow them.

> **Graceful degradation.** Every memory / graph / recommendation step is
> best-effort. If `.agentic/config.yml`, Ruflo, AgentDB, Graphify, or an MCP tool
> is missing, skip that step and continue. A no-op is always acceptable; never
> block the task on optional tooling.

---

## Setup

Read `.agentic/config.yml` if present. Resolve once:

- **namespace** = `memory.namespace` → else `project.name` → else git repo basename.
- **branch** = `git rev-parse --abbrev-ref HEAD` (default `main`).
- **gates** = `gates.{qa,test,security}` (defaults `scripts/{qa,test,security-check}.sh`).

Memory keys are `<namespace>[:<branch>][:<epic>]`.

## Algorithm

1. **L1 — SENSE.** Classify `$ARGUMENTS` into one capability
   (`review · build-fix · security · architecture · research · coding · docs · test · deploy · memory`)
   and a complexity/risk level. If it is a trivial, low-risk, single-file transform,
   just do it directly with `Edit`, run the matching gate, and skip to step 5.

2. **RETRIEVE.** Warm the context from all available sources (merge what returns):
   - Memory: `npx ruflo memory search --query "$ARGUMENTS" --namespace "<namespace>"`
     (or `agentdb_pattern-search` / `agentdb_semantic-route` MCP).
   - Graph: query `graphify-out/graph.json` if it exists ("which files relate / where used").
   - Docs: read the relevant `/docs` source-of-truth + active epic `Automation Log`.
   - External: Context7 for library/API docs before implementing anything library-specific.

3. **DECIDE TIER.** Trivial → done in step 1. Standard → **L2**. High-risk or
   ambiguous or conflicting recall → **L3** (clarify with `AskUserQuestion` +
   Sequential-Thinking MCP) first, then L2.

4. **L2 — COORDINATE (discovery-first).**
   - Ask for a recommendation: `guidance_recommend` / `hooks_route` MCP, or
     `npx @claude-flow/cli@latest hooks route --task "$ARGUMENTS"`.
   - **Prefer pre-built agents/skills:** ECC reviewers/resolvers (`ecc:react-reviewer`,
     `ecc:typescript-reviewer`, `ecc:security-reviewer`, `ecc:database-reviewer`,
     `ecc:react-build-resolver`, `ecc:build-error-resolver`), then Ruflo families
     (`ruflo-core:*`, `ruflo-swarm:*`, `ruflo-rag-memory:memory-specialist`).
   - **Custom project agents only for project-specific behavior** (tenant scoping,
     local conventions, repo gates): `code-agent`, `review-qa-agent`, `security-agent`.
   - **Or invoke an organ command** when the task is already shaped:
     `/agentic-start` (raw drop), `/task-work` (one task → PR), `/epic-loop` (whole epic).
     `/nerve` orchestrates these; it does not replace them.
   - Implement the minimal change. Respect `protected_paths`, `conventions.*`, and
     `tenant.scope_fields` (when non-empty).

5. **RUN GATES.** Run each gate that exists; collect PASS/FAIL:
   ```
   bash <gates.qa>
   bash <gates.test>
   bash <gates.security>
   ```
   Any failure → return to step 4 (max 3 retries, then escalate).

6. **JUDGE.** `success = all run gates passed`. Label the trajectory:
   `npx @claude-flow/cli@latest hooks post-task --task-id "<slug>" --success <true|false> --store-results true`
   (or `agentdb_feedback` MCP).

7. **DISTILL.** Store the minimal reusable lesson:
   `npx ruflo memory store --namespace "<namespace>" --key "<slug>" --value "<lesson>"`
   (or `agentdb_context-synthesize` MCP).

8. **CONSOLIDATE.** Merge into long-term memory + record durably:
   `npx @claude-flow/cli@latest memory store --namespace patterns --key "<slug>" --value "<lesson>"`
   (or `agentdb_consolidate` MCP), **and** append the decision to the active epic
   `Automation Log` (memory is a cache, docs are the system of record).

9. **L3 — ESCALATE** if blocked: after 3 gate failures set the task/epic
   `status: blocked`, record `reason · logs · recommended action`, and stop.

## Guardrails

DEV deploy only · no force-push · no destructive DB · no committed secrets. These
are enforced by the `guardrail.sh` PreToolUse hook — do not work around them.
