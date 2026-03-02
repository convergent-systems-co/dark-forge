# Review: Testing Review

## Purpose

Evaluate test coverage, quality, and testing approach comprehensively. This panel assesses the adequacy of the test portfolio, identifies gaps in coverage, and evaluates the reliability and maintainability of existing tests.

## Context

You are performing a testing-review. Evaluate the provided code change from multiple perspectives. Each perspective must produce an independent finding.

> **Shared perspectives:** Test Engineer, Failure Engineer, Performance Engineer, Security Auditor, Code Reviewer are defined in [`shared-perspectives.md`](../shared-perspectives.md).
> **Baseline emission:** [`testing-review.json`](../../emissions/testing-review.json)

## Perspectives

### Test Engineer

See [`shared-perspectives.md`](../shared-perspectives.md) for the canonical definition.

### Failure Engineer

See [`shared-perspectives.md`](../shared-perspectives.md) for the canonical definition.

### Performance Engineer

See [`shared-perspectives.md`](../shared-perspectives.md) for the canonical definition.

### Security Auditor

See [`shared-perspectives.md`](../shared-perspectives.md) for the canonical definition.

### Code Reviewer

See [`shared-perspectives.md`](../shared-perspectives.md) for the canonical definition.

## Process

1. Review the current test portfolio and its relationship to the code change
2. Each participant identifies coverage gaps from their perspective
3. Assess test reliability and maintenance burden
4. Prioritize improvements by risk reduction impact

## Output Format

> **Schema:** All emissions must conform to [`panel-output.schema.json`](../../schemas/panel-output.schema.json). Wrap the JSON block in `<!-- STRUCTURED_EMISSION_START -->` and `<!-- STRUCTURED_EMISSION_END -->` markers.

### Per Participant

- Perspective name
- Coverage gaps identified
- Quality concerns (flakiness, determinism, isolation)
- Recommended test additions

### Consolidated

- Critical untested paths (code paths that lack any test coverage and handle critical logic)
- Flaky test risks (tests that are non-deterministic or environment-dependent)
- Testing infrastructure needs (tooling, fixtures, CI configuration)
- Prioritized test backlog (ordered by risk reduction impact)
- Confidence assessment (overall confidence in the test portfolio's ability to catch regressions)

### Structured Emission Example

```json
<!-- STRUCTURED_EMISSION_START -->
{
  "panel_name": "testing-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.75,
  "risk_level": "medium",
  "compliance_score": 0.80,
  "policy_flags": [
    {
      "flag": "missing_integration_tests",
      "severity": "high",
      "description": "Payment processing flow has no integration tests covering the full request lifecycle.",
      "remediation": "Add integration tests that exercise the payment flow from API entry to database persistence.",
      "auto_remediable": false
    }
  ],
  "requires_human_review": false,
  "timestamp": "2026-02-25T12:00:00Z",
  "findings": [
    {
      "persona": "engineering/test-engineer",
      "verdict": "request_changes",
      "confidence": 0.80,
      "rationale": "Unit coverage for new PaymentService methods is incomplete. Error handling paths and boundary conditions lack tests.",
      "findings_count": { "critical": 0, "high": 1, "medium": 2, "low": 0, "info": 0 }
    },
    {
      "persona": "operations/failure-engineer",
      "verdict": "request_changes",
      "confidence": 0.70,
      "rationale": "No tests cover partial failure scenarios such as network timeout during payment confirmation or database write failure after external charge.",
      "findings_count": { "critical": 0, "high": 1, "medium": 1, "low": 0, "info": 0 }
    },
    {
      "persona": "engineering/performance-engineer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No load or benchmark tests exist for this path, but current volume does not warrant them. Recommend adding if traffic increases.",
      "findings_count": { "critical": 0, "high": 0, "medium": 0, "low": 1, "info": 0 }
    },
    {
      "persona": "compliance/security-auditor",
      "verdict": "approve",
      "confidence": 0.80,
      "rationale": "Security-relevant input validation has corresponding test coverage. Auth bypass scenarios are tested.",
      "findings_count": { "critical": 0, "high": 0, "medium": 0, "low": 0, "info": 1 }
    },
    {
      "persona": "quality/code-reviewer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "Test code is well-structured with clear assertions. Test naming conventions are consistent. No over-mocking detected.",
      "findings_count": { "critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0 }
    }
  ],
  "aggregate_verdict": "request_changes"
}
<!-- STRUCTURED_EMISSION_END -->
```

## Pass/Fail Criteria

| Criterion | Threshold |
|---|---|
| Confidence score | >= 0.70 |
| Critical findings | 0 |
| High findings | <= 2 |
| Aggregate verdict | approve |
| Compliance score | >= 0.70 |

## Confidence Score Calculation

**Formula:** `final = base - sum(severity_penalties)`

| Severity | Penalty per finding |
|---|---|
| Base | 0.85 |
| Critical | -0.25 |
| High | -0.15 |
| Medium | -0.05 |
| Low | -0.01 |

The confidence score is floored at 0.0 and capped at 1.0. Each finding's severity contributes its penalty once. If multiple perspectives flag the same gap, count it once at the highest severity.

## Execution Trace

To provide evidence of actual code evaluation, include an `execution_trace` object in your structured emission:

- **`files_read`** (required) — List every file you read during this review. Include the full relative path for each file (e.g., `src/auth/login.ts`, `infrastructure/main.bicep`). Do not omit files — this is the audit record of what was actually evaluated.
- **`diff_lines_analyzed`** — Count the total number of diff lines (added + removed + modified) you analyzed.
- **`analysis_duration_ms`** — Approximate wall-clock time spent on the analysis in milliseconds.
- **`grounding_references`** — For each finding, link it to a specific code location. Each entry must include `file` (file path) and `finding_id` (matching the finding's persona or a unique identifier). Include `line` (line number) when the finding maps to a specific line.

The `execution_trace` field is optional in the schema but **strongly recommended** for auditability. When present, it provides verifiable evidence that the panel agent actually read and analyzed the code rather than producing a generic assessment.

## Grounding Requirement

**Grounding Requirement**: Every finding with severity 'medium' or above MUST include an `evidence` block containing the file path, line range, and a code snippet (max 200 chars) from the actual code. Findings without evidence may be treated as hallucinated and discarded. If the review produces zero findings, you must still demonstrate analysis by populating `execution_trace.grounding_references` with at least one file+line reference showing what was examined.

## Constraints

- Prefer integration tests for critical paths over unit tests with heavy mocking
- Balance coverage breadth with maintenance cost -- do not recommend tests that cost more to maintain than the risk they mitigate
- Tests document expected behavior -- assess whether existing tests serve as reliable specifications
- Avoid recommending tests that are tightly coupled to implementation details
- Identify flaky tests and recommend root-cause fixes, not retries or skips
- Every coverage gap finding must include a specific test scenario recommendation
