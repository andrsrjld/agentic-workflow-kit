# Architecture

The conceptual reference for how the Agentic Workflow Kit works: a three-layer
**nervous system**, a continuous **self-learning loop**, **graph-powered**
context retrieval, **warm-start** token-saving, and **discovery-first** routing.
This is the "why and how"; the install steps live in [INSTALL.md](INSTALL.md) and
the bootstrap flow in [ADOPTION-GUIDE.md](ADOPTION-GUIDE.md).

> **One sentence.** Every task is a *stimulus*; the nervous system spends the
> least capable resource that can correctly resolve it, learns from the gate
> verdict, and escalates to a human only when it must.

---

## 1. The three-layer nervous system

A task entering the workflow is a **stimulus**. The system decides — as cheaply
as possible — whether it can be handled by a reflex, needs coordination, or must
escalate. Each layer maps directly onto the **3-tier model routing**.

| Layer | Role | Enters when | Handlers | Model tier |
|-------|------|-------------|----------|------------|
| **L1 — Sense / Reflex** | Always-on sensing + trivial handling | Always, first | Hooks + cheap classifier; deterministic routing; trivial edits applied directly | **Tier 1** — WASM transform / cheapest model |
| **L2 — Coordinate** | Multi-agent orchestration over tools + skills | L1 can't resolve in one step | Discovery-first routing to pre-built ECC/Ruflo agents, Context7, Graphify, AgentDB recall | **Tier 2** — mid (Haiku/Sonnet) |
| **L3 — Escalate** | Human-in-the-loop + deepest reasoning | Ambiguity · conflict · high risk · 3-retry block | AskUserQuestion, Sequential-Thinking MCP, deepest model, `status: blocked` | **Tier 3** — deepest (Sonnet/Opus) |

The **layer is not the model**. A layer chooses *which tier to spend*; a cheap L1
classifier can still decide to escalate to an L3 model. **Cheapest capable
first** — start every stimulus at L1 and only climb when the layer below cannot
resolve it correctly.

### Spike processing (how a stimulus flows)

A **spike** is one stimulus moving through the system. The path is always
*sense → classify → handle-or-escalate*, never *coordinate-first*.

```
stimulus (task / edit / gate result / session event)
   │
   ▼
[L1] sense + cheap classify ─────► trivial? ── yes ─► handle directly (reflex), record outcome ─► done
   │ no / non-trivial
   ▼
[L1→L2] RETRIEVE (graph + memory + docs)        ◄── §2 self-learning, §3 graph
   │
   ▼
[L2] coordinate: route to best pre-built agent ─► run work ─► run gates
   │                                                            │
   │                          gates PASS ───────────────────────► JUDGE → DISTILL → CONSOLIDATE ─► done
   │                          gates FAIL                         │
   ▼                                                             ▼
[L2] retry (bounded, max 3) ◄──────────────────────── feed verdict back
   │
   │ ambiguous / conflicting / high-risk / 3 retries exhausted
   ▼
[L3] escalate: AskUserQuestion / Sequential-Thinking / deepest model / status: blocked
```

**Reflex examples (L1, no coordination):** a one-line typo fix, a rename covered
by a deterministic transform, re-running a gate, routing a clearly-typed task to
its obvious organ command.

**Escalation triggers (L2 → L3):** ambiguity (unclear intent), conflict
(gate/requirement/agent disagreement a retry can't fix), high risk (protected
paths, auth, payments, data integrity, production config, anything irreversible),
or a retry block (bounded retries exhausted, default 3 → `status: blocked`).
Escalation is **not failure** — it's the system correctly refusing to burn cycles
on something it can't safely resolve alone.

---

## 2. The self-learning loop (retrieve → judge → distill → consolidate)

Orchestration *without* learning burns tokens: every session re-reads files and
re-derives the same conclusions. A four-phase loop wraps each gated task and
makes the system improve over time. The training signal is **free** — your gate
verdicts (review / security / test PASS/FAIL) are the labels.

```
task starts ─► RETRIEVE ─► (do the work) ─► run gates ─► JUDGE ─► DISTILL ─► CONSOLIDATE ─► next task
                  ▲                                                                     │
                  └──────────────── recall improves as memory grows ◄──────────────────┘
```

