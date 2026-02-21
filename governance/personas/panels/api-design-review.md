# Panel: API Design Review

## Purpose
Evaluate API design from provider and consumer perspectives.

## Participants
- **API Designer** - REST correctness, versioning, contracts
- **API Consumer** - Usability, documentation, error messages
- **Security Auditor** - Auth, rate limiting, input validation
- **Backend Engineer** - Implementation feasibility, performance
- **Frontend Engineer** - Client integration, caching, offline support

## Process
1. Review API contract and documentation
2. Each participant evaluates from their perspective
3. Identify breaking change risks
4. Test typical consumer workflows
5. Converge on design improvements

## Output Format
### Per Participant
- Perspective name
- Design concerns
- Usability issues
- Suggested changes

### Consolidated
- Contract issues requiring change
- Breaking change risks
- Documentation gaps
- Implementation concerns
- Versioning recommendations

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
- Prioritize backward compatibility
- Consider multiple client types
- Ensure consistent error semantics
- Design for evolution
