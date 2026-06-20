# EPIC-000: Foundation & Bootstrap

status: on-progress
environment: dev
phase: 0
priority: P0
area: Infra
retries: 0
prd: ../product/PRD.md
stories: ../product/USER-STORIES.md
tasks: ../product/ENGINEERING-TASKS.md (T-001 … T-006)

<!--
A generic FIRST epic: the infra/setup work every project needs before feature
epics can run in parallel. Fill the {{placeholders}} with your stack's specifics,
then run it (`/nerve` with status: on-progress) or work one `### task group` at a
time. This is a worked starting point, not a fixed mandate — drop tasks that
don't apply to your project.
-->

## Goal

Stand up the project foundation — repo structure, shared contracts/types, local
dev infrastructure, CI, env management, and commit hygiene — so that feature work
can proceed in parallel against a single source of truth with consistent gates.

## User Stories (Developer / Platform)

- **US-PLAT-1** — As a developer, I want {{REPO_SHAPE}} with shared {{SHARED_TYPES}}, so that {{FRONTEND}} & {{BACKEND}} never drift on contracts.
- **US-PLAT-2** — As a developer, I want one-command local infra ({{INFRA_SERVICES}}), so that I can run the stack instantly.
- **US-PLAT-3** — As a developer, I want CI on every PR (lint + build + test), so that broken code can't merge.
- **US-PLAT-4** — As a developer, I want validated env loading + `.env.example`, so that misconfiguration fails fast at boot.
- **US-PLAT-5** — As a developer, I want commit hooks enforcing format/lint/conventional-commits, so that history stays clean.

## Tasks

### Repo structure & workspace config

- [ ] **T-001** {{INITIALIZE_REPO_STRUCTURE}} — base layout, workspace/build config, `.gitignore`; verify a clean build is green.

### Shared contracts / types package

- [ ] **T-002** Create the shared {{SHARED_TYPES}} package (schemas/types + build + export); confirm consumers import it without error.

### Local dev stack

- [ ] **T-003** {{LOCAL_INFRA}} (e.g. Docker Compose: {{INFRA_SERVICES}}) with healthchecks + volumes; `up`/`down`/`reset` scripts; `.env.example`.

### CI pipeline

- [ ] **T-004** CI on PR + integration branch: lint + build + test with caching; required status check before merge.

### Env management

- [ ] **T-005** `.env.example` per app + validated config loader; document required vars; boot fails fast when a required var is missing.

### Commit hooks

- [ ] **T-006** Pre-commit format/lint on staged files + conventional-commit message enforcement.

## Acceptance Criteria

**Epic-level**

- A clean install + build is green from the repo root.
- The local dev stack starts and all services report healthy.
- CI runs on every PR and must be green before merge.
- Shared types import cleanly from every consumer.
- A non-conventional commit message is rejected by the hook.

**Per-task**

- **T-001** — build green after restructure; layout matches the target.
- **T-002** — package builds and exports types; consumers don't error.
- **T-003** — all services healthy; db/infra scripts work.
- **T-004** — cache-aware pipeline runs; required status check installed.
- **T-005** — boot fails fast when a required env var is absent.
- **T-006** — non-conventional commit rejected; staged files formatted/linted.

> Each task also satisfies the cross-project `../DEFINITION-OF-DONE.md` checklist.

## Automation Log

- {{YYYY-MM-DD}} {{EVENT}} — {{RESULT}}

## Dependencies

- None (opening epic).
