# Adoption Guide — zero → agentic

The master guide for taking **any** project to a fully agentic state with
`/agentic-init`. It covers all three modes (**new · existing · maintenance**),
the `.agentic/config.yml` manifest reference, the standardized doc set each mode
produces, the additive-safety guarantee for existing repos, and troubleshooting.

> **Self-contained by design.** `install.sh` Step 7 copies this file into
> `~/.agentic-workflows/` so the portable engine can read it without the kit repo
> checked out. It therefore repeats the essentials rather than only linking out.

> **What `/agentic-init` is.** A thin frontend over the model-agnostic runbook at
> `~/.agentic-workflows/bootstrap-new-project.md`. Claude runs the slash-command;
> Codex / an `npx` runner follow the same runbook steps. The core scaffold needs
> only **bash + git** — every memory/graph/MCP step is best-effort and skipped if
> the tool is absent.

---

## The three modes

`/agentic-init [new|existing|maintenance]` — if you name a mode it's used;
otherwise it auto-detects (first match wins):

| Mode | Detected when | What it does |
|------|---------------|--------------|
| **new** | empty / near-empty repo (no source tree; only README/LICENSE/.git) | Scaffold full structure + **synthesize** product docs from a brief → first task |
| **existing** | has app code but **no** `.agentic/config.yml` and no `.claude/` agentic wiring | **Additively** layer the scaffold on top + **reverse-engineer** draft docs from the code — never touch app source |
| **maintenance** | `.agentic/config.yml` already present (already agentic) | Sync to the latest kit, fill missing artifacts, normalize epic statuses, run hygiene |

Detection also resolves: **package manager** (lockfile / `packageManager`
field), **monorepo tool** (`turbo.json`/`nx.json`/`lerna.json`), **integration
branch** (current / remote HEAD), and **project type** (workspaces → monorepo,
else single-app). Every detection has a fallback, so it works on a bare repo.

---

### Mode: NEW

Goal: empty repo → full agentic scaffold + synthesized product docs → first task.

1. **Scaffold structure** from `~/.agentic-workflows/templates/`: `claude/`
   (commands, agents, hooks, settings snippet), gate `scripts/`, and the `/docs`
   skeletons — substituting `{{placeholders}}` from detection/answers.
2. **Write the manifest** `.agentic/config.yml` from the template, filled with
   detected values (name, repo, type, package_manager, branches). Unknowns left
   blank fall back to auto-detection at runtime.
3. **Product synthesis** in canonical order: PRD → User Stories → Acceptance
   Criteria → Engineering Tasks → Backlog → `epics/README.md` (status registry)
   → `EPIC-000-bootstrap.md`. All in the standardized format
   (see [DOCS-FORMAT.md](DOCS-FORMAT.md)).
4. **Wire gates + hooks** — make `scripts/{qa,test,security-check,deploy-dev}.sh`
   executable; merge `.claude/settings.json` hooks **non-destructively**
   (preserve any existing rtk / guardrail entries).
5. **Kick off** the first unit of work: `/nerve "<first task>"` or
   `/task-work EPIC-000 1`.

### Mode: EXISTING (strictly additive)

Goal: a real codebase → agentic scaffold layered on top, **with no app-code
edits**.

1. **Detect** stack, package manager, monorepo tool, branches, layout (page
   patterns, source roots).
2. **Write `.agentic/config.yml`** with detected values; surface it for your
   review. It leaves `tenant.scope_fields: []` unless multi-tenant evidence is
   found (do not assume tenancy).
3. **Drop generic tooling** — gate `scripts/`, `.claude/{hooks,agents,commands}/`
   — and merge `settings.json` non-destructively. Never overwrite a project
   customization.
4. **Reverse-engineer initial `/docs` from the actual code** (modules, routes,
   domains), in the standard format, **marked as drafts for human review**. These
   describe what exists; they do not change it.
5. **Verify additive** — the resulting `git diff` must show **only**
   `.agentic/`, `.claude/`, `/docs/`, and `scripts/` additions. If anything else
   changed, `/agentic-init` stops and reports.

> **The additive guarantee.** In `existing` (and `maintenance`) mode the change
> is reviewable as a clean additive `git diff` *before you commit*. Application
> source is never modified. This is what makes adopting the kit on a live,
> production codebase low-risk: you read the diff, and it only ever adds workflow
> scaffolding.

