# Loop Engineering

The Agentic Workflow Kit treats loop engineering as an optional **control
plane** around `/nerve`, not as a second orchestrator. A loop selects one item
on a cadence, restores its operational context, applies budget and safety
limits, and then invokes `/nerve` for the task-level work.

```text
scheduler / manual trigger
  -> loop policy + constraints + state + budget
  -> /nerve (classify, retrieve, route, gates, learn)
  -> verifier (L2 only)
  -> human gate
  -> durable docs + next run
```

## What is included

- `loop:` manifest block, disabled by default.
- Binding constraints, explicit kill-switch, per-item retry cap, daily run and
  token limits.
- Human-readable state plus append-only structured run log.
- A network-free readiness check and mechanical local ledger:
  `bash scripts/loop-readiness.sh`, `bash scripts/loop-ledger.sh preflight <item>`.
- Isolated local worktrees for L2: `bash scripts/loop-worktree.sh create <run-id>`.
- A maker/checker split with a Codex verifier template.
- Seven pattern names: daily triage, issue triage, CI sweeper, dependency
  sweeper, changelog drafter, post-merge cleanup, and PR babysitter.

The design is informed by the MIT-licensed
[loop-engineering](https://github.com/cobusgreyling/loop-engineering) project,
but the kit provides its own native templates and does not require its npm
packages at runtime.

## Safe rollout

1. Run `/agentic-init` or copy the loop templates. Leave `loop.enabled: false`.
2. Pick one pattern, its owner, cadence, budget, and state/log paths in
   `.agentic/config.yml`; record the decision in `docs/LOOP.md`.
3. Run `bash scripts/loop-readiness.sh`. Resolve every failure.
4. Start with L1 `report-only`, preferably daily or issue triage. Review the
   reports before expanding scope.
5. Promote a single pattern to L2 only when a separate verifier and worktree
   flow have been tested. L2 stops at the human gate with a local proposal.

The kit does **not** certify L3 unattended mutation. Enabling a loop never
authorizes remote actions: push, PR mutation, merge, deploy, publication,
credential changes, and third-party writes always require explicit approval.

## State and durability

`docs/LOOP-STATE.md` is the current operational queue, and
`docs/LOOP-RUN-LOG.md` is the observable history. `.agentic/loop.pause`, the
optional local ledger, and disposable worktrees are gitignored. A loop's
material engineering decision must still be appended to the relevant epic
Automation Log—the docs remain the system of record.

## Codex adapter

For a Codex project, copy `templates/codex/` to `.codex/`. The adapter translates
the loop contract into normal Codex actions and supplies `loop-triage` for L1
and `loop-verifier.toml` for an independent L2 checker. It never assumes that a
Claude slash command exists.
