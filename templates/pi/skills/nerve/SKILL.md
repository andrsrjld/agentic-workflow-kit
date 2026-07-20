---
name: nerve
description: The centralized brain for Pi — sense a task, retrieve context, do the work directly (no sub-agents in this harness), run gates, then learn from the result. Invoke as /skill:nerve <task>.
---

# Nerve (Pi adapter)

`/skill:nerve` is the front door of the agentic nervous system for Pi. It is a
**thin frontend** over the model-agnostic spec in
`~/.agentic-workflows/nerve-runbook.md` — read that runbook for the
authoritative algorithm. The task text is whatever the user typed after
`/skill:nerve`.

Pi ships without sub-agents or plan mode by design. Wherever the runbook says
"route to a pre-built agent", read it as: **do the work yourself**, using the
recommendation only as guidance — never claim to spawn an `ecc:*` or `ruflo-*`
agent, those don't exist in this harness. If a matching Pi Skill is installed
(`pi list`), invoke it with `/skill:<name>` instead of describing work you
didn't do.

> **Graceful degradation.** Every memory/graph/recommendation step is
> best-effort. If `.agentic/config.yml`, Ruflo, AgentDB, Graphify, or an
> MCP-bridge extension is missing, skip that step and continue. A no-op is
> always acceptable; never block the task on optional tooling.

## Setup

Read `.agentic/config.yml` if present. Resolve once:

- **namespace** = `memory.namespace` → else `project.name` → else git repo basename.
- **branch** = `git rev-parse --abbrev-ref HEAD` (default `main`).
- **gates** = `gates.{qa,test,security}` (defaults `scripts/{qa,test,security-check}.sh`).

Memory keys are `<namespace>[:<branch>][:<epic>]`.

### Loop preflight (only when enabled)

If `.agentic/config.yml` sets `loop.enabled: true`, read the configured loop
constraints, state, and run log before triage. Stop with a recorded `paused`
outcome if the kill-switch exists; stop at the daily budget and switch to
report-only at 80%. Run `bash scripts/loop-readiness.sh` when available.

An L1 loop may report only. An L2 loop may make one local attempt only in an
isolated worktree, verified by a **separate `pi` session** (no in-process
sub-agent exists to split maker/checker). Neither level may push, open a PR,
merge, deploy, or mutate a third-party service without explicit human approval.

## Algorithm

1. **SENSE.** Classify the task into one capability
   (`review · build-fix · security · architecture · research · coding · docs · test · deploy · memory`)
   and a complexity/risk level. If it is a trivial, low-risk, single-file transform,
   just do it directly with the edit tool, run the matching gate, and skip to step 5.

   **Persona auto-select.** After classifying, map to the default expert persona
   from `~/.agentic-workflows/expert-personas.md` and print it as a framing header:

   | Capability | Persona |
   |------------|---------|
   | coding — greenfield / MVP | `startup-mvp` |
   | review — architecture / unfamiliar codebase | `codebase-audit` |
   | build-fix / bug / debugging | `debug-production` |
   | performance / optimization | `perf-optimize` |
   | refactor / clean-up | `clean-architecture` |
   | coding — backend / API / DB | `backend-systems` |
   | coding — frontend / UI | `frontend-engineer` |
   | architecture / planning | `tech-lead` |
   | security | `security-audit` |
   | deploy / devops / infra | `devops-deploy` |

   Override with `/skill:engage <persona> "<task>"` to force a specific persona
   instead of the auto-selected one.

2. **RETRIEVE.** Warm the context from all available sources (merge what returns):
   - Memory: `npx ruflo memory search --query "<task>" --namespace "<namespace>"`.
   - Graph: query `graphify-out/graph.json` if it exists ("which files relate / where used").
   - Docs: read the relevant `/docs` source-of-truth + active epic `Automation Log`.
   - External: if an MCP-bridge extension is connected (see `~/.pi/agent/mcp.json`),
     use its docs tools (e.g. Context7) before implementing anything
     library-specific; otherwise read the dependency's source/docs directly.

3. **DECIDE TIER.** Trivial → done in step 1. Standard → step 4. High-risk,
   ambiguous, or conflicting recall → ask the user a focused question first,
   then proceed.

4. **IMPLEMENT.**
   - Ask for a recommendation (best-effort): `npx @claude-flow/cli hooks route --task "<task>"`.
   - Treat the recommendation as guidance, not a dispatch target — **do the
     implementation yourself** with the edit/bash tools. Respect
     `protected_paths`, `conventions.*`, and `tenant.scope_fields` (when non-empty).
   - If the task is already epic/task shaped, follow the project's own
     workflow doc instead of re-deriving one.

5. **RUN GATES.**
   ```
   bash <gates.qa>
   bash <gates.test>
   bash <gates.security>
   ```
   Any failure → return to step 4 (max 3 retries, then escalate).

6. **JUDGE.** `success = all run gates passed`. Label the trajectory:
   `npx @claude-flow/cli hooks post-task --task-id "<slug>" --success <true|false> --store-results true`.

7. **DISTILL.** Store the minimal reusable lesson:
   `npx ruflo memory store --namespace "<namespace>" --key "<slug>" --value "<lesson>"`.

8. **CONSOLIDATE.** Merge into long-term memory + record durably:
   `npx @claude-flow/cli memory store --namespace patterns --key "<slug>" --value "<lesson>"`,
   **and** append the decision to the active epic `Automation Log` (memory is a
   cache, docs are the system of record).

9. **ESCALATE** if blocked: after 3 gate failures set the task/epic
   `status: blocked`, record `reason · logs · recommended action`, and stop.

## Guardrails

DEV deploy only · no force-push · no destructive DB · no committed secrets.
