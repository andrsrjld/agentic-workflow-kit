# Docs as Source of Truth

> Every project carries the **same standardized doc set** so any agent (Claude, Codex, or
> human) knows where the truth lives. This rule defines the set, each artifact's purpose,
> which artifact wins when they disagree (**canonicity order**), and the epic status
> lifecycle. Templates live at `~/.agentic-workflows/templates/docs/`.

## Purpose

Agentic workflows re-read the same documents constantly; if every project structured them
differently, recall and routing would break. A single standard means
[graph-intelligence.md](graph-intelligence.md)'s RETRIEVE and the orchestrator always know
which file answers which question.

## The Standard Doc Set

| Artifact | Purpose (one line) | Typical path |
|----------|--------------------|--------------|
| **PRD** | *Why* — the product requirements: problem, goals, scope, non-goals | `docs/product/PRD.md` |
| **User Stories** | *Who needs what* — `US-{DOMAIN}-{n}`, "As a {role}, I want… so that…" | `docs/product/USER-STORIES.md` |
| **Acceptance Criteria** | *Done means* — Given/When/Then + checklist a story must satisfy | `docs/product/ACCEPTANCE-CRITERIA.md` |
| **Epics** | *Units of work* — a feature broken into tasks, with status + Automation Log | `docs/epics/EPIC-XXX-*.md` |
| **Tasks** | *Engineering breakdown* — `T-XXX`, Type / Complexity / Depends / Exit | `docs/product/ENGINEERING-TASKS.md` |
| **Backlog** | *What's next* — prioritized seed list of work | `docs/BACKLOG.md` (+ `backlog.json`) |
| **Definition of Done** | *The bar* — cross-project checklist every task clears before "done" | `docs/DEFINITION-OF-DONE.md` |

Paths are declared per project in the manifest `.agentic/config.yml` `docs.*` block, so
tooling resolves them without guessing.

## Canonicity Order (who wins on conflict)

When artifacts disagree, trust them in this order:

1. **Epics + `docs/epics/README.md` status registry** — *canonical*. The live state of work (status, tasks, Automation Log) is the truth.
2. **PRD · User Stories · Acceptance Criteria · Engineering Tasks** — the *intent*. They define what should be built; epics record what is being built.
3. **`backlog.json` / `BACKLOG.md`** — *seeds only*. A prioritized intake list, not the live state; an item is "real" once it becomes an epic/task.

So: backlog seeds → become epics/tasks → epics + README status are canonical. If the
backlog says one thing and an epic says another, **the epic wins**.

## Epic Frontmatter & Status Lifecycle

Each epic file opens with frontmatter the orchestrator reads:

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

Status moves through a fixed lifecycle:

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

Only epics with `status: on-progress` (or a mid-flight phase) are picked up by the loop.
`backlog`, `done`, and `blocked` are skipped by automation.

## The Automation Log (durability anchor)

Every epic carries an **Automation Log** section. This is where the self-learning loop's
durable decisions land (see [self-learning.md](self-learning.md) and
[memory-protocol.md](memory-protocol.md)): memory is a fast cache, the Automation Log is
the version-controlled record. Append outcomes, decisions, and proof here as work completes.

## Definition of Done

`DEFINITION-OF-DONE.md` is the cross-project bar every task clears:

- Acceptance Criteria pass
- Gates green (qa · test · security)
- Tests added/updated for new behavior
- Security review clean
- Docs updated (epic Automation Log + any affected doc)
- Deployed to DEV (never production from automation)

The test/QA gates and the orchestrator reference this file so "done" means the same thing
everywhere.

## Templates

Blank, `{{placeholder}}` versions of every artifact live at
`~/.agentic-workflows/templates/docs/` — PRD, USER-STORIES, ACCEPTANCE-CRITERIA,
ENGINEERING-TASKS, BACKLOG, DEFINITION-OF-DONE, `epics/README.md`, an EPIC template, and
`backlog.json`. `/agentic-init` copies and fills them when bootstrapping a project; existing
projects fill any missing artifact from the same templates.
