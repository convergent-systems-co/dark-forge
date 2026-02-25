# Panel: Migration Review

> **DEPRECATED:** This panel has been consolidated into `governance/prompts/reviews/migration-review.md`.
> The new format is a self-contained review prompt with inlined perspectives.
> This file will be removed in a future release.

## Purpose
Evaluate migration plan safety, completeness, and risk mitigation.

## Participants
- **Migration Specialist** - Plan completeness, rollback capability
- **Data Architect** - Data integrity, transformation correctness
- **SRE** - Operational readiness, monitoring during migration
- **Failure Engineer** - Failure scenarios, recovery procedures
- **Tech Lead** - Timeline, resource allocation, communication

## Process
1. Review migration plan and timeline
2. Each participant assesses from their perspective
3. Identify rollback gaps
4. Stress-test failure scenarios
5. Validate communication plan

## Output Format

> **Schema:** All emissions must conform to [`panel-output.schema.json`](../../schemas/panel-output.schema.json). Wrap the JSON block in `<!-- STRUCTURED_EMISSION_START -->` and `<!-- STRUCTURED_EMISSION_END -->` markers.

### Per Participant
- Perspective name
- Plan gaps
- Risk concerns
- Required additions

### Consolidated
- Migration blockers
- Risk mitigations required
- Rollback verification checklist
- Monitoring requirements
- Go/No-Go recommendation

### Structured Emission Example

```json
{
  "panel_name": "migration-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.85,
  "risk_level": "low",
  "compliance_score": 0.92,
  "policy_flags": [],
  "requires_human_review": false,
  "timestamp": "2026-01-15T10:30:00Z",
  "findings": [
    {
      "persona": "Migration Specialist",
      "verdict": "approve",
      "confidence": 0.90,
      "rationale": "No significant issues found."
    },
    {
      "persona": "Data Architect",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    },
    {
      "persona": "SRE",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    }
  ],
  "aggregate_verdict": "approve"
}
```

_Other participants (Failure Engineer, Tech Lead) omitted for brevity._

## Pass/Fail Criteria

This panel **passes** when all of the following are met:

| Criterion | Threshold | Blocked If |
|-----------|-----------|------------|
| Confidence score | >= 0.75 | Below 0.75 |
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
- Require tested rollback at every step
- Validate data integrity continuously
- Plan for extended migration states
- Ensure clear abort criteria
