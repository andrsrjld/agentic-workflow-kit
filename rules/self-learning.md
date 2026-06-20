# Self-Learning Loop

> How the workflow gets better with every gated task instead of re-discovering the same
> context each session. A four-phase loop — **retrieve → judge → distill → consolidate** —
> wraps each task, fed by the gate verdicts you already produce.
> Model-agnostic: every phase has an MCP path (Claude) and a portable `npx` CLI path.

## Purpose

Orchestration without learning burns tokens: every session re-reads files and re-derives
the same conclusions. This rule defines a closed loop that **remembers what worked and
what failed**, recalls it on the next relevant task via HNSW vector search, and prunes
itself so it does not drown in stale entries.

It pairs with:

- [nervous-system.md](nervous-system.md) — RETRIEVE runs at the start of L2 coordination; JUDGE/DISTILL/CONSOLIDATE close each spike.
- [memory-protocol.md](memory-protocol.md) — the auto-save mechanics (hooks + CLI), namespacing, and warm-start.
- [graph-intelligence.md](graph-intelligence.md) — RETRIEVE is one query over three stores (Graphify + AgentDB + Context7).

## The Loop

```
task starts ─► RETRIEVE ─► (do the work) ─► run gates ─► JUDGE ─► DISTILL ─► CONSOLIDATE ─► next task
                  ▲                                                                    │
                  └──────────────── recall improves as memory grows ◄─────────────────┘
```

| Phase | What it does | Engine — MCP (Claude) | Engine — portable CLI |
|-------|--------------|------------------------|------------------------|
| **Retrieve** | Fetch relevant past patterns via HNSW vector recall **at task start** | `agentdb_pattern-search` · `agentdb_semantic-route` · `agentdb_hierarchical-recall` | `npx ruflo memory search --query "<q>" --namespace "<ns>"` |
| **Judge** | Score the trajectory PASS/FAIL using gate verdicts as the label | `agentdb_feedback` · `hooks_intelligence_trajectory-end` | `npx @claude-flow/cli hooks post-task --success <bool>` |
| **Distill** | Extract the minimal reusable learning (what worked / what failed / the pattern) | `agentdb_context-synthesize` | `npx ruflo memory store --namespace "<ns>" --key "<k>" --value "<v>"` |
| **Consolidate** | Merge into long-term memory, dedup, manage decay (prevent forgetting) | `agentdb_consolidate` · `agentdb_hierarchical-store` | `npx @claude-flow/cli memory store --namespace patterns` |

## Retrieve — warm the context before reasoning

Run **before** any non-trivial work (L2 entry). Recall the top-K patterns for the current
repo + branch + epic so the agent reasons from prior knowledge instead of re-reading the
repository. HNSW (Hierarchical Navigable Small World) makes this vector recall fast enough
to run on every task without a latency penalty.

```bash
# portable
npx ruflo memory search --query "tenant scoping on a list page" --namespace "myproject:EPIC-009"
```

What to recall: prior decisions for this epic, proven patterns for the task's capability
(e.g. "tenant scoping", "Next.js page port"), and known failure modes to avoid.

## Judge — turn gate verdicts into labels

You already run gates (review / security / test). Their PASS/FAIL verdicts are the
**training signal** — no separate labeling step is needed. Feed the verdict to the judge
so the loop learns which trajectories succeed.

```bash
# portable — success=true when all gates passed
npx @claude-flow/cli hooks post-task --task-id "<id>" --success true
```

**Trajectory tracking:** wrap the work with `hooks_intelligence_trajectory-start` →
`…-step` (per significant action) → `…-end` (with the verdict). The trajectory plus its
verdict is what DISTILL compresses into a reusable lesson.

## Distill — extract the minimal lesson

Compress the trajectory into the **smallest reusable learning**: the conclusion, the
evidence that supports it, the files touched, the decision made, and the proof it worked
(see the store schema in [memory-protocol.md](memory-protocol.md)). Store one focused
lesson, not a transcript.

```bash
# portable
npx ruflo memory store --namespace "myproject:EPIC-009" \
  --key "tenant-scope-list-pages" \
  --value "List queries must filter by userId+familyGroupId; verified by security gate PASS in T-0912."
```

## Consolidate — merge, dedup, prevent forgetting

DISTILL writes a fresh lesson; CONSOLIDATE folds it into long-term memory:

- **Merge & dedup** — collapse near-duplicate lessons into one canonical entry so recall stays sharp.
- **Decay** — let stale, never-recalled entries age out; recently-useful entries are reinforced. This is the *forgetting-prevention* mechanism: without consolidation the store fills with redundant noise and recall quality degrades.
- **Promote** — move broadly-useful patterns into the shared `patterns` namespace so they help across epics, not just one.

```bash
# portable — promote into the cross-epic patterns namespace
npx @claude-flow/cli memory store --namespace patterns \
  --key "tenant-scope-list-pages" --value "<canonical lesson>"
```

## Store After Each Gated Task (the rule)

**Every task that passes its gates ends with JUDGE → DISTILL → CONSOLIDATE.** This is the
single most important habit: it is what converts one-time work into reusable knowledge.
Skipping it means the next session starts cold again. A failed task is *also* worth a
distilled lesson ("this approach failed the security gate because …") — negative lessons
prevent repeated mistakes.

## Durability Rule (memory is a cache, not the record)

AgentDB/Ruflo memory is a **fast cache for recall**, not the system of record. Every
durable decision distilled into memory **must also** be copied into the tracked docs —
normally the epic's **Automation Log** (see [docs-source-of-truth.md](docs-source-of-truth.md)).
If the memory store is wiped or unavailable, the decisions still live in version control.
Memory accelerates; docs are the truth.

## Graceful Degradation

When Ruflo/AgentDB is absent, all four phases no-op cleanly (exit 0) and the task still
runs through its gates — you simply lose the recall speed-up. The durability rule means no
information is lost: decisions are in the docs regardless.
