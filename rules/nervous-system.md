# Agentic Nervous System

> The operating model for how an agentic workflow **senses, coordinates, and escalates**.
> It is a re-framing and wiring of existing infrastructure (3-tier model routing, gate
> scripts, escalation-to-human) into a single nervous-system metaphor — not a rewrite.
> Model-agnostic: works for Claude, Codex, or any harness driven through the `npx` engine.

## Purpose

Every task that enters the workflow is a **stimulus**. The nervous system decides, as
cheaply as possible, whether the stimulus can be handled by a reflex, needs multi-agent
coordination, or must escalate to a human. The goal is to spend the least capable
resource that can correctly resolve the stimulus, and to escalate fast when it cannot.

This rule defines the three layers, how a stimulus flows through them, and when to
escalate. It pairs with:

- [self-learning.md](self-learning.md) — the retrieve → judge → distill → consolidate loop that makes the system improve over time.
- [agent-routing.md](agent-routing.md) — how Layer 2 picks the right pre-built agent.

## The Three Layers

| Layer | Role | Trigger | Handlers | Model tier (Claude · portable) |
|-------|------|---------|----------|--------------------------------|
| **L1 — Sense / Reflex** | Always-on, event-driven sensing and trivial handling | Task drop, file edit, gate result, session start/end | Hooks + a cheap classifier; deterministic routing; trivial edits applied directly | Cheapest capable · Tier-1 WASM transform / Haiku · any small/fast model |
| **L2 — Coordinate** | Multi-agent orchestration over tools and skills | A stimulus L1 cannot resolve by reflex | Discovery-first routing to pre-built ECC/Ruflo agents, Context7, Graphify, AgentDB recall, swarm | Mid · Haiku/Sonnet · any mid-tier model |
| **L3 — Escalate** | Human-in-the-loop + deepest reasoning | Ambiguity, conflict, high risk, or a 3-retry block | AskUserQuestion, Sequential-Thinking MCP, deepest model, `status: blocked` → human QA | Deepest · Sonnet/Opus · most capable available model |

These layers map **directly** onto the existing **3-tier model routing**: L1 ≈ Tier 1
(cheapest capable, skip the LLM when a deterministic transform suffices), L2 ≈ Tier 2
(mid-tier orchestration), L3 ≈ Tier 3 (deepest reasoning). The layer is *not* the same as
the model — a layer chooses *which* tier to spend; a cheap L1 classifier can still decide
to escalate to an L3 model.

## Spike Processing (how a stimulus flows)

A **spike** is a single stimulus moving through the system. The path is always
*sense → classify → handle-or-escalate*, never *coordinate-first*.

```
stimulus (task / edit / gate result / session event)
   │
   ▼
[L1] sense + cheap classify ──────► trivial?  ── yes ─► handle directly (reflex), record outcome
   │                                                      └─► done
   │ no / non-trivial
   ▼
[L1→L2] RETRIEVE (graph + memory + docs)  ◄── self-learning.md, graph-intelligence.md
   │
   ▼
[L2] coordinate: route to best pre-built agent ──► run work ──► run gates
   │                                                              │
   │                            gates PASS ──────────────────────►│ JUDGE → DISTILL → CONSOLIDATE → done
   │                            gates FAIL                         │
   ▼                                                               ▼
[L2] retry (bounded) ◄──────────────────────────────────────── feed verdict back
   │
   │ ambiguous / conflicting / high-risk / 3 retries exhausted
   ▼
[L3] escalate: AskUserQuestion / Sequential-Thinking / deepest model / status: blocked
```

**Reflex examples (handled at L1, no coordination):** a one-line typo fix, a rename
covered by a deterministic transform, re-running a gate, routing a clearly-typed task to
its obvious organ (`/task-work`, `/epic-loop`). When a stimulus is unmistakably trivial,
L1 applies the edit directly with the cheapest resource and records the outcome — it does
**not** spin up agents.

**Coordination (L2)** begins only when the reflex classifier says "this needs more than a
reflex." L2 always runs RETRIEVE first (warm context from graph + memory + docs) so it
reasons from prior knowledge instead of re-reading the repo from scratch.

## Escalation Triggers (when L2 → L3)

Escalate to L3 — a human and/or the deepest model with Sequential-Thinking — when **any**
of these hold:

- **Ambiguity** — the task's intent or acceptance criteria are unclear; multiple valid interpretations exist.
- **Conflict** — gate verdicts, requirements, or two agents' conclusions disagree and cannot be reconciled by a retry.
- **High risk** — the change touches protected/foundation paths, auth, payments, data integrity, production config, or anything irreversible.
- **Retry block** — bounded retries are exhausted (default **3**); mark `status: blocked` and record reason · logs · recommended action for human QA.

Escalation is **not** failure — it is the nervous system correctly refusing to burn cycles
on something it cannot safely resolve alone. L3 always preserves the existing guardrails:
no production deploy, no force-push, no destructive DB operations, no secret exposure.

## Mapping to the 3-Tier Model Routing

| Nervous-system layer | Model tier | Spend it on |
|----------------------|-----------|-------------|
| L1 — Reflex | Tier 1 (WASM transform / cheapest model) | Deterministic edits, classification, routing, re-runs |
| L2 — Coordinate | Tier 2 (mid) | Agent orchestration, code, review, tests |
| L3 — Escalate | Tier 3 (deepest) | Architecture, security, conflict resolution, ambiguous reasoning |

**Cheapest capable first.** Start every spike at L1 and only climb a tier when the layer
below cannot resolve the stimulus correctly. Climbing tiers is driven by the escalation
triggers above, not by task size alone.

## Graceful Degradation

If the learning/graph engines (Ruflo, AgentDB, Graphify, Context7) are absent, every
RETRIEVE/JUDGE/DISTILL/CONSOLIDATE step becomes a clean no-op and the spike still flows:
L1 reflex → L2 coordinate → L3 escalate works with plain tools and human escalation alone.
The nervous system is an enhancement layer, never a hard dependency.
