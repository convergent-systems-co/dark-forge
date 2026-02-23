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

Copilot feedback is consumed from the GitHub API via **three disjoint endpoints**. All three must be checked — Copilot distributes comments across them depending on the type of feedback.

### Comment Endpoints

| Endpoint | API Path | What It Contains |
|----------|----------|-----------------|
| Inline code comments | `GET /repos/{owner}/{repo}/pulls/{pr_number}/comments` | Line-level suggestions, review thread comments |
| PR reviews | `GET /repos/{owner}/{repo}/pulls/{pr_number}/reviews` | Top-level review summaries, approve/request-changes |
| Issue-level comments | `GET /repos/{owner}/{repo}/issues/{pr_number}/comments` | General PR comments, some bot integrations |

### Bot Identity Table

Known Copilot-related `user.login` values and their characteristics:

| `user.login` | `user.type` | Endpoint(s) | Notes |
|--------------|-------------|-------------|-------|
| `copilot-pull-request-reviewer` | `Bot` | Inline, Reviews | Primary Copilot code review bot |
| `github-advanced-security` | `Bot` | Inline, Issue | Security scanning results |
| `copilot` | `Bot` | Any | Standalone name — must be anchored (`^copilot$`) to avoid false matches |
| `github-copilot` | `Bot` | Any | Future-proofing for potential rebranding |

The jq filter combines username regex matching with a user-type secondary check for defense in depth:

```
select(
  (.user.login | test("^copilot$|copilot-pull-request-reviewer|github-advanced-security|github-copilot"; "i"))
  or ((.user.type == "Bot" or (.user.login | test("\\[bot\\]$"))) and (.user.login | test("copilot"; "i")))
)
```

### Diagnostic Pre-Fetch Requirement

Before running filtered queries, the agent must fetch **unfiltered** comment counts from all three endpoints. If any filtered result is empty but its unfiltered count is non-zero, the agent must emit a **filter-mismatch warning** and manually inspect the unfiltered results for bot comments with unexpected `user.login` values. This catches filter regressions caused by GitHub changing bot account names.

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
| Filter returns empty despite comments existing | Diagnostic pre-fetch detected non-zero unfiltered count but zero filtered results. Agent must inspect unfiltered comments, update filter if needed, and log the mismatch. Do not proceed to merge until resolved. |

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
