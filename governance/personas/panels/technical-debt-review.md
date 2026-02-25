# Panel: Technical Debt Review

> **DEPRECATED:** This panel has been consolidated into `governance/prompts/reviews/technical-debt-review.md`.
> The new format is a self-contained review prompt with inlined perspectives.
> This file will be removed in a future release.

## Purpose
Assess and prioritize technical debt for strategic remediation.

## Participants
- **Refactor Specialist** - Code structure, duplication, complexity
- **Systems Architect** - Architectural debt, coupling, boundaries
- **Test Engineer** - Test debt, coverage gaps, flaky tests
- **Tech Lead** - Business impact, team velocity, priorities
- **Minimalist Engineer** - Over-engineering, unnecessary complexity

## Process
1. Inventory known technical debt
2. Each participant identifies debt from their perspective
3. Assess impact on velocity and reliability
4. Estimate remediation effort
5. Prioritize by ROI

## Output Format

> **Schema:** All emissions must conform to [`panel-output.schema.json`](../../schemas/panel-output.schema.json). Wrap the JSON block in `<!-- STRUCTURED_EMISSION_START -->` and `<!-- STRUCTURED_EMISSION_END -->` markers.

### Per Participant
- Perspective name
- Debt items identified
- Impact assessment
- Remediation approach

### Consolidated
- Debt inventory with categories
- High-impact items
- Quick wins (low effort, high value)
- Strategic debt (accept with monitoring)
- Recommended roadmap

### Structured Emission Example

```json
{
  "panel_name": "technical-debt-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.85,
  "risk_level": "low",
  "compliance_score": 0.92,
  "policy_flags": [],
  "requires_human_review": false,
  "timestamp": "2026-01-15T10:30:00Z",
  "findings": [
    {
      "persona": "Refactor Specialist",
      "verdict": "approve",
      "confidence": 0.90,
      "rationale": "No significant issues found."
    },
    {
      "persona": "Systems Architect",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    },
    {
      "persona": "Test Engineer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    }
  ],
  "aggregate_verdict": "approve"
}
```

_Other participants (Tech Lead, Minimalist Engineer) omitted for brevity._

## Pass/Fail Criteria

This panel **passes** when all of the following are met:

| Criterion | Threshold | Blocked If |
|-----------|-----------|------------|
| Confidence score | >= 0.65 | Below 0.65 |
| Critical findings | 0 allowed | Any critical finding present |
| High findings | <= 3 | More than 3 high findings |
| Aggregate verdict | request_changes | Block or abstain majority |
| Compliance score | >= 0.60 | Below 0.60 |

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
- Quantify impact where possible
- Consider compounding effects
- Balance remediation with feature work
- Identify debt that blocks future work
