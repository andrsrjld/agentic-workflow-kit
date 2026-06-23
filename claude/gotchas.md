# Gotchas — Known Traps

Common pitfalls when working with this kit. Read before implementing.

## Claude Code Behavior

**Context bloat kills quality.** Past ~70% context window, output degrades silently.
Watch for it in long sessions. Reset context between PLAN and IMPLEMENT phases.

**Agents hallucinate APIs.** Always use Context7 MCP to verify library signatures before
implementing. Never trust training-data knowledge for version-specific APIs — it drifts.

**Sub-agents for research only, not implementation.** Delegating implementation to sub-agents
causes hallucination because they lack full file context. Research/discovery → sub-agents OK.
Writing/editing code → main session only.

**`/nerve` doesn't replace organ commands.** `/nerve` orchestrates — it routes to
`/task-work`, `/epic-loop`, etc. Don't call `/nerve` on a task that already has a shaped epic;
call `/task-work EPIC-XXX <n>` directly.

## Git / PR

**Never amend published commits.** If a pre-commit hook fails, fix the issue and create a
NEW commit — amending would modify the previous commit and risk losing work.

**Never force-push main/master.** The guardrail hook blocks this. If you're tempted, you're
doing something wrong upstream.

**`git add -A` can include secrets.** Always stage specific files by name, not globs.

## Memory / Learning Loop

**Memory is a cache, not the record.** Every durable decision written to AgentDB/Ruflo must
ALSO be copied to the epic's Automation Log. If the store is wiped, docs survive.

**Stale memory is worse than no memory.** If you recall something that conflicts with what
you see in the code, trust the code and update/remove the stale memory entry.

## Gates / Security

**Never skip gates with `--no-verify`.** Investigate the failure, don't bypass it.

**Never commit .env files.** The security gate blocks this, but don't rely on it — develop
the habit of checking `git diff` before every commit.

**`DROP TABLE` / `TRUNCATE` / `DELETE` without WHERE** are blocked by the guardrail hook.
If you genuinely need one, the user must explicitly approve it.

## Installs / Tooling

**Re-run `bash install/install.sh` after kit changes.** The kit repo is the source of truth.
Local `~/.claude/` and `~/.agentic-workflows/` are deployed copies — they don't self-update.

**`npx ruflo`/`@claude-flow/cli` calls no-op gracefully when offline.** The workflow still
runs on plain tools — don't treat a no-op as a failure.

**Node < 20 breaks the installer hard.** The only hard requirement is Node >= 20 + git.
Everything else degrades gracefully.
