---
name: agentic-start
description: Use when a raw feature, bug, or enhancement must be shaped into a PR-sized docs-driven epic task before development.
version: 1.0.0
author: Agentic Workflow Kit
license: MIT
metadata:
  hermes:
    tags: [agentic, intake, epic, planning, routing]
    related_skills: [nerve, task-work, epic-loop]
---

# Agentic Start

Treat the trailing text as the raw task. Follow the intake portion of the
model-agnostic nerve workflow in `~/.agentic-workflows/nerve-runbook.md`.

Inspect the repository and docs read-only first. Find a matching epic or create
one PR-sized task group. Normalize it before implementation with: Goal,
Evidence, Scope, Acceptance Criteria, Test Plan, Agent Routing, and Done Signal.
Record durable findings in tracked docs, not only runtime memory.

Only begin implementation when the task is sufficiently scoped and the user has
asked to start it. Otherwise stop after the epic/task handoff is ready. For
implementation, continue through the `task-work` workflow. Keep optional Ruflo,
Graphify, MCP, and recommendation calls best-effort.

No production deployment, force-push, destructive database command, secret
exposure, push, PR creation, or other third-party mutation without explicit
user approval.
