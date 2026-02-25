# Panel: Architecture Review

> **DEPRECATED:** This panel has been consolidated into `governance/prompts/reviews/architecture-review.md`.
> The new format is a self-contained review prompt with inlined perspectives.
> This file will be removed in a future release.

## Purpose
Evaluate system design decisions from multiple architectural perspectives.

## Participants
- **Systems Architect** - Scalability, boundaries, state management
- **Security Auditor** - Attack surface, auth model, data protection
- **Failure Engineer** - Resilience, recovery, blast radius
- **Infrastructure Engineer** - Deployment, networking, operations
- **API Designer** - Contracts, versioning, consumer experience

## Process
1. Present design context and constraints
2. Each participant evaluates from their lens
3. Surface cross-cutting concerns
4. Debate tradeoffs explicitly
5. Converge on recommendations

## Output Format

> **Schema:** All emissions must conform to [`panel-output.schema.json`](../../schemas/panel-output.schema.json). Wrap the JSON block in `<!-- STRUCTURED_EMISSION_START -->` and `<!-- STRUCTURED_EMISSION_END -->` markers.

### Per Participant
- Perspective name
- Architectural concerns
- Risk assessment
- Recommended changes

### Consolidated
- Architectural strengths
- Critical risks
- Design modifications required
- Tradeoffs accepted (with rationale)
- Go/No-Go recommendation

### Structured Emission Example

```json
{
  "panel_name": "architecture-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.85,
  "risk_level": "low",
  "compliance_score": 0.92,
  "policy_flags": [],
  "requires_human_review": false,
  "timestamp": "2026-01-15T10:30:00Z",
  "findings": [
    {
      "persona": "Systems Architect",
      "verdict": "approve",
      "confidence": 0.90,
      "rationale": "No significant issues found."
    },
    {
      "persona": "Security Auditor",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    },
    {
      "persona": "Failure Engineer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    }
  ],
  "aggregate_verdict": "approve"
}
```

_Other participants (Infrastructure Engineer, API Designer) omitted for brevity._

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
- Consider both build and operate phases
- Identify hidden assumptions
- Prefer reversible decisions
- Document rejected alternatives
