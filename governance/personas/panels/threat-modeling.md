# Panel: Threat Modeling

> **DEPRECATED:** This panel has been consolidated into `governance/prompts/reviews/threat-modeling.md`.
> The new format is a self-contained review prompt with inlined perspectives.
> This file will be removed in a future release.

## Purpose
Systematic threat analysis mapping attack surfaces to MITRE ATT&CK, identifying kill chains, and producing actionable detection and mitigation strategies.

## Participants
- **MITRE Specialist** - ATT&CK technique mapping, kill chain analysis, detection gaps
- **Security Auditor** - Vulnerability identification, exploit feasibility
- **Infrastructure Engineer** - Network boundaries, IAM policies, encryption posture
- **Adversarial Reviewer** - Attack vector creativity, hidden assumptions, invariant violations
- **Architect** - System boundaries, trust zones, data flow exposure

## Process
1. Define system scope, trust boundaries, and data flows
2. MITRE Specialist maps attack surface to ATT&CK tactics
3. Each participant identifies threats from their perspective
4. Build attack trees for high-value targets
5. Assess detection coverage per ATT&CK technique
6. Prioritize by likelihood and impact
7. Produce mitigation and detection recommendations

## Output Format

> **Schema:** All emissions must conform to [`panel-output.schema.json`](../../schemas/panel-output.schema.json). Wrap the JSON block in `<!-- STRUCTURED_EMISSION_START -->` and `<!-- STRUCTURED_EMISSION_END -->` markers.

### Per Participant
- Perspective name
- Threats identified with ATT&CK technique IDs (where applicable)
- Severity and likelihood rating
- Recommended mitigations or detections

### Consolidated
- Threat model summary with ATT&CK mapping
- Kill chain analysis for top threat scenarios
- Detection gap matrix
- Prioritized mitigation roadmap
- Residual risk assessment

### Structured Emission Example

```json
{
  "panel_name": "threat-modeling",
  "panel_version": "1.0.0",
  "confidence_score": 0.85,
  "risk_level": "low",
  "compliance_score": 0.92,
  "policy_flags": [],
  "requires_human_review": false,
  "timestamp": "2026-01-15T10:30:00Z",
  "findings": [
    {
      "persona": "MITRE Specialist",
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
      "persona": "Infrastructure Engineer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    }
  ],
  "aggregate_verdict": "approve"
}
```

_Other participants (Adversarial Reviewer, Architect) omitted for brevity._

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
- Every threat must reference a specific ATT&CK technique where one exists
- Distinguish between prevention controls and detection controls
- Prioritize by adversary capability and asset value
- Provide actionable detection rules, not just risk descriptions
