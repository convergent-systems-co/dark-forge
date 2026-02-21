# Panel: Performance Review

## Purpose
Comprehensive performance analysis from multiple perspectives.

## Participants
- **Performance Engineer** - Algorithms, hot paths, profiling
- **Backend Engineer** - Database queries, caching, async patterns
- **Frontend Engineer** - Rendering, bundle size, perceived performance
- **Infrastructure Engineer** - Resource allocation, scaling limits
- **SRE** - Production metrics, capacity planning

## Process
1. Review performance requirements and SLOs
2. Analyze current metrics and bottlenecks
3. Each participant identifies issues from their perspective
4. Prioritize by user impact
5. Define measurement strategy

## Output Format
### Per Participant
- Perspective name
- Bottlenecks identified
- Optimization opportunities
- Measurement recommendations

### Consolidated
- Critical performance issues
- Quick wins
- Longer-term optimizations
- Capacity risks
- Performance testing recommendations

## Pass/Fail Criteria

This panel **passes** when all of the following are met:

| Criterion | Threshold | Blocked If |
|-----------|-----------|------------|
| Confidence score | >= 0.65 | Below 0.65 |
| Critical findings | 0 allowed | Any critical finding present |
| High findings | <= 2 | More than 2 high findings |
| Aggregate verdict | approve | Block or abstain majority |
| Compliance score | >= 0.65 | Below 0.65 |

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
- Measure before optimizing
- Focus on user-perceived performance
- Consider cost of optimization
- Require benchmarks for changes
