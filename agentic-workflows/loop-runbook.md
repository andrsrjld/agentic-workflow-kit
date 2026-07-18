# Loop Runbook — control plane for `/nerve`

This is the model-agnostic operating specification for a bounded engineering
loop. The loop does not replace `/nerve`: it selects one item, supplies durable
state and limits, then invokes `/nerve` as the task engine.

> **Safety boundary:** L1 report-only and L2 assisted are the only certified
> levels. A loop may not push, create/update a PR, merge, deploy, publish,
> change credentials, or mutate another service without explicit human approval.
> L3 unattended mutation is deliberately unsupported.

## Prerequisites

An enabled loop requires these manifest keys and files:

- `.agentic/config.yml` → `loop.*`
- `loop.constraints_file` — binding rules
- `loop.state_file` — current queue and human overrides
- `loop.run_log` — append-only JSON-line observations
- `scripts/loop-readiness.sh` — must pass before a scheduled or L2 run
- `scripts/loop-ledger.sh` — mechanically checks retry and daily-budget caps
- `scripts/loop-worktree.sh` — required for every L2 patch attempt

Run `bash scripts/loop-readiness.sh` after changing a loop's level, mode,
budget, verifier policy, or paths. Keep `loop.enabled: false` until a human has
reviewed the result and selected the host scheduler/cadence.

## Per-run algorithm

1. **Assign a run id.** Use a UTC timestamp plus pattern, e.g.
   `2026-07-13T08:00:00Z-daily-triage`.
2. **Preflight.** Read the constraints and state, then run
   `bash scripts/loop-ledger.sh preflight <item-id>`. Stop with `paused` if the
   kill-switch exists, with `budget-exhausted` if the daily budget is spent, or
   with `blocked` if the retry cap is reached; switch to report-only at 80%.
3. **Claim one item.** Select one bounded, non-ambiguous item only. If a
   write-capable loop has already claimed it, record the collision and return a
   report; do not race it.
4. **Invoke `/nerve`.** Pass the selected item, run id, current level, and any
   constraints. `/nerve` still performs classification, retrieval, routing,
   gate execution, learning, and escalation.
5. **L1 result.** Produce findings only. Update state, append the run record,
   and put human-required items in the handoff/inbox. Do not edit source.
6. **L2 result.** Before a patch, create a worktree with
   `bash scripts/loop-worktree.sh create <run-id>`. Make exactly one minimal
   attempt for the claimed root cause. A separate verifier runs the applicable
   project gates in that worktree. The result is only `verified-local` or
   `escalated`; a human decides whether to turn it into a remote action.
7. **Close the run.** Append one structured record with duration, items, action
   count, attempts, escalations, estimated tokens, and outcome; then record the
   attempt with `bash scripts/loop-ledger.sh record <run-id> <item-id> <tokens>
   <outcome>`. Prune resolved state. Copy material engineering decisions to the
   active epic Automation Log.

## Bounded failure handling

- `max_attempts_per_item` is a hard cap, normally three. Count attempts in the
  run log or local ledger before every retry.
- Ambiguous scope, protected paths, flaky tests, conflicting verifier results,
  a missing readiness artifact, or cap exhaustion are escalations—not retries.
- A verifier rejection means discard or hand off the attempt. The implementer
  cannot approve its own work.

## Patterns and safe first rollout

| Pattern | First safe level | Loop output |
| --- | --- | --- |
| Daily triage | L1 | Prioritized report and state update |
| Issue triage | L1 | Categorized issue recommendations |
| Changelog drafter | L1 | Draft only |
| Post-merge cleanup | L1 | Cleanup proposal only |
| PR babysitter | L2 | Locally verified patch proposal |
| CI sweeper | L2 | Locally verified fix proposal |
| Dependency sweeper | L2 | Patch-only, locally verified proposal |

Choose one pattern at a time. If loops overlap, use the priority defined in
`docs/LOOP.md`; only one write-capable loop may own an item.

## Codex and Claude adapters

Claude uses the installed `/nerve` command plus this runbook. Codex translates
the same procedure from `AGENTS.md` and may use the generated
`.codex/skills/loop-triage` and `.codex/agents/loop-verifier.toml` templates.
Neither adapter creates an automation, schedules a job, or expands a connector
scope by itself.
