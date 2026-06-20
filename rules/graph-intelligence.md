# Graph-Powered Intelligence

> RETRIEVE is **one unified query over three complementary stores** — Graphify (code
> structure), AgentDB (decisions & patterns), and Context7 (external API docs) — run
> before reasoning so agents recall instead of re-scanning. This is the single biggest
> token-saver in the workflow.

## Purpose

Before writing code or planning, an agent needs three different kinds of context:
*how the code is wired*, *what we already decided*, and *how the library actually works*.
Re-deriving each by reading files and guessing at APIs is slow and token-hungry. This rule
defines which store answers which question and when to refresh each one.

It pairs with:

- [self-learning.md](self-learning.md) — RETRIEVE is the first phase of the learning loop; AgentDB recall is part of it.
- [nervous-system.md](nervous-system.md) — RETRIEVE runs at the L1→L2 boundary, before coordination.

## The Three Sources

| Source | Answers | Query / access | Refresh cadence |
|--------|---------|----------------|------------------|
| **Graphify** | *Structure* — "which files relate", data-flow paths, "where is X used / imported", impact of a change | Query the cached graph (`graphify-out/graph.json`) | Rebuild **after structural changes** (`graphify . --update`), not every task |
| **AgentDB** | *Decisions & patterns* — "what did we decide for EPIC-009", "proven pattern for tenant scoping", known failure modes | HNSW recall — `agentdb_*-recall` / `npx ruflo memory search` | Continuous — written by the [self-learning loop](self-learning.md) |
| **Context7** | *External docs* — current API signatures and usage for NestJS / Next.js / Prisma / shadcn / any library | `mcp__plugin_ecc_context7__*` (resolve-library-id → query-docs) | Live — fetched on demand, always current |

## Which Source for What

- **"Where is `formatCurrency` used and what breaks if I change it?"** → **Graphify** (structure + impact).
- **"How did we handle multi-tenant scoping last time?"** → **AgentDB** (prior decision).
- **"What's the correct signature for the Next.js `generateMetadata` API?"** → **Context7** (live docs).
- A typical non-trivial task touches **all three**: Graphify to locate and scope the change, AgentDB to recall the pattern and avoid past mistakes, Context7 to confirm the library API before implementing.

**Order within RETRIEVE:** AgentDB first (cheapest, recalls a possibly-complete answer) →
Graphify (scopes the blast radius) → Context7 (only for the specific library calls you are
about to write). Stop early if an earlier source already answers the question.

## Graphify Rebuild Cadence

Graphify caches a static graph of the codebase. It is worth money to query but costs time
to build, so **rebuild on structure change, not on every task**:

```bash
graphify . --update      # after adding/moving/deleting files, new modules, changed imports
```

Trigger a rebuild after: new files or modules, moved/renamed files, changed import graphs,
or a large refactor. Do **not** rebuild for a single in-file edit that changes no imports —
the cached graph is still accurate. The `graphify-out/` directory is gitignored; it is a
local cache, regenerated freely.

## Token-Saving Rationale

A cold agent that reads 15 files to understand a feature spends thousands of tokens to
reconstruct knowledge the system already has. Unified RETRIEVE replaces most of that with:

- **AgentDB recall** — the decision is returned directly; no file reading needed.
- **Graphify** — "these 3 files are involved" instead of grepping the whole tree.
- **Context7** — the correct API up front instead of trial-and-error compile loops.

The net effect is fewer file reads, fewer wrong-API retries, and a warm start across
Claude's 5-hour windows (see [memory-protocol.md](memory-protocol.md)).

## Graceful Degradation

Each source is independent and optional. If `graphify-out/` does not exist, skip Graphify
and fall back to Grep/Glob. If AgentDB/Ruflo is absent, skip recall and read the files. If
Context7 is unavailable, fall back to reading the dependency's source or docs directly.
RETRIEVE degrades to plain inspection — slower, but never broken.
