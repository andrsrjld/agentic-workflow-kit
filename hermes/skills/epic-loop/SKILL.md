---
name: epic-loop
description: Use when coordinating an on-progress epic task by task with bounded verification and documented outcomes.
version: 1.0.0
author: Agentic Workflow Kit
license: MIT
metadata:
  hermes:
    tags: [agentic, epic, orchestration, verification]
    related_skills: [task-work, nerve, agentic-start]
---

# Epic Loop

Treat the trailing text as an epic path or ID. If omitted, select the first
`on-progress` epic. Read the epic, docs, project manifest, and Automation Log.
Process only one PR-sized task group at a time, dependency-first, using the
`task-work` algorithm: scope, minimal implementation, review/security/test
gates, documented result, then move to the next task only after success.

Use a maximum of three implementation-and-gate attempts per task. If unresolved,
set the epic or task to `blocked`, document the failing evidence and recommended
human decision, then stop. If all task groups are verified, set the epic to
`ready-for-qa`; a DEV deployment is allowed only with explicit user approval.

Persist decisions in the epic Automation Log. Memory and graph tools are optional
and never a reason to halt. Do not push, open PRs, deploy, force-push, or modify
external services without explicit approval.
