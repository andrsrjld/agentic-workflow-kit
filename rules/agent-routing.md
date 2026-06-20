# Agent Routing (Discovery-First)

> The orchestrator **defaults to reusing pre-built agents** — ECC reviewers/resolvers and
> Ruflo families — and only falls back to custom project agents for genuinely
> project-specific behavior. Routing is discovery-driven: derive the capability, ask the
> recommender, prefer pre-built, justify any custom choice.

## Purpose

A common failure mode is hand-rolling a new agent for work a battle-tested one already
covers, or calling every installed agent "just because it exists." This rule formalizes a
**reuse-first** policy so Layer 2 coordination ([nervous-system.md](nervous-system.md))
picks the smallest useful, most-proven agent for each capability.

## The Routing Algorithm

1. **Derive the capability.** Reduce the task to one capability: *review · build-fix · security · architecture · research · coding · testing · memory*.
2. **Ask the recommender.** Let the engine suggest an agent for that capability:
   - MCP: `mcp__claude-flow__guidance_recommend` · `guidance_discover` · `hooks_route`
   - CLI: `npx @claude-flow/cli hooks route --task "<description>"`
   - Fallback: the static registry below.
3. **Prefer pre-built.** Choose an ECC or Ruflo agent (tables below) before considering anything custom.
4. **Fall back to custom only for project-specific behavior** — tenant scoping, repo conventions, project gate scripts. A custom choice must be *justified* by a project-specific need, not by convenience.

## Capability → Agent Registry

Static fallback when the recommender is unavailable. Prefer the pre-built column.

| Capability | Pre-built (prefer) | Custom (only if project-specific) |
|------------|--------------------|-----------------------------------|
| **Review — React/TSX** | `ecc:react-reviewer` | project QA agent (conventions, acceptance criteria) |
| **Review — TypeScript** | `ecc:typescript-reviewer` | — |
| **Review — security** | `ecc:security-reviewer` | project security agent (tenant scoping, repo guardrails) |
| **Review — database/SQL** | `ecc:database-reviewer` | — |
| **Build-fix — React/Next** | `ecc:react-build-resolver` | — |
| **Build-fix — TS/compile** | `ecc:build-error-resolver` | — |
| **Architecture / design** | `ecc:architect` · `ruflo-swarm:architect` | — |
| **Research / discovery** | `ruflo-core:researcher` | — |
| **Coding / implementation** | `ruflo-core:coder` | project code agent (conventions-aware) |
| **Code review (general)** | `ruflo-core:reviewer` · `ecc:code-reviewer` | — |
| **Memory / recall** | `ruflo-rag-memory:memory-specialist` | — |
| **Swarm coordination** | `ruflo-swarm:coordinator` | project epic orchestrator |
| **Testing / TDD** | `ecc:tdd-guide` · `ecc:e2e-runner` | project test-runner agent (repo scripts) |

## Pre-Built Families

- **ECC reviewers** — `ecc:react-reviewer`, `ecc:typescript-reviewer`, `ecc:security-reviewer`, `ecc:database-reviewer`, plus language reviewers (`ecc:go-reviewer`, `ecc:python-reviewer`, …).
- **ECC resolvers** — `ecc:react-build-resolver`, `ecc:build-error-resolver`, and language build resolvers, for getting a broken build green.
- **Ruflo core** — `ruflo-core:coder`, `ruflo-core:researcher`, `ruflo-core:reviewer`.
- **Ruflo swarm** — `ruflo-swarm:architect`, `ruflo-swarm:coordinator`.
- **Ruflo memory** — `ruflo-rag-memory:memory-specialist`.

## Reuse Policy

Before creating or invoking a custom agent:

1. Check the ECC families for an equivalent.
2. Check the Ruflo families for an equivalent.
3. Reuse the pre-built agent if one fits.
4. Create/use a custom agent **only** when no pre-built agent covers the
   project-specific slice (tenant scoping, repo conventions, project gate scripts).

**Do not call every installed agent.** Choose the smallest useful set. Pre-built agents
cover generic expertise and gates; custom agents cover only the project-specific behavior —
the two are complementary, not redundant.

## Relationship to the Layers & Gates

- Routing happens at **L2 — Coordinate**; the recommender call is itself cheap (L1-tier).
- The orchestrator (main session) invokes the chosen agents directly; sub-agents cannot spawn sub-agents.
- Gate steps (review / security / test) should each route to their capability's pre-built reviewer first, then add the project's custom gate for project-specific checks. See [nervous-system.md](nervous-system.md) and [testing-taxonomy.md](testing-taxonomy.md).
