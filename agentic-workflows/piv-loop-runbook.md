# PIV Loop Runbook (Greenfield, Model-Agnostic)

> The authoritative, harness-agnostic spec for the kit's **dead-simple greenfield track**:
> set up an AI layer, write a phased PRD, then build it one phase at a time through
> **Plan → Implement → Validate** loops. Claude slash-commands (`/create-prd`, `/prime`,
> `/plan-feature`, `/execute`, `/commit`) and Codex `AGENTS.md` steps are **thin frontends**
> over this file. The four golden rules live in `~/.claude/rules/ecc/common/golden-rules.md`.

This is the lightweight complement to `nerve-runbook.md` (the heavyweight epic/nervous-system
brain) and `bootstrap-new-project.md` (full scaffold). Use PIV for greenfield velocity; both
share the same manifest (`.agentic/config.yml`), gates, memory namespace, and guardrails.

> **Graceful degradation.** Every memory / graph / sub-agent / recommender step is best-effort.
> If `.agentic/config.yml`, Ruflo, AgentDB, Graphify, or an MCP tool is missing, skip it and
> continue on plain `bash + git`. A no-op is always acceptable.

---

## Setup — resolve the manifest once

Read `.agentic/config.yml` if present:

- **prd path** = `docs.prd` (default `docs/product/PRD.md`)
- **plans dir** = `docs.plans` (default `docs/plans`)
- **gates** = `gates.{qa,test,security}` (defaults `scripts/{qa,test,security-check}.sh`)
- **namespace** = `memory.namespace` → else `project.name` → else git repo basename
- **branch** = `git rev-parse --abbrev-ref HEAD` (default `main`)

Memory keys: `<namespace>[:<branch>][:<phase-slug>]`.

## Phase 0 — Establish the AI layer (once per project)

Before any code, create the assets that *are context for the agent*:

1. **PRD** (`/create-prd`) — start with an unstructured brain-dump (idea, tentative stack,
   architecture). Spin up **research sub-agents** for stack/architecture/best-practices.
   Then **ask the user a flurry of clarifying questions** (multiple-choice + free-text) to
   strip assumptions. Only then write the structured PRD to `<docs.prd>` with: MVP scope,
   out-of-scope, directory structure, and an explicit **Phases of Work** list — each phase is
   one future PIV loop.
2. **Global rules** — `AGENTS.md` / `CLAUDE.md` (concise: stack, run/test commands, project
   structure, conventions) + on-demand `reference/` context (front-end, API, styles) the agent
   reads only when relevant. The kit's `/agentic-init` generates these; evolve them by hand.
3. **`.env.example`** — list every env var the app needs *before* implementation, so `/execute`
   can run real migrations/servers instead of silently mock-testing. Set real values in `.env`
   (gitignored — never commit secrets).

## Phase 1 — `/prime` (warm a fresh session)

Run at the **start of every new session**, before anything else. It is read-only orientation:

1. Read the PRD, global rules, and any relevant `reference/` docs.
2. **Read `git log`** (long-term memory) to see what was built recently and infer patterns.
3. Explore the structure / core entry points — delegate breadth to a research sub-agent
   (`Explore`) to keep the main context clean.
4. Output a short **understanding report**: project overview, current state, and the
   **recommended next phase** pulled from the PRD's Phases of Work. The human validates this
   before planning.

## Phase 2 — PLAN (`/plan-feature`)

For the chosen phase only:

1. **Vibe-plan** — an unstructured conversation about *this phase's* architecture and tasks;
   use research sub-agents for codebase analysis and documentation (Context7 for library APIs).
2. **Ask clarifying questions** until assumptions are removed.
3. Write a **structured plan** to `<plans>/<phase-slug>.md` with these sections:
   - **Goal & success criteria**
   - **Context / references** (docs, files, sub-agent findings)
   - **Task list** — specific, down to files to create/update
   - **Validation strategy** — the most important section: exactly how to prove the feature
     works *before* code is written (type-check/lint → unit → integration → the explicit E2E
     user journeys). This is the kit's gate plan for the phase.
4. Iterate with the human on the plan. The plan must be **self-contained** — it becomes the
   *only* context handed to `/execute`.

## Phase 3 — IMPLEMENT (`/execute <plan>`)

**Reset context first** (Golden Rule 1) — start a clean session whose only input is the plan.

1. Delegate **all coding to the main agent** (do not sub-agent the implementation).
2. Work the task list; run DB migrations and start the app using `.env`.
3. The agent self-validates against the plan's validation strategy:
   run `gates.qa` → `gates.test` → `gates.security`, then the E2E journeys (Playwright / Vercel
   agent-browser when available). Capture artifacts (screenshots) as proof.
4. If a gate fails, fix and re-run (bounded retries, default 3). After 3 failures, stop and
   report — do not weaken tests to pass.

## Phase 4 — VALIDATE (human) + `/commit`

Trust **but verify** — the human owns the bookends:

1. **Human review** — read the diff; spin the app up and use it like a real user.
2. **`/commit`** — a standardized conventional commit (Golden Rule 3: git history = memory).
   No `Co-Authored-By` unless the project's `.claude/settings.json` enables attribution.
3. **JUDGE → DISTILL → CONSOLIDATE** (best-effort): label the trajectory with the gate
   verdict, store the lesson under `<namespace>:<phase-slug>`, promote durable lessons to
   `patterns`. The commit message is the version-controlled record.

## Phase 5 — System evolution (Golden Rule 4)

After each loop, and whenever a bug appears: improve the **AI layer**, not just the code —
tighten a rule, add on-demand context, or add a regression test/command so the issue can't
recur. Then return to Phase 1 for the next PRD phase. Repeat until the MVP is complete; then
graduate to the epic/brownfield track (`nerve-runbook.md`).

## Guardrails

DEV deploy only · no force-push · no destructive DB · no committed secrets. Enforced by the
`guardrail.sh` PreToolUse hook — do not work around it.
