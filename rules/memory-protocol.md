# Memory Protocol

> Automatic, hybrid memory persistence so agents stop re-discovering context. Claude
> persists via lifecycle hooks (SessionStart warm-start · PostToolUse capture · Stop
> consolidate); any harness persists via the same portable `npx` CLI step. Memory is
> namespaced per project/branch/epic and degrades to a full no-op when disabled or absent.

## Purpose

This rule defines **how** memory is written and read (the mechanics), where
[self-learning.md](self-learning.md) defines **what** the four-phase loop does and
[graph-intelligence.md](graph-intelligence.md) defines the multi-source RETRIEVE. The goal
is a **warm start**: a fresh session begins already knowing the relevant prior context, so
it recalls instead of re-reading — the key win across Claude's 5-hour usage windows.

Driven by the manifest `.agentic/config.yml` `memory.*` block:

```yaml
memory:
  enabled: true          # false = pure no-op everywhere
  namespace: ""          # "" = use project.name
  warm_start: true       # SessionStart injects top-K relevant memory
  top_k: 8               # how many patterns to recall on warm start
```

## Hybrid Auto-Save

Two paths write the same memory; use whichever the harness supports. They are additive,
not exclusive.

### Path A — Claude lifecycle hooks (automatic)

| Hook event | Action | Phase |
|------------|--------|-------|
| **SessionStart** | Warm-start RETRIEVE for repo + branch + epic; inject a compact top-K context block | retrieve |
| **PostToolUse** | Capture spike events (edits, gate results) to AgentDB as they happen | judge / distill (incremental) |
| **Stop / SessionEnd** | DISTILL + CONSOLIDATE the session's learnings for the next window | distill / consolidate |

These use hook events that do **not** collide with existing PreToolUse hooks (e.g. an
`rtk` rewrite hook or a project `guardrail.sh`) — they are purely additive.

### Path B — portable CLI step (any model)

Where hooks are unavailable (Codex, CI, another harness), the same persistence runs as
explicit CLI calls inside the runbook:

```bash
# warm start (session begin)
npx ruflo memory search --query "<repo>:<branch> recent decisions" --namespace "<ns>"
# capture / distill (task end)
npx ruflo memory store --namespace "<ns>" --key "<k>" --value "<v>"
# consolidate (session end)
npx @claude-flow/cli memory store --namespace patterns --key "<k>" --value "<canonical>"
```

## Namespacing

Keys are scoped from the manifest (`memory.namespace` or `project.name`) plus the current
git context, so recall is precise and never leaks across projects:

| Namespace | Scope | Example |
|-----------|-------|---------|
| `<ns>` | Whole project | `myproject` |
| `<ns>:<branch>` | Work on a branch | `myproject:feat-onboarding` |
| `<ns>:<epic>` | An epic's decisions | `myproject:EPIC-009` |
| `patterns` | Cross-project / cross-epic promoted lessons | `patterns` |

RETRIEVE queries the most specific namespace first (`<ns>:<epic>`), then widens to `<ns>`
and `patterns`. CONSOLIDATE promotes broadly-useful lessons up to `patterns`.

## What to Store (schema)

Store one focused lesson per entry, not a transcript. Each entry carries:

| Field | Meaning |
|-------|---------|
| **conclusion** | The one-line takeaway ("list queries must filter by tenant fields") |
| **evidence** | Why it's true (gate verdict, error, doc reference) |
| **files** | The paths the lesson touches |
| **decision** | The choice made and the alternative rejected |
| **proof** | The verification that it worked (gate PASS, test name, deploy smoke) |

Keep it minimal and self-contained: a future agent must be able to act on the entry
without re-reading the original session.

## Warm Start (the token-saving goal)

On SessionStart (or the first runbook step), inject a compact top-K block:
recent decisions for this repo+branch+epic, the proven patterns for the task's capability,
and known failure modes. A fresh 5-hour window then begins **warm** — the agent recalls
instead of re-reading dozens of files. This is the primary reason the protocol exists.

## Durability to Docs

Mirroring [self-learning.md](self-learning.md): memory is a **cache**, not the record.
Every durable decision written to memory is **also** copied to the epic's Automation Log
(or the relevant tracked doc per [docs-source-of-truth.md](docs-source-of-truth.md)). If
the store is wiped, decisions survive in version control.

## Graceful Degradation

`memory.enabled: false` → **full no-op**: no AgentDB/Ruflo calls anywhere, hooks exit 0
immediately, the workflow runs on plain tools. The same holds when Ruflo/AgentDB is simply
not installed. Memory is an accelerator that can always be switched off without breaking
the workflow.
