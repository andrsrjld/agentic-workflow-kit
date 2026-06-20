# Testing

A teaching guide to the testing vocabulary the kit uses, written for anyone newer
to testing. It defines the kinds of tests — black-box vs white-box, happy path vs
negative/edge/error, the unit → integration → E2E levels, and smoke testing — and
maps each to **where it runs in the gates**. It's a fuller, example-driven version
of the `testing-taxonomy` rule.

> **Two complementary rules.** `ecc/common/testing.md` says *how much* to test
> (80% coverage) and *the workflow* (test-first, AAA). This guide explains *the
> kinds* of tests and *which gate* each belongs to. Read both.

---

## Black-box vs white-box

These describe **how much you know about the internals** when you write the test.

| | Black-box | White-box |
|--|-----------|-----------|
| **Definition** | Test behavior through the public interface; internals ignored | Test with knowledge of the internal branches and code paths |
| **You assert on** | Inputs → outputs / observable effects | Specific branches, conditions, code paths exercised |
| **Driven by** | Requirements + acceptance criteria | Code coverage (hit every branch) |
| **Typical home** | Most E2E + integration tests | Most unit tests |
| **Use it to verify** | *what the system does* for a user | *how a function behaves* across its logic |

A good suite uses **both**: white-box unit tests prove each function's branches
are correct; black-box E2E tests prove the assembled system does what the user
needs.

**Example.**

- *White-box:* you read `calculateDiscount()` and write a test for each branch —
  no discount, tier-1, tier-2, the cap — because you can see the `if`s.
- *Black-box:* you don't look inside checkout; you assert "a tier-2 user sees the
  expected total at the confirmation screen."

---

## Happy path vs the rest

For any behavior, test more than the success case. Untested error paths are where
silent failures hide.

| Path | Test | Example for "import accounts" |
|------|------|-------------------------------|
| **Happy** | The expected, successful flow — always test first | Valid file imports, balances render |
| **Negative** | Invalid input, unauthorized access, missing data → assert the correct rejection | Wrong file type → clear validation error |
| **Edge** | Boundaries: empty, zero, max length, first/last, off-by-one | Empty file → empty state, not a crash |
| **Error** | A dependency fails (DB down, API 500, timeout) → assert graceful handling | Import API times out → retry shown, no blank screen |

A feature "works" only when the happy path **and** its negative/edge/error paths
are covered.

---

## Levels: unit → integration → E2E

| Level | Scope | Isolation | Speed | Example |
|-------|-------|-----------|-------|---------|
| **Unit** | One function / component | Fully isolated; deps mocked | Fastest | `formatCurrency(1234.5)` → `"$1,234.50"` |
| **Integration** | Several modules together, real DB/API | Partial; real collaborators | Medium | An API endpoint writes a row and returns it |
| **E2E** | A full user journey through the running app | None; the real app | Slowest | User logs in, opens a page, sees their data |

```
        ▲  slow, few, expensive
        │      ┌─────────┐
        │      │   E2E   │   critical journeys only
        │   ┌──┴─────────┴──┐
        │   │  Integration  │  modules + real DB/API
        │ ┌─┴───────────────┴─┐
        │ │       Unit        │  many, fast, isolated
        │ └───────────────────┘
        ▼  fast, many, cheap
```

**Climb the pyramid:** many fast unit tests, fewer integration tests, a handful
of E2E tests on the **critical** journeys. E2E is expensive — reserve it for
flows that must never break.

---

## Smoke testing

A **smoke test** is a fast "is it alive / does the critical path still work" check
run **right after a build or deploy**, before deeper testing. It is not
exhaustive; it catches gross breakage early.

Typical smoke checks:

- A health endpoint responds: `curl <deploy.health_url>` → 200.
- The app boots.
- **One** critical journey passes (e.g. log in as `deploy.smoke_user` and load the
  home page).

If the smoke test fails, **stop** — there's no point running the full suite
against a dead build.

---

## Mapping to the gates

Each kind of test maps to a specific gate in the workflow:

| Test kind | Gate | Engine (typical) |
|-----------|------|------------------|
| **White-box unit** | **test gate** — `gates.test` → `scripts/test.sh` | the project's unit runner (Jest / Vitest / pytest / go test …) |
| **Integration** | **test gate** — same script, integration suite | runner + real DB/API fixtures |
| **Black-box E2E** | **e2e gate** | Playwright / the project's E2E runner, against the running app |
| **Smoke** | **post-deploy** | health URL + one critical journey, from `deploy.health_url` / `deploy.smoke_user` |

Concretely, in a manifest-driven project:

- **White-box unit + integration** → `gates.test` (install → type-check/build →
  run tests).
- **Black-box E2E** → the E2E runner on critical journeys.
- **Smoke** → after `deploy.dev_command`: hit `deploy.health_url`, then run one
  journey as `deploy.smoke_user`.

These verdicts are exactly the labels the self-learning loop's **JUDGE** phase
consumes (see [ARCHITECTURE.md](ARCHITECTURE.md) §2): a green test gate is a PASS
label, a red one a FAIL — no separate labeling step.

---

## Quick decision guide

- Writing a pure function? → **white-box unit**, happy + edge + error.
- Verifying an endpoint touches the DB correctly? → **integration**.
- Verifying a user can complete a flow? → **black-box E2E** on the critical
  journey.
- Just deployed and want a fast confidence check? → **smoke** (health + one
  journey).

---

## See also

- `ecc/common/testing.md` — coverage targets (80%) and the test-first workflow.
- [DOCS-FORMAT.md](DOCS-FORMAT.md) — Acceptance Criteria, which black-box tests
  verify.
- [ARCHITECTURE.md](ARCHITECTURE.md) — how gate verdicts feed the learning loop.
