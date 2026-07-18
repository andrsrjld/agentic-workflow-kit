---
name: task-work
description: Use when implementing one task group from a docs epic through scoped changes, review, security, tests, and a durable handoff.
version: 1.0.0
author: Agentic Workflow Kit
license: MIT
metadata:
  hermes:
    tags: [agentic, epic, implementation, review, testing]
    related_skills: [nerve, agentic-start, epic-loop]
---

# Task Work

Expect `<EPIC-ID> [task-number]` in the trailing text. Locate the epic and work
exactly one unchecked task group. Read its goal, evidence, scope, acceptance
criteria, test plan, agent routing, and Automation Log before editing.

Scope discovery first. Use Hermes delegation only when it materially helps; keep
subtasks read-only until the implementation plan is clear. Implement the minimal
change, then run relevant review, security, lint/typecheck/build, unit, and E2E
gates. Retry a failing implementation/gate loop at most three times.

When all applicable gates pass, update the task state and append a concise,
durable result to the epic Automation Log. On a hard block, set the appropriate
status to `blocked` with the reason, evidence, and recommended action.

Do not commit, push, create a pull request, deploy, or change a remote service
unless the user explicitly authorizes that action. Never weaken tests merely to
make the gate pass.
