# Panel: Testing Strategy Review

## Purpose
Evaluate test coverage, quality, and testing approach comprehensively.

## Participants
- **Test Engineer** - Coverage, isolation, determinism
- **Failure Engineer** - Failure scenario coverage, chaos testing
- **Performance Engineer** - Load testing, benchmarks
- **Security Auditor** - Security test coverage, penetration testing
- **Code Reviewer** - Test code quality, maintainability

## Process
1. Review current test portfolio
2. Each participant identifies gaps from their perspective
3. Assess test reliability and maintenance burden
4. Prioritize improvements by risk reduction

## Output Format
### Per Participant
- Perspective name
- Coverage gaps identified
- Quality concerns
- Recommended additions

### Consolidated
- Critical untested paths
- Flaky test risks
- Testing infrastructure needs
- Prioritized test backlog
- Confidence assessment (High/Medium/Low)

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
- Prefer integration tests for critical paths
- Balance coverage with maintenance cost
- Ensure tests document expected behavior
- Avoid testing implementation details