### Mode: MAINTENANCE

Goal: an already-agentic repo → synced to the latest kit + repaired.

1. **Sync kit** — refresh generic scripts/hooks/agents/commands to the kit's
   current versions, **preserving** project-specific customizations (manifest
   values, custom agents, filled docs).
2. **Fill missing artifacts** — add any standard doc that's absent (e.g.
   `DEFINITION-OF-DONE.md`, `ACCEPTANCE-CRITERIA.md`) and any missing manifest
   keys with sane defaults.
3. **Normalize epic statuses** — reconcile `docs/epics/*` against the canonical
   lifecycle and the `epics/README.md` registry.
4. **Run hygiene** — execute the gates to confirm nothing regressed; report drift.

### After any mode

- Run `bash install/verify.sh` (or the project's verify) to confirm wiring.
- Append a one-line note to the active epic's **Automation Log** recording what
  the bootstrap did (the durability rule — memory is a cache, the log is the
  record).
- Guardrails always hold: no production deploy, no force-push, no destructive DB,
  no committed secrets.

---

## Manifest reference — `.agentic/config.yml`

The manifest is the **single source of truth** for everything that used to be
hardcoded in scripts/hooks/agents. Generic kit tooling reads it (with
auto-detect fallbacks) so the same scripts work in every repo. It is
**git-tracked**; machine-specific overrides go in `.agentic/config.local.yml`
(gitignored, deep-merged on top). Any field left blank falls back to
auto-detection at runtime.

| Key | Meaning | Auto-detect fallback when blank |
|-----|---------|----------------------------------|
| `project.name` | Short slug; the **memory namespace root** | required — set it |
| `project.repo` | `owner/name` | `git remote get-url origin` |
| `project.type` | `single-app` \| `monorepo` | workspaces present → monorepo |
| `package_manager` | `pnpm`\|`npm`\|`yarn`\|`bun` | `packageManager` field → lockfile → `npm` |
| `monorepo.tool` | `turbo`\|`nx`\|`lerna`\|`none` | `turbo.json`→turbo, `nx.json`→nx, `lerna.json`→lerna |
| `monorepo.workspaces` | e.g. `[apps/*, packages/*]` | `package.json` workspaces / `pnpm-workspace.yaml` |
| `branches.integration` | PRs target this (`develop`/`development`/`main`) | remote HEAD → current branch → `main` |
| `branches.primary` | production-tracking branch | `main` |
| `deploy.dev_command` | e.g. `scripts/deploy-dev.sh`; **`""` disables the deploy gate** | — (disabled if blank) |
| `deploy.health_url` | smoke check, e.g. `http://localhost:4000/health` | — (smoke skipped if blank) |
| `deploy.smoke_user` | seeded login for smoke E2E | — |
| `protected_paths[]` | globs agents must not modify without a reviewed task | `[]` (none protected) |
| `conventions.page_pattern` | e.g. `src/app/(app)/[page-id]/page.tsx` | `""` (none) |
| `conventions.shared_types` | e.g. `@myproject/contracts` | `""` (none) |
| `conventions.notes` | one-line reminder surfaced to agents | `""` |
| `tenant.scope_fields[]` | e.g. `[userId, tenantId]`; **EMPTY `[]` disables all tenant checks** | `[]` (single-tenant) |
| `guardrail.override_env` | env var that, set `=1`, bypasses a guardrail block for a reviewed exception | `AGENTIC_OVERRIDE` |
| `gates.qa` | lint + static checks | `scripts/qa.sh` |
| `gates.test` | install + build/type-check + unit tests | `scripts/test.sh` |
| `gates.security` | secrets, env files, destructive SQL, dep audit | `scripts/security-check.sh` |
| `memory.enabled` | `false` = pure no-op (no AgentDB/Ruflo calls anywhere) | `true` |
| `memory.namespace` | `""` = use `project.name`; keys are `<ns>[:<branch>][:<epic>]` | `project.name` |
| `memory.warm_start` | SessionStart hook injects top-K relevant memory | `true` |
| `memory.top_k` | how many patterns to recall on warm start | `8` |
| `docs.root` | docs root dir | `docs` |
| `docs.prd` | PRD path | `docs/product/PRD.md` |
| `docs.stories` | User stories path | `docs/product/USER-STORIES.md` |
| `docs.acceptance` | Acceptance criteria path | `docs/product/ACCEPTANCE-CRITERIA.md` |
| `docs.tasks` | Engineering tasks path | `docs/product/ENGINEERING-TASKS.md` |
| `docs.backlog` | Backlog path | `docs/BACKLOG.md` |
| `docs.epics` | Epics dir | `docs/epics` |
| `docs.definition_of_done` | DoD path | `docs/DEFINITION-OF-DONE.md` |

> **Two switches worth knowing.** `tenant.scope_fields: []` turns off **all**
> tenant-scoping checks (correct for single-tenant / non-SaaS apps), and
> `memory.enabled: false` makes the whole self-learning layer a no-op. Both are
> graceful — the workflow runs fine with them off.

The detection logic lives in `templates/scripts/_agentic_lib.sh`
(`manifest_get`, `manifest_list`, `detect_pm`, `detect_monorepo_tool`,
`detect_integration_branch`, `detect_primary_branch`, `pm_run_prefix`), a
dependency-free bash reader — no `yq` needed.

---

## The standardized doc set each mode produces

Every project carries the **same** doc set so any agent (Claude, Codex, human)
knows where the truth lives. Full spec in [DOCS-FORMAT.md](DOCS-FORMAT.md); the
summary:

| Artifact | Purpose | Default path |
|----------|---------|--------------|
| **PRD** | *Why* — problem, goals, scope, non-goals | `docs/product/PRD.md` |
| **User Stories** | *Who needs what* — `US-{DOMAIN}-{n}` | `docs/product/USER-STORIES.md` |
| **Acceptance Criteria** | *Done means* — Given/When/Then | `docs/product/ACCEPTANCE-CRITERIA.md` |
| **Epics** | *Units of work* — tasks + status + Automation Log | `docs/epics/EPIC-XXX-*.md` |
| **Tasks** | *Engineering breakdown* — `T-XXX` | `docs/product/ENGINEERING-TASKS.md` |
| **Backlog** | *What's next* — prioritized seed list | `docs/BACKLOG.md` |
| **Definition of Done** | *The bar* every task clears | `docs/DEFINITION-OF-DONE.md` |

**How each mode produces it:**

- **new** — *synthesizes* the docs from your brief/answers, top-down (PRD first,
  decomposing into stories → criteria → tasks → backlog → epics).
- **existing** — *reverse-engineers* draft docs **from the actual code** (modules,
  routes, domains), marked as drafts for human review.
- **maintenance** — *fills the gaps*: adds any standard artifact that's missing
  from the same templates, and normalizes epic statuses.

**Canonicity** (who wins on conflict): Epics + `epics/README.md` status registry
are **canonical** (live state) > PRD/Stories/AC/Tasks (the intent) > Backlog
(seeds only). If the backlog and an epic disagree, the epic wins.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `/agentic-init` picks the wrong mode | Auto-detect signals ambiguous | Force it: `/agentic-init existing` (or `new` / `maintenance`) |
| Manifest has wrong package manager / branch | Detection guessed | Edit `.agentic/config.yml` and set the value explicitly — manifest always wins over auto-detect |
| Tenant checks firing on a single-tenant app | `tenant.scope_fields` not empty | Set `tenant.scope_fields: []` |
| Memory calls noisy / slow | Engine present but not wanted | Set `memory.enabled: false` for a pure no-op |
| `git diff` shows app-code changes after `existing` init | A bug — existing mode must be additive | Stop, revert; report. Existing mode must only add `.agentic/`, `.claude/`, `/docs/`, `scripts/` |
| Gate scripts not executable | `chmod +x` step skipped | `chmod +x scripts/*.sh` |
| Epic statuses inconsistent with the registry | Drift over time | Run `/agentic-init maintenance` to normalize against the lifecycle |

For install-level issues (plugins not loading, MCP not connecting, hooks not
firing, GateGuard), see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## Next

- [DOCS-FORMAT.md](DOCS-FORMAT.md) — the full spec for the standardized doc set.
- [ARCHITECTURE.md](ARCHITECTURE.md) — the nervous system + self-learning loop.
- [TESTING.md](TESTING.md) — the testing taxonomy and how it maps to the gates.
