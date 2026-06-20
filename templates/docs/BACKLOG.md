# {{PROJECT_NAME}} — Roadmap & Backlog

> A prioritized **seed list** of work, grouped by phase/epic. Sits last in the
> source-of-truth order (see `rules/docs-source-of-truth.md`): the backlog is
> *seeds only*. An item is "real" once it becomes an epic/task — at which point
> `docs/epics/` is canonical and **the epic wins** on any conflict.
>
> Machine-readable mirror: [`backlog.json`](backlog.json). Status of in-flight
> work is canonical in [`epics/README.md`](epics/README.md), not here.

**Priority:** **P0** = MVP-blocking · **P1** = core product · **P2** = follow-on / integration.
**MVP** = completion of {{MVP_EPIC_RANGE}} (e.g. EPIC-000 → EPIC-002).

<!--
How to use:
- One `## Phase N · {Name}  (Epic N)` section per epic. Number phases sequentially.
- One checklist item per backlog seed: `- [ ] **P{0|1|2}** ({Area}) {description}`.
- Tick `- [x]` only once the seed has been promoted to an epic/task AND delivered;
  the epic file remains the source of truth for live status.
-->

---

## Phase 0 · {{EPIC_NAME}} _(Epic 0)_

- [ ] **P0** ({{AREA}}) {{BACKLOG_ITEM}}
- [ ] **P0** ({{AREA}}) {{BACKLOG_ITEM}}
- [ ] **P1** ({{AREA}}) {{BACKLOG_ITEM}}
- [ ] **P2** ({{AREA}}) {{BACKLOG_ITEM}}

## Phase 1 · {{EPIC_NAME}} _(Epic 1)_

- [ ] **P0** ({{AREA}}) {{BACKLOG_ITEM}}
- [ ] **P1** ({{AREA}}) {{BACKLOG_ITEM}}

## Phase {{N}} · {{EPIC_NAME}} _(Epic {{N}})_

- [ ] **P{{0_1_2}}** ({{AREA}}) {{BACKLOG_ITEM}}

<!-- Repeat one `## Phase N · {Name}  (Epic N)` block per epic/phase. -->

---

### Promotion flow

A backlog seed becomes work like this:

```
backlog seed (here / backlog.json)
   → promoted to an epic task  (docs/epics/EPIC-XXX-*.md, a ### task group)
   → epic + epics/README.md status become canonical
```

If this file and an epic disagree, **trust the epic**. Keep this list lean: prune
seeds once they are delivered or abandoned.
