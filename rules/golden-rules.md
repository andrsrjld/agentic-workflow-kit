# Golden Rules (Greenfield PIV Track)

> Four universal habits for working with a coding agent, plus the **AI layer** and the
> **PIV loop** they live inside. This is the kit's *dead-simple* greenfield track — a
> deliberately lightweight alternative to the epic/nervous-system path, not a replacement.
> Adapted from the "no fluff, no overengineering" agentic coding workflow; mapped onto the
> kit's existing primitives so the simple flow and the heavyweight flow share one brain.

## Purpose

The epic-driven path ([nervous-system.md](nervous-system.md), [docs-source-of-truth.md](docs-source-of-truth.md))
is the right tool for coordinated, multi-task, multi-tenant work. But for **starting a new
project from scratch**, that machinery is too much ceremony too early. This rule defines the
minimal loop that gets a greenfield project moving fast *without* abandoning the kit's
discipline — the same memory, gates, and learning, expressed simply.

It is driven by the portable spec in `~/.agentic-workflows/piv-loop-runbook.md` and surfaced
through the opt-in commands `/create-prd`, `/prime`, `/plan-feature`, `/execute`, `/commit`.

## The AI Layer

The **AI layer** is every asset in the repo that exists *to be context for the coding agent* —
distinct from the application code. Keep it small, keep it sharp:

| Asset | What it is | Lives in (kit) |
|-------|------------|----------------|
| **PRD** | *What* we're building — scope, MVP, out-of-scope, and **phases of work** | `<docs.prd>` |
| **Global rules** | *How* we always build — stack, run/test commands, conventions, structure | `AGENTS.md` / `CLAUDE.md` |
| **On-demand context** | Deep guidance loaded *only when relevant* (front-end, API, styles) | `CONVENTIONS.md` + a `reference/` folder |
| **Commands** | Reusable workflows you invoke (`/prime`, `/plan-feature`, …) | `.claude/commands/` |
| **Sub-agents** | Delegated **research only** (context isolation) | ECC/Ruflo + `Explore`/`Task` |

The AI layer is not write-once. It **evolves with the codebase** (Golden Rule 4).

## The PIV Loop

After the AI layer exists, build the PRD **one phase at a time** through *Plan → Implement →
Validate*:

```
/prime  (warm a fresh session from docs + git log)
   │
   ▼
PLAN  — vibe-plan the phase → /plan-feature → structured plan (goal · refs · tasks · validation)
   │   ▲ you are in the loop here
   ▼   │  ── context reset between plan and implement ──
IMPLEMENT — /execute <plan> in a CLEAN context; delegate all coding to the agent
   │
   ▼
VALIDATE — agent self-tests (unit → integration → E2E via the gates) + your human review
   │
   ▼
/commit  (standardized message = long-term memory) → next phase
```

This is *trust-but-verify*, not vibe-coding: the implementation is **sandwiched** by planning
and validation that a human owns. It maps onto the kit's gates
([testing-taxonomy.md](testing-taxonomy.md)) and learning loop
([self-learning.md](self-learning.md)) — `/execute` runs the manifest's qa/test/security gates;
success ends in JUDGE → DISTILL → CONSOLIDATE.

---

## Rule 1 — Context is your most precious resource

Protect the **main** session's context above all else.

- **Sub-agents for research, never for implementation.** Exploration/research agents load tens
  to hundreds of thousands of tokens but return only a summary — keep that cost *out* of the
  main context. Implementation needs the full file context in the main session; delegating it
  invites hallucination. (This is why the kit routes discovery to read-only `Explore`/Ruflo
  scouts — see [agent-routing.md](agent-routing.md), [graph-intelligence.md](graph-intelligence.md).)
- **Reset context between PLAN and IMPLEMENT.** The structured plan must carry *all* the context
  `/execute` needs, so implementation starts in a fresh, focused window.
- **Progressive disclosure.** Keep `AGENTS.md`/`CLAUDE.md` concise; push deep guidance into
  on-demand `reference/` files the agent reads only when the task touches that area.

## Rule 2 — Commandify everything

If you do something more than twice, make it a command (or skill). Commands make the workflow
**repeatable and reliable** — the same PRD shape, the same plan shape, the same commit shape,
every time. Commands are what *you* invoke (`/commit`, `/prime`); skills are context an agent
chooses to read. The kit ships the greenfield set as templates; evolve them per project.

## Rule 3 — Git history is your long-term memory

Standardize commit messages (via `/commit`) so the log reads as a coherent project history.
`/prime` reads `git log` to reconstruct *what was built recently* and *what comes next*. This is
the version-controlled twin of the AgentDB/Ruflo cache ([memory-protocol.md](memory-protocol.md)):
memory accelerates recall, **git is the durable record**.

## Rule 4 — System-evolution mindset

When you hit a bug or a misalignment, don't just fix the code — fix the **AI layer** so it can't
recur: tighten a rule, add on-demand context (e.g. a `styles.md`), or add a regression test/command.
You evolve three things in parallel — **codebase, test base, and AI layer** — and the compounding
is the whole point. This is the human-facing face of the kit's self-learning loop
([self-learning.md](self-learning.md)): every gate verdict and every bug is a lesson worth
distilling. Prefer to make AI-layer edits **small, focused, and human-reviewed** (have the agent
*reason* about the change first, then apply it yourself), while delegating *code* freely.

## Reducing assumptions (the planning meta-rule)

The single highest-leverage planning habit: **make the agent ask you questions before it builds.**
One bad line of code is one bad line; one bad line in a plan is ~100 bad lines; one bad line in a
PRD is ~1000. Every clarifying question answered removes an assumption. `/create-prd` and
`/plan-feature` both end their unstructured phase by interrogating you (use `AskUserQuestion`)
before committing anything to a structured doc.

## Relationship to the epic track

Use **this track** for greenfield: empty repo → PRD with phases → PIV per phase → MVP. Once a
solid foundation exists, graduate to the epic/`/task-work`/`/epic-loop` path for coordinated
brownfield work. Both share the same gates, memory namespace, guardrails, and docs format — only
the ceremony differs. Nothing here removes or overrides the epic flow.
