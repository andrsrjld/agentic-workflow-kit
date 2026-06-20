# {{PROJECT_NAME}} — Engineering Task Breakdown

> Companion to `PRD.md` + `USER-STORIES.md`. Decomposes the epics in `docs/epics/`
> into engineering tasks. Sits 4th in the source-of-truth order (see
> `rules/docs-source-of-truth.md`): it records *intent* (what should be built),
> while `docs/epics/` records the *live state* (what is being built) and wins on conflict.
>
> Each task carries:
> - **ID** — `T-XXX` (mirror the per-task IDs used in `docs/epics/EPIC-*.md`).
> - **Type** — domain tag, e.g. `BE` / `FE` / `Infra` (use your project's tags).
> - **Cx** — complexity: `S` ≤1d · `M` 2–4d · `L` ≥1w.
> - **Depends** — task IDs (or epic IDs) that must land first; `—` if none.
> - **Exit** — the per-task exit criterion: the observable thing that proves it done.
> - **Stories** — the `US-XXX` user stories this task satisfies (optional).
>
> Group tasks under one `## EPIC-XXX — {Name}` heading per epic. Close each epic
> block with a single **Exit:** line stating the bar the whole epic must clear.

<!--
How to use:
- Add a row per PR-sized task. Keep tasks small enough that one `### task group`
  in the epic file maps to one (or a few) rows here.
- Task IDs are stable; never renumber. Mark status in the epic file, not here —
  this file is the decomposition, the epic is canonical for status.
- `Exit` is the column an agent's test/QA gate reads to decide PASS/FAIL.
-->

---

## EPIC-{{NNN}} — {{EPIC_NAME}}

| ID        | Task                                  | Type     | Cx  | Depends      | Exit                                   | Stories       |
| --------- | ------------------------------------- | -------- | --- | ------------ | -------------------------------------- | ------------- |
| T-{{NNN}} | {{TASK_DESCRIPTION}}                  | {{TYPE}} | {{S_M_L}} | {{DEPENDS}}  | {{OBSERVABLE_EXIT_CRITERION}}          | {{US_IDS}}    |
| T-{{NNN}} | {{TASK_DESCRIPTION}}                  | {{TYPE}} | {{S_M_L}} | T-{{NNN}}    | {{OBSERVABLE_EXIT_CRITERION}}          | {{US_IDS}}    |

**Exit:** {{EPIC_EXIT_CRITERION}} — the consolidated bar every task above must clear before the epic is acceptable (tie this to `docs/epics/EPIC-{{NNN}}-*.md` Acceptance Criteria).

---

<!-- Repeat one `## EPIC-XXX — {Name}` block per epic. -->

## Summary

<!-- Optional rollup so dependencies and load are visible at a glance. -->

| Epic          | Tasks      | {{TYPE_A}} | {{TYPE_B}} | {{TYPE_C}} | Heaviest dependency |
| ------------- | ---------- | ---------- | ---------- | ---------- | ------------------- |
| EPIC-{{NNN}}  | {{COUNT}}  | {{N}}      | {{N}}      | {{N}}      | {{DEPENDENCY}}      |
| **Total**     | **{{N}}**  | **{{N}}**  | **{{N}}**  | **{{N}}**  | —                   |

**Sequencing note:** {{CROSS_EPIC_DEPENDENCY_NOTE}} — call out any task that soft-depends on a later epic and how it ships if its epic lands first.
