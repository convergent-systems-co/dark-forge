# Panel: Copilot Review

## Purpose

Integrates GitHub Copilot as a formal review panel within the Dark Factory governance pipeline. Copilot feedback is parsed, classified, and emitted as structured output compatible with the policy engine.

## Role

GitHub Copilot serves as an automated first-pass reviewer. Its suggestions are consumed as input signals alongside persona-based panel reviews. Copilot does not have veto authority but contributes to the aggregate confidence score.

## Integration Model

```
PR Created/Updated
       |
       v
GitHub Copilot Review (automatic)
       |
       v
Parse Copilot Comments
       |
       v
Classify by Severity
       |
       v
Emit Structured Output (panel-output.schema.json)
       |
       v
Feed into Policy Engine
```

## Feedback Parsing

Copilot feedback is consumed from the GitHub API via:

```
GET /repos/{owner}/{repo}/pulls/{pr_number}/comments
```

Filter for comments where `user.login` matches the Copilot bot account.

### Classification Rules

Each Copilot comment is classified into a severity level:

| Pattern | Severity | Description |
|---------|----------|-------------|
| Security vulnerability, injection, authentication bypass | `critical` | Direct security risk identified. |
| Bug, incorrect logic, null reference, race condition | `high` | Functional correctness issue. |
| Performance concern, unnecessary allocation, N+1 query | `medium` | Non-blocking but material concern. |
| Style, naming, readability, minor refactor suggestion | `low` | Code quality improvement suggestion. |
| Question, clarification, alternative approach | `info` | Informational only, no action required. |

Classification is performed by keyword matching and context analysis. The classification model is deterministic: identical comments always produce identical severity ratings.

## Structured Output Schema

Copilot review emits a standard `panel-output.schema.json` artifact:

```json
{
  "panel_name": "copilot-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.75,
  "risk_level": "low",
  "compliance_score": 0.90,
  "policy_flags": [],
  "requires_human_review": false,
  "timestamp": "2026-02-20T12:00:00Z",
  "findings": [
    {
      "persona": "copilot",
      "verdict": "approve",
      "confidence": 0.75,
      "rationale": "3 suggestions: 0 critical, 0 high, 1 medium, 2 low.",
      "findings_count": {
        "critical": 0,
        "high": 0,
        "medium": 1,
        "low": 2,
        "info": 0
      }
    }
  ],
  "aggregate_verdict": "approve"
}
```

## Failure Conditions

| Condition | Behavior |
|-----------|----------|
| Copilot review not triggered | Panel output omitted. Policy engine uses `missing_panel_behavior` from the active profile. |
| Copilot API unavailable | Retry 3 times with exponential backoff. If all retries fail, emit panel output with `confidence_score: 0.0` and `requires_human_review: true`. |
| Copilot comments unparseable | Log raw comments, emit panel output with `confidence_score: 0.0`, flag `copilot_parse_failure`. |
| Copilot review still pending | Wait up to 10 minutes. If not completed, proceed without Copilot panel. |

## Severity Mapping

Copilot severity maps to policy engine risk levels:

| Copilot Findings | Risk Level | Policy Impact |
|------------------|------------|---------------|
| Any `critical` finding | `critical` | Escalation to human review. |
| 2+ `high` findings | `high` | Escalation to human review. |
| 1 `high` finding | `medium` | Contributes to aggregate risk. |
| Only `medium` or below | `low` | Normal processing. |
| Only `low` or `info` | `negligible` | Minimal impact on aggregate. |

## Confidence Score Calculation

```
base_confidence = 0.80

For each finding:
  critical  -> confidence -= 0.25
  high      -> confidence -= 0.15
  medium    -> confidence -= 0.05
  low       -> confidence -= 0.01
  info      -> no change

confidence = max(0.0, base_confidence - deductions)
```

## GitHub Branch Protection Compatibility

The Copilot review panel integrates with GitHub branch protection via:

1. **Required status check**: `dark-factory / copilot-review`
2. **Pass criteria**: Panel emitted with `aggregate_verdict != "block"`
3. **Bypass**: If Copilot is unavailable and profile sets `missing_panel_behavior: redistribute`, the status check passes with a warning annotation.

## Limitations

- Copilot suggestions are heuristic, not deterministic across model versions.
- Confidence scores from Copilot are lower-weighted in policy profiles to account for this.
- Copilot does not have access to full project context (personas, governance rules).
- The panel treats Copilot as one signal among many, not as a decision authority.
