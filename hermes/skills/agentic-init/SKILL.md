---
name: agentic-init
description: Use when bootstrapping a repository into the docs-driven agentic workflow in new, existing, or maintenance mode.
version: 1.0.0
author: Agentic Workflow Kit
license: MIT
metadata:
  hermes:
    tags: [agentic, bootstrap, docs, workflow]
    related_skills: [nerve, agentic-start]
---

# Agentic Init

Treat the trailing text as an optional mode: `new`, `existing`, or
`maintenance`. Read `~/.agentic-workflows/bootstrap-new-project.md` first; use
the repository's `agentic-workflows/bootstrap-new-project.md` only as a local
fallback.

Auto-detect the mode if omitted. In `existing` and `maintenance` mode, make only
additive workflow changes: `.agentic/`, `docs/`, Hermes skill wiring, and gate
scripts. Do not alter application behavior while bootstrapping. Preserve all
existing configuration and show the diff before declaring completion.

Create or normalize the project manifest, source-of-truth docs, PR-sized epic
format, gate scripts, and the canonical status vocabulary:
`backlog`, `on-progress`, `coding`, `review`, `testing`, `deploying-dev`,
`ready-for-qa`, `blocked`, `done`.

Optional memory, graph, and MCP setup must not block bootstrap. Never deploy,
push, modify credentials, or mutate third-party systems without explicit user
approval.
