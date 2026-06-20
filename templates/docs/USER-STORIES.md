# {{PROJECT_NAME}} — User Stories

> Companion to `PRD.md`. Stories use `As a {role}, I want {capability}, so that {outcome}`.
> Roles: {{ROLE_GLOSSARY}} (e.g. **{{ROLE_1}}**, **{{ROLE_2}}**, **{{ROLE_3}}**).
> Each story carries an ID (`US-{DOMAIN}-{n}`), priority (P0–P2), owning epic, and acceptance criteria.
> Stories in domains {{DELIVERED_DOMAINS}} are largely **delivered**; {{PLANNED_DOMAINS}} are **planned**.

<!--
Conventions:
- One `## N. {Domain} — EPIC-XXX` section per domain. Number sections sequentially.
- ID = `US-{DOMAIN}-{n}` where {DOMAIN} is a short uppercase tag (AUTH, DASH, TXN…).
- Priority: P0 = MVP-blocking · P1 = core product · P2 = follow-on/integration.
- Mark delivered stories with a trailing ✅ in the Epic column (or the row).
- Close every domain with a single **Acceptance:** paragraph (the shared bar for that domain).
-->

---

## 1. {{DOMAIN_NAME}} — {{EPIC_ID}}

| ID            | Story                                                                       | Priority | Epic        |
| ------------- | --------------------------------------------------------------------------- | -------- | ----------- |
| US-{{DOM}}-1  | As a {{ROLE}}, I want {{CAPABILITY}}, so that {{OUTCOME}}.                   | P0       | {{EPIC_ID}} |
| US-{{DOM}}-2  | As a {{ROLE}}, I want {{CAPABILITY}}, so that {{OUTCOME}}.                   | P1       | {{EPIC_ID}} |
| US-{{DOM}}-3  | As a {{ROLE}}, I want {{CAPABILITY}}, so that {{OUTCOME}}.                   | P2       | {{EPIC_ID}} |

**Acceptance:** {{DOMAIN_ACCEPTANCE_PARAGRAPH}} — the shared, testable bar every story in this domain must clear. Keep it specific (where the source of truth lives, what must persist, what must stay consistent across surfaces).

---

## 2. {{DOMAIN_NAME}} — {{EPIC_ID}}

| ID            | Story                                                     | Priority |
| ------------- | --------------------------------------------------------- | -------- |
| US-{{DOM}}-1  | As a {{ROLE}}, I want {{CAPABILITY}}, so that {{OUTCOME}}. | P0       |
| US-{{DOM}}-2  | As a {{ROLE}}, I want {{CAPABILITY}}, so that {{OUTCOME}}. | P1       |

**Acceptance:** {{DOMAIN_ACCEPTANCE_PARAGRAPH}}

---

<!-- Repeat one `## N. {Domain} — EPIC-XXX` block per domain. -->

## Coverage Check

{{COVERAGE_STATEMENT}} — confirm every product surface in `PRD.md` Appendix A maps to at least one story domain above, and note which domains are delivered vs planned and in which epics.
