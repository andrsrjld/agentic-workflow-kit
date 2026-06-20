# {{PROJECT_NAME}} — Epics

> **Canonical status registry.** This file + each `EPIC-XXX-*.md` frontmatter are
> the *live state of work* — first in the source-of-truth order (see
> `rules/docs-source-of-truth.md`). When the backlog, PRD, or tasks disagree with
> an epic, **the epic wins**. Templates live at `~/.agentic-workflows/templates/docs/epics/`.
>
> Seeds: [`../backlog.json`](../backlog.json) · [`../BACKLOG.md`](../BACKLOG.md).

## Registry

<!-- One row per epic. `Status` mirrors the `status:` frontmatter in the epic file. -->

| Epic                                          | Phase   | Focus              | Priority   | Status         |
| --------------------------------------------- | ------- | ------------------ | ---------- | -------------- |
| [EPIC-000](EPIC-000-bootstrap.md)             | Phase 0 | {{FOUNDATION}}     | P0         | {{STATUS}}     |
| [EPIC-{{NNN}}]({{EPIC_FILE}})                 | Phase {{N}} | {{FOCUS}}      | {{P0_P1_P2}} | {{STATUS}}   |

**Definition of MVP:** completion of {{MVP_EPIC_RANGE}} (e.g. EPIC-000 → EPIC-002).

## Status Lifecycle

Every epic's `status:` moves through a fixed lifecycle:

```
backlog → on-progress → coding → review → testing → deploying-dev → ready-for-qa → done
                                                                   ↘ blocked (on failure)
```

| Status          | Meaning                                                        |
| --------------- | -------------------------------------------------------------- |
| `backlog`       | Not started; **ignored by automation**.                        |
| `on-progress`   | Picked up by the loop; ready to be processed.                  |
| `coding`        | Currently implementing a task.                                 |
| `review`        | Currently in code/QA review.                                   |
| `testing`       | Running the test/quality gate.                                 |
| `deploying-dev` | Deploying to the DEV environment (never production).           |
| `ready-for-qa`  | All tasks passed gates — **human QA required** before done.    |
| `blocked`       | Failed after max `retries` — **human action required**.        |
| `done`          | Completed; **ignored by automation**.                          |

Only epics in `on-progress` (or a mid-flight phase) are picked up by the loop.
`backlog`, `done`, and `blocked` are skipped.

`environment` advances separately: `dev → staging → prod`. Automation operates on
`dev` only; `staging`/`prod` are human-triggered.

## Conventions

- **One epic = one feature/milestone.** Break it into `### task group` blocks
  (each PR-sized) inside the epic file.
- **Automation Log is the durability anchor.** Every epic carries an
  `## Automation Log`; the self-learning loop's distilled decisions are copied
  there (memory is a cache, the log is version-controlled).
- **Add a new epic** by copying [`EPIC-template.md`](EPIC-template.md), then add a
  row to the registry above.
