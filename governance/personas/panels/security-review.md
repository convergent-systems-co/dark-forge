# Panel: Security Review

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
