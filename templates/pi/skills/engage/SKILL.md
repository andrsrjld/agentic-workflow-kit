---
name: engage
description: Activate a named expert persona for the current task, then run it through the nerve algorithm with that mindset. Invoke as /skill:engage <persona> "<task>".
---

# Engage (Pi adapter)

Activate an expert persona, then execute the task with that mindset. Personas
live in `~/.agentic-workflows/expert-personas.md` — plain prose, no
architectural dependency, so this skill is a full port, not an approximation.

Usage: `/skill:engage <persona> "<task>"` — or `/skill:engage <persona>` and
ask the user what task to run it against if none is given.

## Available personas

| Persona | Best for |
|---------|----------|
| `startup-mvp` | Greenfield project, MVP from scratch |
| `codebase-audit` | Reverse-engineer & audit an unfamiliar codebase |
| `debug-production` | Root-cause a bug or production outage |
| `perf-optimize` | Performance bottlenecks, memory, scaling |
| `clean-architecture` | Refactor messy code into clean architecture |
| `backend-systems` | API, database, caching, backend infra |
| `frontend-engineer` | UI components, accessibility, responsive design |
| `tech-lead` | Pre-code planning, tradeoff analysis, architecture |
| `security-audit` | Security vulnerabilities, auth flaws, injection |
| `devops-deploy` | CI/CD, Docker/Kubernetes, monitoring, deployment |

## Algorithm

1. **Parse** the text after `/skill:engage`: first word = persona name;
   remainder = task. If only a persona name is given, ask the user directly
   what task to run it against.
2. **Load** the persona: read `~/.agentic-workflows/expert-personas.md`, find
   the section matching the persona name, print it as a visible framing
   header. This makes the active mindset explicit for the rest of the task.
3. **Adopt** the persona fully. Every response, plan, and output for the
   remainder of this task must reflect the persona's priorities, decision
   framework, and output format — not a generic assistant mode.
4. **Execute** the task as `/skill:nerve "<task>"` would — RETRIEVE → DECIDE
   TIER → IMPLEMENT (yourself; Pi has no sub-agents) → GATES → JUDGE →
   DISTILL — but with the persona mindset applied throughout every step.
5. **On completion**, note any persona-specific insights worth distilling to
   memory (`npx ruflo memory store ...`, per the nerve skill's DISTILL step).

## Guardrails

Same as `/skill:nerve`: DEV deploy only · no force-push · no destructive DB ·
no committed secrets.