| Phase | What it does | MCP (Claude) | Portable CLI |
|-------|--------------|--------------|--------------|
| **Retrieve** | HNSW vector recall of past patterns **at task start** | `agentdb_pattern-search` · `agentdb_semantic-route` · `agentdb_hierarchical-recall` | `npx ruflo memory search --query "<q>" --namespace "<ns>"` |
| **Judge** | Score the trajectory PASS/FAIL using the gate verdict as the label | `agentdb_feedback` · `hooks_intelligence_trajectory-end` | `npx @claude-flow/cli hooks post-task --success <bool>` |
| **Distill** | Extract the minimal reusable lesson (what worked / failed / the pattern) | `agentdb_context-synthesize` | `npx ruflo memory store --namespace "<ns>" --key "<k>" --value "<v>"` |
| **Consolidate** | Merge into long-term memory, dedup, manage decay (prevent forgetting) | `agentdb_consolidate` · `agentdb_hierarchical-store` | `npx @claude-flow/cli memory store --namespace patterns` |

- **Retrieve** runs *before* any non-trivial work (the L1→L2 boundary), so the
  agent reasons from prior knowledge instead of re-reading the repo. HNSW
  (Hierarchical Navigable Small World) makes vector recall fast enough to run on
  every task.
- **Judge** needs no separate labeling step — the gates you already run produce
  the PASS/FAIL signal.
- **Distill** stores *one* focused lesson, not a transcript.
- **Consolidate** is the **forgetting-prevention** mechanism: it merges
  near-duplicates, lets stale never-recalled entries decay, and *promotes*
  broadly-useful patterns into the shared `patterns` namespace.

**Store after every gated task.** A task that passes ends with
JUDGE → DISTILL → CONSOLIDATE; a task that *fails* is also worth a distilled
lesson ("this failed the security gate because …") so the mistake isn't repeated.

**Durability rule (memory is a cache, not the record).** Every durable decision
distilled into memory is **also** copied into the tracked docs — normally the
epic's **Automation Log**. If the store is wiped, the decisions still live in
version control. Memory accelerates; docs are the truth.

---

## 3. Graph-powered intelligence (unified retrieve over 3 sources)

RETRIEVE is **one query over three complementary stores**. Before writing code an
agent needs three kinds of context — *how the code is wired*, *what we already
decided*, and *how the library actually works* — and each store answers one.

```
            ┌──────────── RETRIEVE (one unified warm-up) ────────────┐
            │                                                        │
   ┌────────▼────────┐   ┌──────────────────┐   ┌───────────────────▼─┐
   │   Graphify      │   │     AgentDB      │   │      Context7       │
   │  (structure)    │   │  (decisions)     │   │   (external docs)   │
   │ which files     │   │ what we decided  │   │ current API         │
   │ relate / impact │   │ + proven patterns│   │ signatures          │
   │ graphify-out/   │   │ HNSW recall      │   │ resolve→query-docs  │
   │ graph.json      │   │ (the §2 loop)    │   │                     │
   └─────────────────┘   └──────────────────┘   └─────────────────────┘
   rebuild on structure   continuous (written    live — fetched on
   change:                by self-learning loop)  demand, always current
   graphify . --update
```

| Question | Source |
|----------|--------|
| "Where is `formatCurrency` used and what breaks if I change it?" | **Graphify** (structure + impact) |
| "How did we handle multi-tenant scoping last time?" | **AgentDB** (prior decision) |
| "What's the correct signature for the Next.js `generateMetadata` API?" | **Context7** (live docs) |

