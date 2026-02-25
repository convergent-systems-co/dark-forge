# Panel: Data Design Review

> **DEPRECATED:** This panel has been consolidated into `governance/prompts/reviews/data-design-review.md`.
> The new format is a self-contained review prompt with inlined perspectives.
> This file will be removed in a future release.

## Purpose
Evaluate data architecture, schema design, and data management.

## Participants
- **Data Architect** - Schema, integrity, query patterns
- **Backend Engineer** - Access patterns, ORM usage, transactions
- **Performance Engineer** - Indexing, query optimization, caching
- **Security Auditor** - Data protection, encryption, access control
- **Compliance Officer** - Retention, privacy, audit requirements

## Process
1. Review data model and access patterns
2. Each participant evaluates from their perspective
3. Identify schema evolution risks
4. Assess query performance concerns
5. Evaluate compliance requirements

## Output Format

> **Schema:** All emissions must conform to [`panel-output.schema.json`](../../schemas/panel-output.schema.json). Wrap the JSON block in `<!-- STRUCTURED_EMISSION_START -->` and `<!-- STRUCTURED_EMISSION_END -->` markers.

### Per Participant
- Perspective name
- Data concerns
- Risk level
- Recommended changes

### Consolidated
- Schema issues requiring change
- Performance risks
- Security/compliance gaps
- Migration complexity assessment
- Data architecture recommendations

### Structured Emission Example

```json
{
  "panel_name": "data-design-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.85,
  "risk_level": "low",
  "compliance_score": 0.92,
  "policy_flags": [],
  "requires_human_review": false,
  "timestamp": "2026-01-15T10:30:00Z",
  "findings": [
    {
      "persona": "Data Architect",
      "verdict": "approve",
      "confidence": 0.90,
      "rationale": "No significant issues found."
    },
    {
      "persona": "Backend Engineer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    },
    {
      "persona": "Performance Engineer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    }
  ],
  "aggregate_verdict": "approve"
}
```

_Other participants (Security Auditor, Compliance Officer) omitted for brevity._

## Pass/Fail Criteria

This panel **passes** when all of the following are met:

| Criterion | Threshold | Blocked If |
|-----------|-----------|------------|
| Confidence score | >= 0.70 | Below 0.70 |
| Critical findings | 0 allowed | Any critical finding present |
| High findings | <= 1 | More than 1 high finding |
| Aggregate verdict | approve | Block or abstain majority |
| Compliance score | >= 0.75 | Below 0.75 |

When blocked, the panel emits a `block` verdict with a structured explanation of which criterion failed. The PR comment includes the specific scores and finding counts.

Local overrides via `panels.local.json` can increase these thresholds (more restrictive) but never decrease them. See `governance/schemas/panels.schema.json` for the override format.

## Confidence Score Calculation

```
confidence = 0.85  (base)
           - (critical_findings x 0.25)
           - (high_findings x 0.15)
           - (medium_findings x 0.05)
           - (low_findings x 0.01)
           = max(confidence, 0.0)  (floor)
```

| Finding Severity | Deduction | Example: 1 finding |
|-----------------|-----------|-------------------|
| Critical | -0.25 | 0.85 -> 0.60 |
| High | -0.15 | 0.85 -> 0.70 |
| Medium | -0.05 | 0.85 -> 0.80 |
| Low | -0.01 | 0.85 -> 0.84 |

## Constraints
- Plan for schema evolution
- Consider data growth projections
- Ensure audit trail requirements
- Design for both OLTP and analytics needs
