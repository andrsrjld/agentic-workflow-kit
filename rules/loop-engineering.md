# Loop Engineering Control Plane

> `/nerve` is the task engine. A loop is the bounded control plane that decides
> when to call it, with what state, and under which budget and human gate.

## Default posture

- Loops are opt-in through `.agentic/config.yml`; an absent or disabled `loop`
  block means ordinary `/nerve` operation.
- Start at **L1 report-only**. It may inspect, classify, update loop state, and
  create a durable report; it must not edit source, push, create a PR, deploy,
  or mutate a third-party system.
- **L2 assisted** may create one local patch in one isolated worktree per
  attempt only after the readiness script passes. A separate verifier runs the
  project gates. The human gate remains required before any remote action.
- This kit does not certify L3 unattended mutation. Never use a loop as a way
  around approval, guardrail, protected-path, or deployment rules.

## Required control artifacts

An enabled loop has all of the following:

1. `loop.constraints_file` — binding denylist, retry, and communication rules.
2. `loop.state_file` — current queue, human overrides, and last-run marker.
3. `loop.run_log` — append-only structured outcome per run.
4. Budget, max runs, max attempts, kill-switch, and explicit cadence in the
   manifest.
5. `scripts/loop-readiness.sh` passing before a scheduled or assisted run.

The durable decision still goes to the relevant epic Automation Log. Loop state
is operational context; memory is a cache; neither replaces the docs of record.

## Run contract

At the beginning of every enabled run: read constraints and state, check the
kill-switch and budget, claim exactly one bounded item, and record a unique
`run_id`. At the end: append outcome, duration, estimated tokens, action count,
and escalations to the run log; prune resolved state; copy material decisions to
the active epic log.

After three failed attempts on one root cause, stop, mark it `blocked`, and
escalate with evidence. Do not turn flaky retries into a false fix.

## Isolation and coordination

- An L2 fix attempt uses `scripts/loop-worktree.sh create <run-id>` or an
  equivalent isolated worktree. Do not run an automated fix in the primary
  checkout.
- Maker and checker are separate agents/sessions. The maker cannot declare its
  own work done.
- Only one write-capable loop may claim an item at a time. Prefer this priority
  when loops collide: CI sweeper → PR babysitter → dependency sweeper →
  post-merge/changelog → daily or issue triage.
- Connectors begin read-only. Write scopes, automatic PRs, merging, and
  notifications require a separately reviewed, explicit human decision.
