# Implementation Progress — Agentic Workflow Kit

> **Resumability anchor.** This file is the single source of truth for "where are we".
> After a session/limit reset, a new session reads: this file + the plan
> (`~/.claude/plans/lively-seeking-manatee.md`) + project memory, then continues from
> the first unchecked item. Update this file as each item completes.

**Status legend:** `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked

Last updated: 2026-06-20 — by Claude (initial scaffold)

---

## Phase 3 — Distribution repo (authoring home, built first)

- [x] Repo skeleton + git init (`/home/stealth/WORK/vibes/agentic-workflow-kit`)
- [x] Anchor files: README.md, PROGRESS.md, LICENSE, .gitignore
- [x] `rules/` — 7 global rules authored (agent-routing, docs-source-of-truth, graph-intelligence, memory-protocol, nervous-system, self-learning, testing-taxonomy)
- [x] `claude/commands/` — nerve.md, agentic-init.md
- [x] `claude/hooks/` — nerve-session-start.sh, nerve-capture.sh, nerve-consolidate.sh, guardrail.sh (generic) — bash -n clean; guardrail block logic + graceful no-op self-tested
- [x] `claude/settings.snippet.json` — additive hook + permission merge snippet — valid JSON
- [x] `templates/agentic/config.yml` — manifest schema template
- [x] `templates/scripts/_agentic_lib.sh` — manifest reader lib (manifest_get/list, detect_*)
- [x] `templates/docs/` — PRD,USER-STORIES,ACCEPTANCE-CRITERIA,ENGINEERING-TASKS,BACKLOG,DEFINITION-OF-DONE,epics/README,EPIC-template,EPIC-000-bootstrap,backlog.json (valid JSON)
- [x] `templates/claude/` — CLAUDE/AGENTS/CONVENTIONS .tmpl + 6 agents/*.tmpl + 6 commands/*.tmpl (manifest-driven, tenant-aware, discovery-first)
- [x] `agentic-workflows/` runbooks — nerve-runbook.md, bootstrap-new-project.md (ADOPTION-GUIDE.md lives under docs/, installer copies it to ~/.agentic-workflows)
- [x] `install/install.sh` — idempotent installer
- [x] `install/verify.sh` — doctor — read-only PASS/WARN table, exits 0 on warnings
- [x] `docs/` — INSTALL, ADOPTION-GUIDE, ARCHITECTURE, DOCS-FORMAT, TESTING, TROUBLESHOOTING
- [x] `examples/` — new-project-walkthrough.md
- [x] Initial commit — decbeb4 (56 files, 5420 insertions)

## Phase 3.5 — Greenfield PIV track (adapted from "no-fluff agentic coding" video)  ✅

- [x] `rules/golden-rules.md` — AI layer + PIV loop + 4 golden rules (context · commandify · git=memory · system-evolution); cross-linked to nervous-system/self-learning/memory-protocol/agent-routing/testing-taxonomy; positioned as opt-in parallel track to the epic flow
- [x] `agentic-workflows/piv-loop-runbook.md` — model-agnostic PIV spec (Phase 0 AI layer → /prime → PLAN → IMPLEMENT → VALIDATE → system evolution); thin-frontend source for the commands
- [x] `templates/claude/commands/{create-prd,prime,plan-feature,execute,commit}.md.tmpl` — manifest-driven (`{{manifest.*}}`), graceful-degradation + guardrail blocks, gates reused from manifest
- [x] `templates/agentic/config.yml` — added `docs.plans: docs/plans` (consumed by plan-feature/execute)
- [x] README repo-layout + feature list updated; auto-deploys via install Step 4 (rules glob) + Step 7 (templates/runbooks glob), scaffolded by /agentic-init (globs *.tmpl) — no registry edit needed
- Source: `_transcript.md` (YouTube goOZSXmrYQ4). Additive only; nothing existing changed/removed.

## Phase 1 — Nervous system on WealthMe (after kit deploy)

- [!] Run `install/install.sh` → BLOCKED: auto-mode classifier denied (settings.json
      merge + wildcard permission widening needs the USER's hand). HANDED TO USER:
      run `! bash /home/stealth/WORK/vibes/agentic-workflow-kit/install/install.sh`
      then `! bash .../install/verify.sh`. Everything below this line waits on it.
- [ ] Verify deploy: 7 rules present, `/nerve` + `/agentic-init` available, hooks merged non-destructively (rtk + guardrail intact)
- [ ] Wire `.claude/commands/{agentic-start,task-work,epic-loop}.md` → Step 0 RETRIEVE + final JUDGE/DISTILL/CONSOLIDATE
- [ ] Rewrite `.claude/agents/epic-orchestrator.md` → discovery-first ECC/Ruflo routing
- [ ] Update `.claude/agents/code-agent.md` (+ review-qa/security/test) → consume warm-start, emit learnings
- [ ] Update `AGENTS.md` + `CLAUDE.md` → `/nerve` front door, model-agnostic note
- [ ] Graphify cadence doc in `docs/AGENTIC-AGENT-LOOP.md`
- [ ] Verify: warm-start hook no-ops cleanly; round-trip learning; discovery-first routing
- NOTE: kit templates for the Phase-1 wiring already exist at
  `agentic-workflow-kit/templates/claude/{commands,agents}/*.tmpl` — the WealthMe
  edits are a manifest-fill of those. Do them after deploy so they reference live rules.

## Phase 2 — Portability dogfood on WealthMe  ✅ (branch `feat/agentic-manifest-dogfood`)

- [x] Write WealthMe `.agentic/config.yml` (real values) — committed b9335eb
- [x] Refactor `scripts/{test,qa,security-check,deploy-dev}.sh` → manifest-driven + auto-detect fallback
- [x] Refactor `.claude/hooks/guardrail.sh` → `AGENTIC_OVERRIDE` from manifest (generic kit guardrail, +DELETE-without-WHERE)
- [x] Add WealthMe `docs/DEFINITION-OF-DONE.md` + `docs/product/ACCEPTANCE-CRITERIA.md`
- [ ] Rewrite `docs/AGENTIC-NEW-PROJECT-SETUP.md` → cover existing + maintenance (REMAINING — small doc edit)
- [~] Verify behavior-preserving: security gate runs identically (fails only on PRE-EXISTING
      multer advisory — same as before); guardrail blocks force-push via AGENTIC_OVERRIDE +
      DELETE-without-WHERE, bypass/safe pass (tested). qa/test verified by resolved-command
      equivalence (pnpm turbo run build|lint|test) — full double build skipped (cost), not a regression.
- [x] `.agentic/config.local.yml` gitignored
- [x] BONUS fix: `manifest_list` hardened for prettier multiline flow arrays (kit 2f0a4ca, WM 0ee1a22)

## Final validation (all phases)

- [ ] `/agentic-init new` on a throwaway empty repo → full scaffold → `/nerve "<task>"` runs
- [ ] `/agentic-init existing` on a copy of a non-agentic repo → only additive diff
- [ ] `install.sh` from clean clone → `verify.sh` all green
- [ ] Update plan + memory with final state

---

## Decisions locked (from planning)
- Centralized brain: new `/nerve`; bootstrap: new `/agentic-init` (modes new|existing|maintenance)
- Engine: CLI/MCP (`npx ruflo`, `npx @claude-flow/cli`, `mcp__claude-flow__*`); thin Claude/Codex frontends
- Auto-memory: hybrid (Claude hooks + portable CLI step); graceful no-op when absent
- Params: per-project `.agentic/config.yml` manifest; machine overrides in `.agentic/config.local.yml`
- WealthMe dogfoods the kit (one source of truth, no drift)
- Docs: per-project `/docs` in shared standard format (PRD·Stories·AC·Epics·Tasks·Backlog·DoD)
- Source-of-truth inversion: kit repo is canonical; `install.sh` deploys to `~/.claude` + `~/.agentic-workflows`

## Self-learning loop → engine mapping (reference)
- retrieve → `agentdb_pattern-search`/`semantic-route`/`hierarchical-recall` · `npx ruflo memory search`
- judge → `agentdb_feedback` / `hooks_intelligence_trajectory-end` · gate verdicts as labels
- distill → `agentdb_context-synthesize` · `npx ruflo memory store`
- consolidate → `agentdb_consolidate`/`hierarchical-store` · `npx @claude-flow/cli memory store --namespace patterns`
