# Panel: Security Review

> **DEPRECATED:** This panel has been consolidated into `governance/prompts/reviews/security-review.md`.
> The new format is a self-contained review prompt with inlined perspectives.
> This file will be removed in a future release.

## Purpose
Comprehensive security assessment from multiple threat perspectives.

## Participants
- **Security Auditor** - Vulnerabilities, OWASP, secure coding
- **Infrastructure Engineer** - Network security, IAM, encryption
- **Compliance Officer** - Regulatory requirements, audit readiness
- **Adversarial Reviewer** - Attack vectors, threat modeling
- **Backend Engineer** - Auth implementation, data protection

## Process
1. Define threat model and trust boundaries
2. Each participant identifies risks from their lens
3. Classify by severity and exploitability
4. Identify defense gaps
5. Prioritize remediation

## Output Format

> **Schema:** All emissions must conform to [`panel-output.schema.json`](../../schemas/panel-output.schema.json). Wrap the JSON block in `<!-- STRUCTURED_EMISSION_START -->` and `<!-- STRUCTURED_EMISSION_END -->` markers.

### Per Participant
- Perspective name
- Threats identified
- Severity rating
- Recommended mitigations

### Consolidated
- Critical vulnerabilities (immediate action)
- High-risk findings
- Compliance gaps
- Defense-in-depth recommendations
- Security posture assessment

### Structured Emission Example

```json
{
  "panel_name": "security-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.85,
  "risk_level": "low",
  "compliance_score": 0.92,
  "policy_flags": [],
  "requires_human_review": false,
  "timestamp": "2026-01-15T10:30:00Z",
  "findings": [
    {
      "persona": "Security Auditor",
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
      "persona": "Compliance Officer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    }
  ],
  "aggregate_verdict": "approve"
}
```

_Other participants (Adversarial Reviewer, Backend Engineer) omitted for brevity._

## Pass/Fail Criteria

This panel **passes** when all of the following are met:

| Criterion | Threshold | Blocked If |
|-----------|-----------|------------|
| Confidence score | >= 0.75 | Below 0.75 |
| Critical findings | 0 allowed | Any critical finding present |
| High findings | 0 allowed | Any high finding present |
| Aggregate verdict | approve | Block or abstain majority |
| Compliance score | >= 0.85 | Below 0.85 |

When blocked, the panel emits a `block` verdict with a structured explanation of which criterion failed. The PR comment includes the specific scores and finding counts.

Local overrides via `panels.local.json` can increase these thresholds (more restrictive) but never decrease them. See `governance/schemas/panels.schema.json` for the override format.

## Confidence Score Calculation

```
confidence = 0.90  (base)
           - (critical_findings x 0.30)
           - (high_findings x 0.20)
           - (medium_findings x 0.05)
           - (low_findings x 0.01)
           = max(confidence, 0.0)  (floor)
```

| Finding Severity | Deduction | Example: 1 finding |
|-----------------|-----------|-------------------|
| Critical | -0.30 | 0.90 -> 0.60 |
| High | -0.20 | 0.90 -> 0.70 |
| Medium | -0.05 | 0.90 -> 0.85 |
| Low | -0.01 | 0.90 -> 0.89 |

## Constraints
- Assume attacker capability
- Prioritize by exploitability and impact
- Require evidence for findings
- Provide specific remediation steps
