# Docs Format — the standardized source of truth

Every project the kit touches carries the **same** doc set, so any agent (Claude,
Codex, Pi, or a human) knows where the truth lives. This is the human guide to that
format: each artifact's purpose, the canonicity order (who wins on conflict),
cross-references, and where the skeletons live. It mirrors the
`docs-source-of-truth` rule but with fuller explanation and examples.

> **Why standardize.** Agentic workflows re-read the same documents constantly. If
> every project structured them differently, RETRIEVE and routing would break. A
> single standard means the orchestrator and the graph layer always know which
> file answers which question. Paths are declared per project in
> `.agentic/config.yml` `docs.*`, so tooling resolves them without guessing.

---

## The standard doc set

| Artifact | Purpose (one line) | Default path | Manifest key |
|----------|--------------------|--------------|--------------|
| **PRD** | *Why* — problem, goals, scope, non-goals | `docs/product/PRD.md` | `docs.prd` |
| **User Stories** | *Who needs what* — `US-{DOMAIN}-{n}`, "As a {role}, I want… so that…" | `docs/product/USER-STORIES.md` | `docs.stories` |
| **Acceptance Criteria** | *Done means* — Given/When/Then + a checklist a story must satisfy | `docs/product/ACCEPTANCE-CRITERIA.md` | `docs.acceptance` |
| **Epics** | *Units of work* — a feature broken into tasks, with status + Automation Log | `docs/epics/EPIC-XXX-*.md` | `docs.epics` |
| **Tasks** | *Engineering breakdown* — `T-XXX`, Type / Complexity / Depends / Exit | `docs/product/ENGINEERING-TASKS.md` | `docs.tasks` |
| **Backlog** | *What's next* — prioritized seed list (+ `backlog.json`) | `docs/BACKLOG.md` | `docs.backlog` |
| **Definition of Done** | *The bar* — cross-project checklist every task clears | `docs/DEFINITION-OF-DONE.md` | `docs.definition_of_done` |

---

## Each artifact

### PRD — *why*

The product requirements: the problem in the user's terms, evidence it's worth
solving, users/personas, hypothesis, success metrics, scope (MVP / post-MVP /
out-of-scope), milestones (one per epic), open questions, and risks. It states
**intent**, not implementation — decomposition lives in epics + tasks.

> Mark anything unproven explicitly, e.g.
> `Assumption — needs validation via user interviews`, so a reader can tell
> signal from guess. Tech-stack decisions in the PRD appendix should mirror
> `.agentic/config.yml`.

### User Stories — *who needs what*

IDs as `US-{DOMAIN}-{n}` with the canonical shape:

```
US-ONBOARD-1 — As a new user, I want to import my accounts so that I can see my net worth on day one.
```

Each story is small enough to own one slice of behavior and maps to acceptance
criteria.

### Acceptance Criteria — *done means*

Given/When/Then plus a checklist that makes "done" testable for a story:

```
US-ONBOARD-1
  Given a user with no linked accounts
  When they complete the import flow
  Then their net worth renders from the imported balances
  - [ ] Empty state shown before import
  - [ ] Error path: import failure shows a retry, never a blank screen
```

These are what the review/QA gate verifies, and what the Definition of Done's
"Acceptance Criteria pass" line points at.

### Epics — *units of work* (canonical live state)

A feature broken into tasks, carrying frontmatter the orchestrator reads:

```markdown
# EPIC-XXX: Title

status: on-progress
environment: dev
retries: 0

## Goal
## Tasks
## Acceptance Criteria
## Automation Log
```

**Status lifecycle:**

```
backlog → on-progress → coding → review → testing → deploying-dev → ready-for-qa → done
                                                                    ↘ blocked (on failure)
```

| Status | Meaning |
|--------|---------|
| `backlog` | Ignored by automation |
| `on-progress` | Will be processed |
| `coding` / `review` / `testing` / `deploying-dev` | Currently in that phase |
| `ready-for-qa` | All tasks passed — human QA required |
| `blocked` | Failed after max retries — human action required |
| `done` | Completed — ignored by automation |

Only epics with `status: on-progress` (or a mid-flight phase) are picked up by
the loop; `backlog`, `done`, and `blocked` are skipped.

### Tasks — *engineering breakdown*

