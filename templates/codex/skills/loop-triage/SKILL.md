---
name: loop-triage
description: Read one enabled loop's state and constraints, produce a bounded report-only triage result, and update durable operational records.
---

# Loop Triage

Use for an L1 daily or issue-triage run. Read `.agentic/config.yml`, the loop
constraints, state, run log, relevant epic logs, and only the evidence required
to classify the current items.

Before doing work, stop if the loop kill-switch exists or the daily budget is
exhausted. Run `bash scripts/loop-ledger.sh preflight <item-id>` when available;
at 80% budget, reduce output to the smallest useful report. Do not edit
application source, run a fix, push, comment on external systems, create a PR,
or change any connector scope.

Produce exactly these sections:

1. **High Priority** — actionable items requiring a human decision.
2. **Watch List** — observations that need no immediate action.
3. **No action / resolved** — items to prune from state.
4. **Escalations** — ambiguity, protected paths, budget/cap blocks, or loop
   collisions, with the evidence needed for a human to decide.

Update the configured state file and append one JSON object to the run log with
`outcome: report-only`, `no-op`, `paused`, `budget-exhausted`, or `escalated`.
Copy material engineering decisions to the active epic Automation Log.
