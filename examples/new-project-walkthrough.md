# Example — New project, empty repo → first task

> A minimal worked example of taking an **empty repository** to a fully agentic
> state with the kit, then running the first task through `/nerve`. Commands are
> copy-pasteable; swap the `{{placeholders}}` for your project.
>
> Assumes the kit is already installed (`install/install.sh` ran once, deploying
> rules/commands/hooks into `~/.claude` and templates into `~/.agentic-workflows`).

---

## 1. Start from an empty repo

```bash
mkdir my-app && cd my-app
git init
```

```
my-app/
└── .git/
```

## 2. Bootstrap with `/agentic-init new`

In Claude Code, from the repo root:

```
/agentic-init new
```

This runs the `new` mode of the bootstrap runbook. It auto-detects what it can
(package manager, integration branch, project type), scaffolds the agentic wiring,
and synthesizes the standardized `/docs` set in canonical order
(PRD → User Stories → Acceptance Criteria → Engineering Tasks → Backlog →
`epics/README.md` → `EPIC-000-bootstrap.md`).

Resulting tree:

```
my-app/
├── .agentic/
│   └── config.yml                     # the manifest — single source of truth
├── .claude/
│   ├── commands/                      # /nerve, /agentic-init, organ commands
│   ├── agents/                        # code / review / security / deploy agents
│   ├── hooks/                         # guardrail + warm-start hooks
│   └── settings.json                  # merged non-destructively
├── scripts/
│   ├── qa.sh                          # gates.qa
│   ├── test.sh                        # gates.test
│   └── security-check.sh              # gates.security
└── docs/
    ├── product/
    │   ├── PRD.md
    │   ├── USER-STORIES.md
    │   ├── ACCEPTANCE-CRITERIA.md
    │   └── ENGINEERING-TASKS.md
    ├── BACKLOG.md
    ├── backlog.json
    ├── DEFINITION-OF-DONE.md
    └── epics/
        ├── README.md                  # canonical status registry
        └── EPIC-000-bootstrap.md      # first/foundation epic (status: on-progress)
```

## 3. Review the generated manifest

`.agentic/config.yml` is git-tracked and drives every generic script/hook. Blank
fields auto-detect at runtime; fill in the project-specific ones:

```yaml
project:
  name: my-app
  type: single-app
docs:
  root: docs
  prd: docs/product/PRD.md
  # … the rest of the standard doc paths …
gates:
  qa: scripts/qa.sh
  test: scripts/test.sh
  security: scripts/security-check.sh
deploy:
  dev_command: ""        # set your DEV deploy (leave blank to disable the deploy gate)
tenant:
  scope_fields: []       # leave empty for single-tenant; tenant checks stay off
```

Commit the scaffold once it looks right:

```bash
git add .agentic .claude scripts docs
git commit -m "chore: bootstrap agentic workflow kit"
```

## 4. Run the first task with `/nerve`

`/nerve` is the front door. Hand it a task in plain language:

```
/nerve "implement T-001: initialize repo structure and a green build"
```

`/nerve` will: classify the task (L1), retrieve any relevant memory/docs, route to
the right pre-built agent or organ command (L2), implement the minimal change, run
the three gates, then judge → distill → consolidate the outcome and append a line
to the `EPIC-000` **Automation Log**.

For a task already shaped as an epic group, you can target it directly:

```
/task-work EPIC-000 1        # work one ### task group → gates → branch → PR
```

Or drive the whole foundation epic end-to-end (DEV-only, bounded retries):

```
/epic-loop docs/epics/EPIC-000-bootstrap.md
```

## 5. What "done" means

Each task clears the cross-project `docs/DEFINITION-OF-DONE.md` checklist —
merged, acceptance criteria pass, gates green, tests added, security reviewed,
docs/Automation-Log updated, deployed to DEV. When every task in `EPIC-000`
passes, its `status:` advances to `ready-for-qa` for human sign-off, then `done`.

From here, add feature epics (copy `docs/epics/EPIC-template.md`, register it in
`docs/epics/README.md`) and keep driving them with `/nerve`, `/task-work`, or
`/epic-loop`.