`T-XXX` items with Type / Complexity / Depends / Exit, the concrete units a
coding agent or `/task-work` executes.

### Backlog — *what's next* (seeds only)

A prioritized intake list (`BACKLOG.md` + optional `backlog.json`). An item is
**not** live state — it becomes "real" only once promoted into an epic/task.

### Definition of Done — *the bar*

The single cross-project checklist every task clears before it counts as done.
It *wraps* per-story Acceptance Criteria (AC say *what* must be true; DoD adds the
*process* proof — gates, tests, security, docs, deploy):

- **Merged** via a reviewed PR (never force-pushed, never direct to primary).
- **Acceptance Criteria pass** — demonstrably, via test/gate/reviewer.
- **Gates green** — `gates.qa` · `gates.test` · `gates.security` all PASS.
- **Tests added/updated** — coverage does not regress.
- **Security reviewed** — no secrets; tenant scoping honored where
  `tenant.scope_fields` is non-empty; protected paths untouched.
- **Docs updated** — the epic's Automation Log + any affected doc.
- **Deployed to DEV** — via `deploy.dev_command` + smoke; **never production**
  from automation.

Single-tenant projects skip the tenant sub-item; projects with no DEV deploy skip
the deploy line — every other line still applies.

---

## Canonicity order (who wins on conflict)

When artifacts disagree, trust them in this order:

1. **Epics + `docs/epics/README.md` status registry** — **canonical**. The live
   state of work (status, tasks, Automation Log) is the truth.
2. **PRD · User Stories · Acceptance Criteria · Engineering Tasks** — the
   **intent**. They define what *should* be built; epics record what *is* being
   built.
3. **`backlog.json` / `BACKLOG.md`** — **seeds only**. A prioritized intake list,
   not live state.

```
backlog seeds ──promote──► epics + tasks ──status──► epics + README registry (canonical)
   (intake)                  (the work)               (the truth on conflict)
```

So if the backlog says one thing and an epic says another, **the epic wins**.

---

## The Automation Log (the durability anchor)

Every epic carries an **Automation Log** section. This is where the self-learning
loop's durable decisions land: **memory is a fast cache, the Automation Log is
the version-controlled record.** Append outcomes, decisions, and proof here as
work completes. If the memory store is wiped, the decisions survive in git. (See
[ARCHITECTURE.md](ARCHITECTURE.md) §2 for the loop that writes them.)

---

## Cross-references

- **PRD → Epics**: each PRD milestone names its owning epic; the epic's `status`
  is the canonical state the PRD milestone table mirrors.
- **User Stories → Acceptance Criteria**: each story has criteria; the criteria
  are what the review gate checks.
- **Acceptance Criteria → Definition of Done**: DoD's "Acceptance Criteria pass"
  line points at the per-story criteria.
- **Tasks → Epics**: tasks decompose an epic's Goal; `/task-work` runs one.
- **Backlog → Epics**: backlog seeds get promoted into epics/tasks.
- **`.agentic/config.yml` `docs.*` → every path above**: tooling resolves each
  artifact's location from the manifest, never a hardcoded path.

---

## Templates

Blank, `{{placeholder}}` versions of every artifact ship in the kit at
`templates/docs/` and are installed to `~/.agentic-workflows/templates/docs/`:
`PRD.md`, `USER-STORIES.md`, `ACCEPTANCE-CRITERIA.md`, `ENGINEERING-TASKS.md`,
`BACKLOG.md`, `DEFINITION-OF-DONE.md` (plus the epics registry + an EPIC template
+ `backlog.json` as the kit fills them out).

`/agentic-init` copies and fills these when bootstrapping:

- **new** — synthesizes the content from a brief, top-down.
- **existing** — reverse-engineers drafts from the actual code.
- **maintenance** — fills any missing artifact from the same templates.

See [ADOPTION-GUIDE.md](ADOPTION-GUIDE.md) for how each mode produces the set.

---

## See also

- [ADOPTION-GUIDE.md](ADOPTION-GUIDE.md) — how the docs get created per mode.
- [ARCHITECTURE.md](ARCHITECTURE.md) — why RETRIEVE depends on this standard.
- [TESTING.md](TESTING.md) — the Acceptance Criteria ↔ gate mapping.
