# Testing Taxonomy

> A teaching rule for anyone newer to testing. It defines the vocabulary —
> black-box vs white-box, happy path vs negative/edge/error, the unit → integration → E2E
> levels, and smoke testing — and maps each concept to **where it runs in the gates**.
> It complements (does not duplicate) the coverage/TDD requirements in
> [ecc/common/testing.md](../ecc/common/testing.md) — read that for the 80%-coverage and
> red-green-refactor rules.

## Why two rules

`ecc/common/testing.md` says *how much* to test (80% coverage) and *the workflow*
(test-first, AAA structure). This rule explains *the kinds* of tests and *which gate*
each kind belongs to, so a newcomer knows what they are writing and why.

## Black-Box vs White-Box

These describe **how much you know about the internals** when you write the test.

| | Black-box | White-box |
|--|-----------|-----------|
| **Definition** | Test behavior through the public interface; internals are unknown/ignored | Test with knowledge of the internal branches and code paths |
| **You assert on** | Inputs → outputs / observable effects | Specific branches, conditions, and code paths being exercised |
| **Driven by** | Requirements and acceptance criteria | Code coverage (hit every branch) |
| **Typical home** | Most E2E and integration tests | Most unit tests |
| **When to use** | Verifying *what the system does* for a user | Verifying *how a function behaves* across its logic |

A good suite uses both: white-box unit tests prove each function's branches are correct;
black-box E2E tests prove the assembled system does what the user needs.

## Happy Path vs the Rest

For any behavior, test more than the success case:

- **Happy path** — the expected, successful flow (valid input, everything available). Always test this first.
- **Negative path** — invalid input, unauthorized access, missing required data → assert the correct rejection/error.
- **Edge cases** — boundaries: empty list, zero, max length, first/last item, off-by-one limits.
- **Error paths** — a dependency fails (DB down, API 500, timeout) → assert graceful handling, not a crash or a silently-swallowed error.

A feature "works" only when the happy path **and** its negative/edge/error paths are
covered. Untested error paths are where silent failures hide.

## Levels: Unit → Integration → E2E

| Level | Scope | Isolation | Speed | Example |
|-------|-------|-----------|-------|---------|
| **Unit** | One function / component | Fully isolated; dependencies mocked | Fastest | `formatCurrency(1234.5)` returns `"$1,234.50"` |
| **Integration** | Several modules together, with real DB/API | Partial; real collaborators | Medium | An API endpoint writes a row and returns it |
| **E2E** | A full user journey through the running app | None; the real app | Slowest | User logs in, opens a page, sees their data |

Climb the pyramid: many fast unit tests, fewer integration tests, a handful of E2E tests
on the **critical** journeys. E2E is expensive — reserve it for flows that must never break.

## Smoke Testing

A **smoke test** is a fast "is it alive / does the critical path still work" check run
**right after a build or deploy** — before deeper testing. It is not exhaustive; it
catches gross breakage early.

Typical smoke checks: a health endpoint responds (`curl /health`), the app boots, and one
critical journey passes (e.g. log in and load the home page). If the smoke test fails,
stop — there is no point running the full suite against a dead build.

## Mapping to the Gates

Each kind of test maps to a specific gate in the workflow:

| Test kind | Gate | Engine (typical) |
|-----------|------|------------------|
| **White-box unit** | **test gate** (`gates.test` → `scripts/test.sh`) | the project's unit runner (Jest / Vitest / pytest / go test …) |
| **Integration** | **test gate** (same script, integration suite) | runner + real DB/API fixtures |
| **Black-box E2E** | **e2e gate** | Playwright / the project's E2E runner, against the running app |
| **Smoke** | **post-deploy** | health URL + one critical journey, from the manifest `deploy.health_url` / `deploy.smoke_user` |

Concretely, in a manifest-driven project:

- White-box unit + integration → `gates.test` (install → type-check/build → run tests).
- Black-box E2E → the E2E runner on critical journeys.
- Smoke → after `deploy.dev_command`: hit `deploy.health_url`, then one journey as `deploy.smoke_user`.

## Quick Decision Guide

- Writing a pure function? → **white-box unit**, happy + edge + error.
- Verifying an endpoint touches the DB correctly? → **integration**.
- Verifying a user can complete a flow? → **black-box E2E** on the critical journey.
- Just deployed and want a fast confidence check? → **smoke** (health + one journey).

For coverage targets and the test-first workflow, see
[ecc/common/testing.md](../ecc/common/testing.md).
