# Panel: Incident Post-Mortem

## Purpose
Analyze incident for root cause and systemic improvements.

## Participants
- **Incident Commander** - Timeline accuracy, response effectiveness
- **SRE** - Detection gaps, SLO impact, operational failures
- **Systems Architect** - Architectural contributing factors
- **Failure Engineer** - Resilience gaps, recovery effectiveness
- **Observability Engineer** - Monitoring blind spots, alert quality

## Process
1. Reconstruct incident timeline
2. Each participant analyzes from their perspective
3. Identify contributing factors (not blame)
4. Distinguish symptoms from root causes
5. Prioritize preventive actions

## Output Format
### Per Participant
- Perspective name
- Contributing factors identified
- Gaps in their domain
- Recommended improvements

### Consolidated
- Incident summary
- Root cause(s)
- Contributing factors
- What went well
- Action items with owners and deadlines
- Systemic improvements needed

## Pass/Fail Criteria

This panel **passes** when all of the following are met:

| Criterion | Threshold | Blocked If |
|-----------|-----------|------------|
| Confidence score | >= 0.70 | Below 0.70 |
| Critical findings | 0 allowed | Any critical finding present |
| High findings | <= 2 | More than 2 high findings |
| Aggregate verdict | approve | Block or abstain majority |
| Compliance score | >= 0.70 | Below 0.70 |

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
- Focus on systems, not individuals
- Seek multiple contributing factors
- Prioritize prevention over detection
- Ensure actions are specific and measurable
