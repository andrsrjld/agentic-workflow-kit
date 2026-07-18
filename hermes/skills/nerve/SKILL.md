---
name: nerve
description: Use when a raw task needs the agentic nervous-system workflow: scope, implement, gate, and record durable learning.
version: 1.0.0
author: Agentic Workflow Kit
license: MIT
metadata:
  hermes:
    tags: [agentic, workflow, routing, verification, docs]
    related_skills: [agentic-start, task-work, epic-loop, engage]
---

# Nerve

Treat the user's trailing text as `TASK`. Start L1 Sense immediately. Do not
read a runbook, probe optional tools, or load another skill before classifying
the task. Do not claim to run a Claude Code command.

Classify `TASK` as `review`, `build-fix`, `security`, `architecture`,
`research`, `coding`, `docs`, `memory`, `test`, or `deploy`; estimate risk as
trivial, standard, or high. For a trivial, low-risk, single-file task, make the
small change, run only the matching check, and report the result.

For standard work, retrieve only the repository files and docs directly related
to the task, then choose the smallest useful route. Use memory, Graphify, Ruflo,
MCP, or delegation only when the task is broad, ambiguous, library-specific, or
needs past context. Do not spend time checking optional tooling that will not
change the next action.

Implement minimally, then run applicable QA, test, and security gates. Record a
compact durable decision in the active epic Automation Log or another tracked
project document. For the complete algorithm, only when the task warrants it,
read `${HERMES_SKILL_DIR}/references/nerve-runbook.md`; this local reference is
installed with the skill and must be preferred over a global path.

After L1 classification, automatically select and print a concise persona
framing header. Use this mapping:

| Capability or task shape | Persona |
| --- | --- |
| greenfield or MVP coding | `startup-mvp` |
| unfamiliar-codebase or architecture review | `codebase-audit` |
| bug or debugging | `debug-production` |
| performance or optimization | `perf-optimize` |
| refactor or cleanup | `clean-architecture` |
| backend, API, database, or caching | `backend-systems` |
| frontend or UI | `frontend-engineer` |
| architecture or planning | `tech-lead` |
| security | `security-audit` |
| deploy, CI/CD, or infrastructure | `devops-deploy` |

The selected persona frames prioritization and communication; it does not
override repository instructions or safety boundaries. Load the detailed
persona only when it changes the implementation approach. The user can override
the selection at any time with `/engage <persona> <task>`.

Graceful degradation is mandatory. Ruflo, Graphify, MCP servers, and memory are
optional accelerators. If unavailable, continue with repository inspection and
docs rather than blocking.

For a raw task that needs shaping, use the `agentic-start` workflow. For an
existing epic task, use `task-work`. For a whole active epic, use `epic-loop`.

Safety rules: treat networked tools as read-only by default; never deploy to
production, force-push, run destructive database operations, expose secrets, or
commit real `.env` files. Ask for explicit approval before pushing, opening a
pull request, publishing, deploying, or changing third-party resources.