**Order within RETRIEVE:** AgentDB first (cheapest, may return a complete
answer) → Graphify (scopes the blast radius) → Context7 (only for the specific
library calls you're about to write). Stop early if an earlier source already
answers the question.

**Graphify rebuild cadence:** rebuild on *structure change*, not every task —
`graphify . --update` after adding/moving/deleting files, new modules, or changed
imports. The `graphify-out/` directory is gitignored (a local cache).

---

## 4. Warm-start token-saving across the 5-hour window

The single biggest token win is **recall over re-read**. A cold agent that reads
15 files to understand a feature spends thousands of tokens reconstructing
knowledge the system already has.

On **SessionStart**, the `nerve-session-start.sh` hook runs a time-boxed
(<5s) RETRIEVE for the current repo + branch + epic and injects a compact top-K
block — recent decisions, proven patterns for the task's capability, and known
failure modes. A fresh **5-hour usage window** then begins **warm**: the agent
recalls instead of re-reading dozens of files.

The hybrid auto-save that keeps memory warm:

| Hook event | Action | Loop phase |
|------------|--------|------------|
| **SessionStart** | Warm-start RETRIEVE; inject top-K context | retrieve |
| **PostToolUse** | Capture spikes (edits, gate results) to AgentDB as they happen | judge / distill (incremental) |
| **Stop / SessionEnd** | DISTILL + CONSOLIDATE the session's learnings | distill / consolidate |

These use events that **don't collide** with existing PreToolUse hooks (an `rtk`
rewrite hook or a project `guardrail.sh`) — the kit's wiring is purely additive.
The portable equivalents (`npx ruflo memory …`, `npx @claude-flow/cli …`) cover
Codex/CI/other harnesses where lifecycle hooks aren't available.

**Net effect:** fewer file reads, fewer wrong-API retries, a warm start every
window.

---

## 5. Discovery-first routing

A common failure mode is hand-rolling a new agent for work a battle-tested one
already covers, or calling every installed agent "just because it exists."
Routing is **reuse-first**:

1. **Derive the capability** — reduce the task to one of:
   *review · build-fix · security · architecture · research · coding · testing · memory*.
2. **Ask the recommender** — `mcp__claude-flow__guidance_recommend` /
   `guidance_discover` / `hooks_route` (MCP), or
   `npx @claude-flow/cli hooks route --task "<description>"` (CLI), else the
   static registry.
3. **Prefer pre-built** — choose an **ECC** reviewer/resolver or a **Ruflo**
   family agent before considering anything custom.
4. **Fall back to custom only for project-specific behavior** — tenant scoping,
   repo conventions, project gate scripts — and *justify* the custom choice.

Pre-built agents cover generic expertise and gates; custom agents cover only the
project-specific slice. They are complementary, not redundant. **Do not call
every installed agent — choose the smallest useful set.**

---

## 6. Model-agnostic by construction

Nothing above is Claude-only:

- The `/nerve` and `/agentic-init` slash-commands are **thin frontends** over the
  prose runbooks at `~/.agentic-workflows/nerve-runbook.md` and
  `bootstrap-new-project.md`.
- Every learning phase has both an **MCP path** (Claude) and a **portable CLI
  path** (`npx ruflo …`, `npx @claude-flow/cli …`).
- Codex and Pi each use an `AGENTS.md` entry as their frontend over the same
  runbooks; Pi additionally exposes `/skill:nerve` and `/skill:agentic-init`
  via its native Agent Skills format.
- Optional loops are a separate, bounded control plane over `/nerve`: their
  policy/state/budget preflight runs before task execution, and L2 adds an
  isolated maker/checker worktree flow. See [LOOP-ENGINEERING.md](LOOP-ENGINEERING.md).

---

## 7. Graceful degradation (a hard rule)

The nervous system is an **enhancement layer, never a hard dependency**. When
Ruflo / AgentDB / Graphify / Context7 / `claude` are absent:

- Every RETRIEVE / JUDGE / DISTILL / CONSOLIDATE step becomes a clean **no-op**
  (exit 0). The hooks time out / no-op silently and never block a session.
- Graphify missing → fall back to Grep/Glob. AgentDB missing → read the files.
  Context7 missing → read the dependency's source.
- `memory.enabled: false` in the manifest makes the whole layer a no-op.
- The spike still flows: **L1 reflex → L2 coordinate → L3 escalate** works with
  plain tools and human escalation alone.

The **durability rule** means no information is lost when memory degrades:
decisions live in the docs regardless.

---

## Guardrails (never bypassed by any layer)

DEV deploy only · no force-push · no destructive DB · no committed secrets. These
are enforced independently by the `guardrail.sh` PreToolUse hook (and GateGuard);
the workflow must not work around them. L3 escalation preserves them too.

---

## See also

- [INSTALL.md](INSTALL.md) — deploy the kit.
- [ADOPTION-GUIDE.md](ADOPTION-GUIDE.md) — bootstrap a project.
- [DOCS-FORMAT.md](DOCS-FORMAT.md) — the standardized doc set RETRIEVE reads.
- [TESTING.md](TESTING.md) — how gate verdicts (the JUDGE labels) are produced.
