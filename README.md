# Agentic Workflow Kit

A portable, **model-agnostic** agentic development workflow you can install once and use across
**new, existing, and maintenance** projects. It packages a three-layer "nervous system", a
continuous self-learning memory loop, graph-powered context retrieval, discovery-first agent
routing, and a standardized source-of-truth docs format — deployed from this one repo.

> This repo is the **canonical source**. An installer deploys it into `~/.claude` and
> `~/.agentic-workflows`; the per-project command `/agentic-init` then bootstraps individual
> repositories. Edit the workflow = edit this repo → re-run install.

---

## What you get

- **3-layer nervous system** — L1 *sense* (event-driven reflex), L2 *coordinate* (multi-agent
  orchestration + MCP tools + skills), L3 *escalate* (human + deepest model). See
  [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- **Continuous self-learning** — `retrieve → judge → distill → consolidate` over AgentDB/HNSW so
  agents stop re-discovering context and you save tokens across sessions.
- **Graph-powered intelligence** — unified retrieve over Graphify (structure) + AgentDB
  (decisions) + Context7 (library docs).
- **Discovery-first routing** — defaults to pre-built **ECC** + **Ruflo** agents/skills; custom
  project agents only for project-specific behavior.
- **Standardized docs** — PRD · User Stories · Acceptance Criteria · Epics · Tasks · Backlog ·
  Definition of Done, identical across every project. See [docs/DOCS-FORMAT.md](docs/DOCS-FORMAT.md).
- **Bounded loop engineering** — opt-in L1 triage and L2 assisted loops with budgets, state,
  readiness checks, isolated worktrees, verifier split, kill-switch, and mandatory human gates.
  See [docs/LOOP-ENGINEERING.md](docs/LOOP-ENGINEERING.md).
- **Two commands** — `/nerve` (the runtime brain) and `/agentic-init` (bootstrap new/existing/maintenance).
- **Model-agnostic engine** — runs on Claude Code, Codex, or any harness via the `npx` CLI engine;
  Claude slash-commands and Codex `AGENTS.md` are thin frontends.

## Quickstart (3 commands)

```bash
git clone <this-repo> agentic-workflow-kit && cd agentic-workflow-kit
bash install/install.sh        # installs plugins, MCP servers, rules, commands, hooks, templates
bash install/verify.sh         # doctor: confirms everything is wired
```

Then, in any project:

```bash
/agentic-init        # auto-detects: new | existing | maintenance, scaffolds to full agentic state
/nerve "your task"   # the centralized brain runs the task through the nervous system
```

See [docs/INSTALL.md](docs/INSTALL.md) for the full tutorial (prerequisites, ECC, Ruflo, MCP, RTK,
manual fallbacks) and [docs/ADOPTION-GUIDE.md](docs/ADOPTION-GUIDE.md) for taking any project from
zero to a fully agentic state.

## Repo layout

| Path | What |
|------|------|
| `install/` | `install.sh` (deploy) + `verify.sh` (doctor) |
| `rules/` | Global rules (auto-loaded by ECC): nervous-system, self-learning, graph-intelligence, memory-protocol, agent-routing, testing-taxonomy, docs-source-of-truth, loop-engineering |
| `claude/` | `/nerve` + `/agentic-init` commands, hooks, settings snippet |
| `templates/` | Per-project scaffolding: manifest, docs, loop controls, worktree/readiness scripts, and Claude/Codex/Pi adapters |
| `agentic-workflows/` | Portable runbooks (model-agnostic): nerve, bootstrap, and loop control-plane algorithms |
| `docs/` | Human manuals: install, adoption, architecture, loop engineering, docs format, testing, troubleshooting |
| `examples/` | Minimal worked walkthrough |
| `PROGRESS.md` | Implementation/resumability tracker |

## Status

Under active construction — see [PROGRESS.md](PROGRESS.md) for current state. This kit is the
productized form of the workflow proven on the WealthMe project (its reference implementation).

## License

Internal/MIT — usable by the team. See [LICENSE](LICENSE).
# agentic-workflow-kit
# agentic-workflow-kit
