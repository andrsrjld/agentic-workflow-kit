# Hermes Adapter

This adapter makes the Agentic Workflow Kit available in Hermes Agent through
native skill slash commands. The workflow remains model-agnostic; the commands
are thin Hermes frontends over the runbooks in `~/.agentic-workflows/`.

Install or refresh it from the repository root:

```bash
bash scripts/install-hermes-agent.sh
bash scripts/verify-hermes-agent.sh
```

The installer preserves the active Hermes provider and credentials, and sets
`model.default` to `gpt-5.6-terra`. It installs these commands:

| Command | Purpose |
| --- | --- |
| `/nerve <task>` | Classify, scope, implement, gate, and record learning. |
| `/agentic-init [mode]` | Bootstrap agentic docs and workflow wiring. |
| `/agentic-start <task>` | Shape a raw request into a PR-sized epic task. |
| `/task-work EPIC-XXX [n]` | Complete one epic task group through gates. |
| `/epic-loop [EPIC]` | Coordinate an active epic task by task. |
| `/engage <persona> <task>` | Apply a named expert persona to the workflow. |

Restart Hermes after installing. In an active session, use `/reload-skills`.
`/nerve` automatically runs L1 Sense and selects a matching expert persona.
Its first pass uses only the task and relevant repository evidence; the detailed
runbook is installed alongside the skill and is loaded only for complex work.
`/engage` is the manual persona override.
The adapter intentionally requires explicit approval before remote mutations
such as push, PR creation, deployment, publishing, or credential changes.
