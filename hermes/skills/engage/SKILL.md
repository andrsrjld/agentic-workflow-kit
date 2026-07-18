---
name: engage
description: Use when a task should be handled with a named expert persona while retaining the agentic workflow and safety gates.
version: 1.0.0
author: Agentic Workflow Kit
license: MIT
metadata:
  hermes:
    tags: [agentic, persona, routing]
    related_skills: [nerve]
---

# Engage

Parse the trailing text as `<persona> <task>`. Read
`~/.agentic-workflows/expert-personas.md` and load the named persona. If the
task is missing, ask one focused question.

Available personas include `startup-mvp`, `codebase-audit`,
`debug-production`, `perf-optimize`, `clean-architecture`, `backend-systems`,
`frontend-engineer`, `tech-lead`, `security-audit`, and `devops-deploy`.

Apply the selected persona's priorities while running the same model-agnostic
nerve workflow: retrieve, classify, scope, implement, verify, distill, and
record durable conclusions. Persona selection never overrides safety boundaries:
external actions, pushes, PRs, and deployments still require explicit approval.
