# Panel: Production Readiness Review

> **DEPRECATED:** This panel has been consolidated into `governance/prompts/reviews/production-readiness-review.md`.
> The new format is a self-contained review prompt with inlined perspectives.
> This file will be removed in a future release.

## Purpose


Assess whether a system is ready for production deployment.


## Participants

- **SRE** - SLOs, runbooks, on-call readiness
- **Infrastructure Engineer** - Deployment, security, networking
- **Observability Engineer** - Logging, metrics, alerting
- **Failure Engineer** - Recovery, rollback, graceful degradation
- **DevOps Engineer** - CI/CD, artifact management, environments


## Process

1. Review deployment architecture
2. Each participant assesses operational readiness
3. Identify gaps in observability and recovery
4. Evaluate incident response capability

5. Determine launch blockers vs follow-ups


## Output Format

> **Schema:** All emissions must conform to [`panel-output.schema.json`](../../schemas/panel-output.schema.json). Wrap the JSON block in `<!-- STRUCTURED_EMISSION_START -->` and `<!-- STRUCTURED_EMISSION_END -->` markers.

### Per Participant

- Perspective name

- Readiness gaps
- Risk level
- Required before launch

### Consolidated

- Launch blockers (must fix)

- Launch risks (accepted with mitigation)
- Post-launch requirements
- Operational runbook status
- Go/No-Go recommendation

### Structured Emission Example

```json
{
  "panel_name": "production-readiness-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.85,
  "risk_level": "low",
  "compliance_score": 0.92,
  "policy_flags": [],
  "requires_human_review": false,
  "timestamp": "2026-01-15T10:30:00Z",
  "findings": [
    {
      "persona": "SRE",
      "verdict": "approve",
      "confidence": 0.90,
      "rationale": "No significant issues found."
    },
    {
      "persona": "Infrastructure Engineer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    },
    {
      "persona": "Observability Engineer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    }
  ],
  "aggregate_verdict": "approve"
}
```

_Other participants (Failure Engineer, DevOps Engineer) omitted for brevity._

## Pass/Fail Criteria

This panel **passes** when all of the following are met:

| Criterion | Threshold | Blocked If |
|-----------|-----------|------------|
| Confidence score | >= 0.75 | Below 0.75 |
| Critical findings | 0 allowed | Any critical finding present |
| High findings | <= 1 | More than 1 high finding |
| Aggregate verdict | approve | Block or abstain majority |
| Compliance score | >= 0.80 | Below 0.80 |

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

- Ensure rollback capability exists
- Verify alerting covers critical paths
- Require runbooks for known failure modes
- Document accepted risks explicitly
