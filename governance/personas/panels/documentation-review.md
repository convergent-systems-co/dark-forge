# Panel: Documentation Review

> **DEPRECATED:** This panel has been consolidated into `governance/prompts/reviews/documentation-review.md`.
> The new format is a self-contained review prompt with inlined perspectives.
> This file will be removed in a future release.

## Purpose
Evaluate documentation completeness, accuracy, and usability.

## Participants
- **Documentation Reviewer** - Accuracy, completeness, structure
- **Documentation Writer** - Clarity, examples, task orientation
- **API Consumer** - Discoverability, onboarding experience
- **Mentor** - Learning progression, concept explanation
- **UX Engineer** - Developer ergonomics, cognitive load

## Process
1. Identify target audiences
2. Each participant evaluates from their perspective
3. Test documentation by following it
4. Identify gaps and inconsistencies
5. Prioritize improvements by user impact

## Output Format

> **Schema:** All emissions must conform to [`panel-output.schema.json`](../../schemas/panel-output.schema.json). Wrap the JSON block in `<!-- STRUCTURED_EMISSION_START -->` and `<!-- STRUCTURED_EMISSION_END -->` markers.

### Per Participant
- Perspective name
- Gaps identified
- Usability issues
- Suggested improvements

### Consolidated
- Critical missing documentation
- Accuracy issues requiring immediate fix
- Structure improvements
- Example additions needed
- Maintenance recommendations

### Structured Emission Example

```json
{
  "panel_name": "documentation-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.85,
  "risk_level": "low",
  "compliance_score": 0.92,
  "policy_flags": [],
  "requires_human_review": false,
  "timestamp": "2026-01-15T10:30:00Z",
  "findings": [
    {
      "persona": "Documentation Reviewer",
      "verdict": "approve",
      "confidence": 0.90,
      "rationale": "No significant issues found."
    },
    {
      "persona": "Documentation Writer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    },
    {
      "persona": "API Consumer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    }
  ],
  "aggregate_verdict": "approve"
}
```

_Other participants (Mentor, UX Engineer) omitted for brevity._

## Pass/Fail Criteria

This panel **passes** when all of the following are met:

| Criterion | Threshold | Blocked If |
|-----------|-----------|------------|
| Confidence score | >= 0.65 | Below 0.65 |
| Critical findings | 0 allowed | Any critical finding present |
| High findings | <= 3 | More than 3 high findings |
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
- Verify code examples actually work
- Test from newcomer perspective
- Ensure documentation matches current behavior
- Prioritize task completion over exhaustive reference
