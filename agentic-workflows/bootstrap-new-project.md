# Bootstrap Runbook — model-agnostic `/agentic-init` (new | existing | maintenance)

Canonical, harness-independent spec for bootstrapping a project to a fully
agentic state. The Claude `/agentic-init` command is a thin frontend over this;
Codex or a plain `npx` runner follows the same steps.

> **Graceful degradation.** Optional tooling (Ruflo, AgentDB, Graphify, MCP) is
> best-effort. The core scaffold (manifest, scripts, hooks, docs) only needs
> bash + git. Skip anything unavailable; never fail the bootstrap because an
> optional tool is missing.
>
> **Existing-project safety.** In `existing` and `maintenance` modes the change
> is **strictly additive** — only `.agentic/`, `.claude/`, `/docs`, and gate
> scripts are added or repaired. **Never modify application source code.** The
> result must be reviewable as a clean additive `git diff` before commit.

---

## Mode auto-detection

Inspect the target repo and pick the first matching row:

| Mode | Signal |
|------|--------|
| **new** | empty or near-empty repo (no source tree, only README/LICENSE/.git) |
| **existing** | has application code but **no** `.agentic/config.yml` and no `.claude/` agentic wiring |
| **maintenance** | already agentic — `.agentic/config.yml` present (a WealthMe-like repo) |

The user may force a mode explicitly: `/agentic-init new|existing|maintenance`.

Detection helpers (each: manifest value first, else auto-detect, else default):

- **package manager** — `packageManager` field in `package.json`; else lockfile
  (`pnpm-lock.yaml`→pnpm, `yarn.lock`→yarn, `bun.lockb`→bun, `package-lock.json`→npm); else `npm`.
- **monorepo tool** — `turbo.json`→turbo, `nx.json`→nx, `lerna.json`→lerna; else none.
- **integration branch** — current branch or remote HEAD; common: `develop`/`development`/`main`.
- **project type** — workspaces present → `monorepo`, else `single-app`.

---

## Mode: NEW

Goal: empty repo → full agentic scaffold + synthesized product docs → first task.

1. **Scaffold structure** from `~/.agentic-workflows/templates/`:
   copy `claude/` (commands, agents, hooks, settings snippet) and, when the
   harness is Codex, `codex/` into `.codex/`; then copy gate `scripts/` and the
   `/docs` skeletons. Substitute `{{placeholders}}` from answers/detection.
2. **Write the manifest** `.agentic/config.yml` from
   `~/.agentic-workflows/templates/agentic/config.yml`, filled with detected values
   (name, repo, type, package_manager, branches). Leave unknowns blank (auto at runtime).
3. **Product synthesis** — generate the source-of-truth `/docs` in order:
   PRD → User Stories → Acceptance Criteria → Engineering Tasks → Backlog →
   `epics/README.md` (status registry) → `EPIC-000-bootstrap.md`. Keep them in the
   standardized format (see `docs-source-of-truth` rule / `DOCS-FORMAT.md`).
4. **Wire gates + hooks** — ensure `scripts/{qa,test,security-check,deploy-dev}.sh`
   are executable and the `.claude/settings.json` hooks (guardrail + nerve session
   hooks) are merged non-destructively.
5. **Seed loop control artifacts** — copy `.agentic/loop-constraints.md`,
   `docs/{LOOP,LOOP-STATE,LOOP-RUN-LOG}.md`, and
   `scripts/{loop-readiness,loop-ledger,loop-worktree}.sh`. Keep `loop.enabled: false` until
   a human has selected a pattern, budget, and cadence and readiness passes.
6. **Kick off** — run the first unit of work: `/nerve "<first task>"` or
   `/task-work EPIC-000 1`.

## Mode: EXISTING (non-destructive layering)

Goal: real codebase → agentic scaffold layered on top, **no app-code edits**.

1. **Detect** stack, package manager, monorepo tool, branches, and project layout
   (page patterns, source roots) using the helpers above.
2. **Write `.agentic/config.yml`** from the template, filled with detected values.
   Surface it for the user to review (do not assume tenant scoping — leave
   `tenant.scope_fields: []` unless multi-tenant evidence is found).
3. **Drop generic tooling** — copy gate `scripts/`, `.claude/hooks/` (guardrail +
   nerve), `.claude/agents/`, `.claude/commands/`, and the applicable
   `templates/codex/` adapter into `.codex/` or `templates/pi/` adapter into
   `.pi/`; merge `settings.json` non-destructively. Do not overwrite anything
   the project already customized.
4. **Reverse-engineer initial `/docs`** — seed PRD / epics / backlog **from the
   actual code** (modules, routes, domains found), in the standard format, marked
   as drafts for human review. These describe what exists; they don't change it.
5. **Add disabled loop artifacts** — add the loop templates and readiness/ledger/worktree
   scripts, but do not schedule a job or enable the loop. The human decides whether
   the first rollout is L1 daily triage or no loop at all.
6. **Verify additive** — `git diff` must show only `.agentic/`, `.claude/`,
   `/docs/`, and `scripts/` additions. Stop and report if anything else changed.

## Mode: MAINTENANCE

Goal: an already-agentic repo → synced to the latest kit + repaired.

1. **Sync kit** — refresh generic scripts/hooks/agents/commands to the kit's
   current versions, preserving project-specific customizations (manifest values,
   custom agents, filled docs).
2. **Fill missing artifacts** — add any standard doc that's absent (e.g.
   `DEFINITION-OF-DONE.md`, `ACCEPTANCE-CRITERIA.md`), add missing manifest keys
   with sane defaults. Add disabled loop artifacts if absent; do not silently
   enable or reschedule an existing loop.
3. **Normalize epic statuses** — reconcile `docs/epics/*` against the canonical
   lifecycle (`backlog → on-progress → … → done | blocked`) and the registry in
   `epics/README.md`.
4. **Run hygiene** — execute the gates to confirm nothing regressed; report drift.

---

## After any mode

- Run `bash install/verify.sh` (or the project's verify) to confirm wiring.
- Append a one-line note to the active epic `Automation Log` recording what the
  bootstrap did (durability rule).
- Never commit secrets, never force-push, never deploy production.
