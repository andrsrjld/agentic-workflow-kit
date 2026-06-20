# {{PROJECT_NAME}} — Acceptance Criteria Standard

> The single, shared definition of "what makes a story or task acceptable" for this
> project. User stories (`USER-STORIES.md`) and epics (`docs/epics/*`) embed acceptance
> criteria written to this standard. This file defines the **format**; individual
> stories/epics supply the **content**.

---

## Two complementary forms

Use **both**, picking the one that fits the criterion:

### 1. Given / When / Then (behavioural)

For anything observable through the product's interface — the default for user stories.

```
Given {{precondition / starting state}}
When  {{the user or system does X}}
Then  {{the observable, verifiable outcome}}
And   {{any additional guaranteed outcome}}
```

- **Given** sets the world up (data, role, page).
- **When** is a single triggering action.
- **Then** is observable and testable — assertable by a human or an automated test.
- Cover the **happy path first**, then add scenarios for negative / edge / error paths.

### 2. Checklist (structural / non-behavioural)

For constraints that aren't a user flow — schema rules, performance budgets, security
invariants, convention compliance:

- [ ] {{Verifiable structural requirement}}
- [ ] {{Performance / limit budget, with the number}}
- [ ] {{Security or tenant-scoping invariant}}
- [ ] {{Convention the change must follow}}

---

## How acceptance criteria are embedded

| Location              | What it carries                                                              |
| --------------------- | --------------------------------------------------------------------------- |
| **User stories**      | One **Acceptance:** paragraph per domain — the shared bar for that domain.   |
| **Epics (epic-level)**| `## Acceptance Criteria` → the outcomes that mark the whole epic acceptable. |
| **Epics (per-task)**  | Per-`### task group` criteria — the bar one PR-sized task must clear.        |

A criterion is **done** only when it is demonstrably true: an automated test asserts it,
a gate (qa/test/security) passes on it, or a reviewer verifies it against the running app.
Unverifiable criteria ("works well", "is fast") are not acceptable — quantify or restate
them as Given/When/Then.

---

## Worked example

Story: *As a {{ROLE}}, I want {{CAPABILITY}}, so that {{OUTCOME}}.*

**Given/When/Then**

```
Given a signed-in {{ROLE}} with {{starting data}}
When  they {{perform the action}}
Then  {{the primary observable result}}
And   {{the secondary guaranteed result, e.g. totals stay consistent}}

Given {{an invalid / edge input}}
When  they {{attempt the action}}
Then  {{the system rejects it with a clear message and no state change}}
```

**Checklist**

- [ ] Data access is scoped by {{TENANT_SCOPE_FIELDS or "n/a — single-tenant"}}.
- [ ] Shared types come from {{SHARED_TYPES_PACKAGE}} (not redeclared).
- [ ] No new {{forbidden pattern}}; protected paths untouched.
- [ ] Covered by {{unit / integration / E2E}} tests; gates green.

> See `DEFINITION-OF-DONE.md` for the cross-project completion checklist that wraps these
> criteria (criteria pass **and** gates/tests/docs/deploy steps complete).
