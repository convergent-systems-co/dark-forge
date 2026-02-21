# Panel: Code Review

## Purpose
Comprehensive code evaluation from multiple engineering perspectives.

## Participants
- **Code Reviewer** - Correctness, edge cases, error handling
- **Security Auditor** - Vulnerabilities, input validation, secrets
- **Performance Engineer** - Complexity, allocations, bottlenecks
- **Test Engineer** - Testability, coverage gaps, mock quality
- **Refactor Specialist** - Structure, duplication, maintainability

## Process
1. Each participant reviews independently
2. Present findings with severity (Critical/High/Medium/Low)
3. Identify conflicting recommendations
4. Produce consolidated assessment

## Output Format
### Per Participant
- Perspective name
- Key concerns (bulleted)
- Risk level
- Suggested changes

### Consolidated
- Must-fix items
- Should-fix items
- Consider items
- Tradeoff summary
- Final recommendation (Approve/Request Changes/Reject)

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
- Focus on substantive issues, not style preferences
- Resolve conflicts explicitly with reasoning
- Provide concrete remediation for each issue
