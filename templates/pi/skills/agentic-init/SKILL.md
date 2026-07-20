---
name: agentic-init
description: Bootstrap or maintain a project's agentic state for Pi — auto-detects new | existing | maintenance and scaffolds the manifest, gates, docs, and the .pi/ adapter. Invoke as /skill:agentic-init [new|existing|maintenance].
---

# Agentic Init (Pi adapter)

Bootstraps or maintains the current project against the agentic workflow. This
is a **thin frontend** over the model-agnostic spec in
`~/.agentic-workflows/bootstrap-new-project.md` — read that runbook for the
authoritative steps.

> **Graceful degradation.** Optional tooling (Ruflo, AgentDB, Graphify, MCP) is
> best-effort; the core scaffold only needs bash + git. Skip what's unavailable.
>
> **Existing-project safety.** In `existing` and `maintenance` modes the change
> is **strictly additive** — only `.agentic/`, `.pi/`, `docs/`, and gate scripts
> are added or repaired. **Never edit application source code.** The result
> must be a clean additive `git diff`.

## 1. Determine mode

Use the mode named after `/skill:agentic-init` if given; otherwise auto-detect
(first match wins):

| Mode | Signal |
|------|--------|
| **new** | empty / near-empty repo (no source tree; only README/LICENSE/.git) |
| **existing** | has app code but **no** `.agentic/config.yml` and no `.pi/` agentic wiring |
| **maintenance** | `.agentic/config.yml` already present (already agentic) |

## 2. Run the mode

### new
1. Scaffold from `~/.agentic-workflows/templates/`: the applicable `pi/`
   adapter (`AGENTS.md`, `skills/{nerve,agentic-init,loop-triage}`), gate
   `scripts/`, and the standard `docs/` skeletons.
2. Write `.agentic/config.yml` from the template with detected values; leave
   unknowns blank (auto at runtime).
3. Product synthesis in order: PRD → User Stories → Acceptance Criteria →
   Engineering Tasks → Backlog → `epics/README.md` → `EPIC-000-bootstrap.md`
   (standardized format — see the `docs-source-of-truth` rule).
4. Make gate scripts executable.
5. Seed disabled loop constraints, state/run-log docs, and
   readiness/ledger/worktree helpers. Do not schedule or enable a loop before
   human review.
6. Kick off: `/skill:nerve "<first task>"`.

### existing (non-destructive)
1. Detect stack / package manager / monorepo tool / branches / layout.
2. Write `.agentic/config.yml` with detected values; surface for user review.
   Leave `tenant.scope_fields: []` unless multi-tenant evidence is found.
3. Drop generic `scripts/` and the applicable `.pi/` adapter. Never overwrite
   project customizations.
4. Reverse-engineer initial `docs/` **from the actual code** (modules, routes,
   domains found), in the standard format, marked as drafts for human review.
5. Add disabled loop controls; do not schedule or enable them.
6. Verify `git diff` shows ONLY `.agentic/`, `.pi/`, `docs/`, `scripts/`
   additions. Stop and report if anything else changed.

### maintenance
1. Sync generic scripts and the `.pi/` adapter to the kit's current versions,
   preserving project customizations.
2. Fill missing standard artifacts (e.g. `DEFINITION-OF-DONE.md`,
   `ACCEPTANCE-CRITERIA.md`) and missing manifest keys with sane defaults.
   Add missing loop controls disabled; preserve any human-approved policy.
3. Normalize `docs/epics/*` statuses against the canonical lifecycle and the
   `epics/README.md` registry.
4. Run the gates to confirm no regression; report drift.

## 3. After any mode

- Run `bash install/verify.sh` (or the project's verify) to confirm wiring.
- Append a one-line note to the active epic `Automation Log` recording what
  the bootstrap did.

## Guardrails

No production deploy · no force-push · no destructive DB · no committed
secrets · no app-code edits in `existing`/`maintenance`.
