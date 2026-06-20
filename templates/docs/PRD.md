# {{PROJECT_NAME}} — {{ONE_LINE_PRODUCT_DESCRIPTION}}

> **Status:** DRAFT — requirements only. Implementation decomposition lives in `docs/epics/` + `docs/product/ENGINEERING-TASKS.md`.
> **Version:** {{VERSION}} · **Author:** {{AUTHOR}} · **Synthesized from:** {{SOURCE_BRIEFS}}

---

## Problem

{{PROBLEM_STATEMENT}}

<!--
Describe the user's pain in their own terms, not the solution. What goes wrong
today, for whom, and what does leaving it unsolved cost them? Be concrete.
-->

The cost of leaving this unsolved: {{COST_OF_INACTION}}

## Evidence

<!--
Real signals that this problem is worth solving. Prototypes, interviews,
analytics, waitlists, support tickets. Mark anything unverified explicitly as
`Assumption — needs validation via …` so the reader can tell signal from guess.
-->

- {{EVIDENCE_ITEM_1}}
- {{EVIDENCE_ITEM_2}}
- **Gap:** {{UNVALIDATED_EVIDENCE}} — `Assumption — needs validation via {{VALIDATION_METHOD}}`.

## Users

- **Primary — {{PRIMARY_PERSONA}}**: {{PRIMARY_PERSONA_DESCRIPTION}}. Triggered by {{PRIMARY_TRIGGER}}.
- **Secondary — {{SECONDARY_PERSONA}}**: {{SECONDARY_PERSONA_DESCRIPTION}}.
- **Tertiary — {{TERTIARY_PERSONA}}**: {{TERTIARY_PERSONA_DESCRIPTION}}.
- **Not for**: {{NON_USERS}} — out-of-scope audiences and why.

## Hypothesis

We believe a **{{SOLUTION_SHAPE}}** will **{{INTENDED_BEHAVIOR_CHANGE}}** for **{{TARGET_SEGMENT}}**.

We'll know we're right when **{{LEADING_INDICATOR_1}}**, and **{{LEADING_INDICATOR_2}}** within {{TIME_HORIZON}}.

## Success Metrics

| Metric              | Target              | How measured              |
| ------------------- | ------------------- | ------------------------- |
| {{METRIC_1}}        | {{TARGET_1}}        | {{MEASUREMENT_1}}         |
| {{METRIC_2}}        | {{TARGET_2}}        | {{MEASUREMENT_2}}         |
| {{METRIC_3}}        | {{TARGET_3}}        | {{MEASUREMENT_3}}         |

> Targets are `TBD — needs validation via {{VALIDATION_SOURCE}}`. Listed as directional, not committed.

## Scope

**MVP (delivered / target)** — {{MVP_DESCRIPTION}}. This is **{{MVP_EPICS}}**.

**Post-MVP (planned)** — {{POST_MVP_DESCRIPTION}}:

- **{{EPIC_ID}} — {{EPIC_NAME}}**: {{EPIC_SUMMARY}}.
- **{{EPIC_ID}} — {{EPIC_NAME}}**: {{EPIC_SUMMARY}}.

**Out of scope (v1)**

- **{{OUT_OF_SCOPE_ITEM}}** — {{REASON_AND_DEFERRAL}}.
- **{{OUT_OF_SCOPE_ITEM}}** — {{REASON_AND_DEFERRAL}}.

## Delivery Milestones

<!-- Business outcomes, not engineering tasks. Each epic = one milestone. -->
<!-- Status mirrors docs/epics/ frontmatter (the canonical source). -->

| #   | Milestone (Epic)      | Outcome              | Status        | Plan                                  |
| --- | --------------------- | -------------------- | ------------- | ------------------------------------- |
| 1   | {{EPIC_ID}} {{NAME}}  | {{OUTCOME}}          | {{STATUS}}    | `docs/epics/{{EPIC_FILE}}`            |
| 2   | {{EPIC_ID}} {{NAME}}  | {{OUTCOME}}          | {{STATUS}}    | `docs/epics/{{EPIC_FILE}}`            |

## Open Questions

<!-- Each blocks something. Note what, so sequencing is clear. -->

- [ ] **{{OPEN_QUESTION}}** — {{WHY_IT_MATTERS}}. (blocks {{BLOCKED_WORK}})
- [ ] **{{OPEN_QUESTION}}** — {{WHY_IT_MATTERS}}. (blocks {{BLOCKED_WORK}})

## Risks

| Risk            | Likelihood | Impact   | Mitigation            |
| --------------- | ---------- | -------- | --------------------- |
| {{RISK_1}}      | {{L_M_H}}  | {{IMPACT}} | {{MITIGATION_1}}    |
| {{RISK_2}}      | {{L_M_H}}  | {{IMPACT}} | {{MITIGATION_2}}    |

---

## Appendix A — Product Surface ({{N}} pages/screens → epic ownership)

<!-- Optional. Enumerate the UI surface so every screen maps to an owning epic. -->

| #   | Page (route)        | Domain        | Owning Epic   | Status     |
| --- | ------------------- | ------------- | ------------- | ---------- |
| 1   | {{PAGE}} ({{ROUTE}}) | {{DOMAIN}}   | {{EPIC_ID}}   | {{STATUS}} |

## Appendix B — Core Formulas / Domain Rules (authoritative, deterministic)

<!-- Optional. Domain math/rules that must live in shared code (never an LLM). -->

```
{{FORMULA_OR_RULE_1}}
{{FORMULA_OR_RULE_2}}
```

## Appendix C — Tech Stack (locked decisions)

<!-- These also live in `.agentic/config.yml`; keep them in sync. -->

- **Repo:** {{REPO_SHAPE}}
- **Frontend:** {{FRONTEND_STACK}}
- **Backend:** {{BACKEND_STACK}}
- **Database:** {{DATABASE_STACK}}
- **Auth:** {{AUTH_STACK}}
- **Infra:** {{INFRA_STACK}}
- **Integration ports (mock-first):** {{INTEGRATION_PORTS}}
