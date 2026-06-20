# Example — Greenfield PIV track (idea → MVP, the dead-simple way)

> A minimal worked example of the kit's **opt-in lightweight track** for *new* projects:
> set up the AI layer, write a phased PRD, then build it one phase at a time through
> **Plan → Implement → Validate** loops. This is the simple sibling of
> [new-project-walkthrough.md](new-project-walkthrough.md) (the epic/`/nerve` flow) — same
> gates, memory, and guardrails, far less ceremony.
>
> Governed by the four **golden rules** (`~/.claude/rules/ecc/common/golden-rules.md`):
> protect context · commandify everything · git = long-term memory · system-evolution.
> Authoritative spec: `~/.agentic-workflows/piv-loop-runbook.md`.
>
> Assumes the kit is installed (`install/install.sh` ran once). Running example: a
> self-hosted **link-in-bio page builder** (accounts, a customizable links page, click
> analytics).

---

## 0. Empty repo + AI layer

```bash
mkdir linkfolio && cd linkfolio && git init
```

```
/agentic-init new      # scaffolds .agentic/config.yml, .claude/, scripts/, docs/
```

`/agentic-init` drops the PIV commands (`create-prd`, `prime`, `plan-feature`, `execute`,
`commit`) into `.claude/commands/` alongside the epic commands — they share the manifest.

## 1. `/create-prd` — turn an idea into a phased PRD

Brain-dump your idea (a speech-to-text tool is great here), naming a tentative stack:

```
/create-prd "A self-hosted Linktree. Users sign up, build a links page, reorder links,
see click analytics, customize the theme. Thinking Next.js + a Postgres/Drizzle stack,
deploy to Vercel. Spin up research sub-agents for the stack and best practices, then ask
me a bunch of questions before writing anything."
```

What happens: research sub-agents (context-isolated) investigate the stack/architecture →
the agent asks you a **flurry of clarifying questions** (`AskUserQuestion`, multiple-choice +
free-text) to strip assumptions → it writes a structured PRD to `docs/product/PRD.md` with
**MVP scope**, **out-of-scope**, directory structure, and a **Phases of Work** list, e.g.:

```
Phases of Work
  1. Foundation        — auth, schema, app shell
  2. Link management   — create/edit/reorder links, inline editor + preview
  3. Theming           — customizable page themes
  4. Analytics         — per-link click-through tracking
```

Each phase = one future PIV loop. Finish the AI layer: keep `AGENTS.md`/`CLAUDE.md` concise,
push deep guidance into `reference/` (e.g. `components.md`, `api.md`), and list every env var
in `.env.example` (set real values in `.env` — never commit secrets).

## 2. `/prime` — warm a fresh session

Start **every** session here:

```
/prime
```

It reads the PRD (esp. Phases of Work), the rules, and `git log` (long-term memory), explores
structure via an `Explore` sub-agent, and reports: project overview · current state ·
**recommended next phase** (here: *Phase 1 — Foundation*). You confirm before planning.

## 3. PLAN — `/plan-feature`

```
/plan-feature "Phase 1 — Foundation"
```

Vibe-plan the phase (sub-agents for codebase/library research, Context7 for APIs), answer its
clarifying questions, then it writes a self-contained plan to `docs/plans/foundation.md`:
**goal & success criteria · references · task list (down to files) · validation strategy**
(type-check/lint → unit → integration → the explicit E2E user journeys). Iterate until aligned —
this plan is the *only* context `/execute` will get.

## 4. IMPLEMENT — `/execute` (reset context first)

Open a **new conversation** (Golden Rule 1: context is precious) and point it at the plan:

```
/execute docs/plans/foundation.md
```

The agent implements the task list, runs migrations/servers from `.env`, then self-validates
through the manifest gates (`scripts/{qa,test,security-check}.sh`) + the plan's E2E journeys
(Playwright / Vercel agent-browser), capturing screenshots as proof. It hands back a report —
it does **not** commit.

## 5. VALIDATE (human) + `/commit`

Trust **but verify**: read the diff, spin the app up, click through it like a user. Then:

```
/commit "feat: foundation — auth + links schema + app shell"
```

A standardized conventional commit (your git history is the memory `/prime` reads next time).
Best-effort, the loop also distills the lesson into memory.

## 6. System evolution, then loop

Hit a rough edge (e.g. inconsistent styling)? Fix the **AI layer**, not just the code — have
the agent *reason* about it, then you add a `reference/styles.md` or tighten a rule so it can't
recur. Then back to **step 2** for Phase 2, Phase 3, … until the MVP is done.

```
/prime  →  /plan-feature "Phase 2 — Link management"  →  /execute …  →  /commit  →  …
```

## When to graduate

Once a solid foundation exists, move to brownfield with the epic track —
`/task-work`, `/epic-loop`, `/nerve` (see [new-project-walkthrough.md](new-project-walkthrough.md)).
Both tracks share the same manifest, gates, memory namespace, and guardrails; only the ceremony
differs.
