# Review: API Design Review

## Purpose

Evaluate API design from both provider and consumer perspectives. This panel assesses REST correctness, contract stability, security posture, implementation feasibility, and client integration experience to produce a comprehensive evaluation of the API surface before it is exposed to consumers.

## Context

You are performing an api-design-review. Evaluate the provided API design from multiple perspectives. Each perspective must produce an independent finding assessing the API in its domain. The goal is to catch contract issues, breaking change risks, and usability problems before consumers depend on the interface.

> **Shared perspectives:** API Designer, API Consumer, Security Auditor, Backend Engineer, and Frontend Engineer are defined in [`shared-perspectives.md`](../shared-perspectives.md).
> **Baseline emission:** [`api-design-review.json`](../../emissions/api-design-review.json)

## Perspectives

### API Designer

**Focus:** REST correctness, idempotent verbs, error semantics, versioning strategy, contract stability.

Full definition in [`shared-perspectives.md`](../shared-perspectives.md).

### API Consumer

**Focus:** Documentation clarity, authentication complexity, error message usefulness, SDK quality, rate limit transparency.

Full definition in [`shared-perspectives.md`](../shared-perspectives.md).

### Security Auditor

**Focus:** Authentication and authorization model, rate limiting, input validation, injection vectors.

Full definition in [`shared-perspectives.md`](../shared-perspectives.md).

### Backend Engineer

**Focus:** Implementation feasibility, database access patterns, caching strategy, performance characteristics.

Full definition in [`shared-perspectives.md`](../shared-perspectives.md).

### Frontend Engineer

**Focus:** Client integration patterns, caching and offline support, bundle size impact, rendering performance.

Full definition in [`shared-perspectives.md`](../shared-perspectives.md).

## Process

1. **Review API contract and documentation** -- Examine the OpenAPI/Swagger specification, endpoint definitions, request/response schemas, error codes, authentication requirements, and versioning strategy. Understand the intended consumer experience.
2. **Each participant evaluates independently** -- Every perspective analyzes the API through its own lens, producing findings without influence from other perspectives.
3. **Identify breaking change risks** -- Catalog any design decisions that could become breaking changes if modified later. Assess whether the current design locks in assumptions that will be costly to reverse.
4. **Test typical consumer workflows** -- Walk through common consumer use cases end-to-end. Verify that the API supports these workflows without unnecessary complexity, excessive round trips, or ambiguous behavior.
5. **Converge on design improvements** -- Synthesize individual findings into a unified set of recommendations, prioritizing changes that improve consumer experience, security, and long-term evolvability.

## Output Format

> **Schema:** All emissions must conform to [`panel-output.schema.json`](../../schemas/panel-output.schema.json). Wrap the JSON block in `<!-- STRUCTURED_EMISSION_START -->` and `<!-- STRUCTURED_EMISSION_END -->` markers.

### Per Participant

- Perspective name and role
- Design concerns identified (with evidence from the API contract)
- Usability issues (from the perspective's vantage point)
- Suggested changes (concrete and actionable)

### Consolidated

- Contract issues requiring change (before the API is published)
- Breaking change risks (design decisions that are costly to reverse)
- Documentation gaps (missing examples, unclear error codes, ambiguous behavior)
- Implementation concerns (performance, scalability, feasibility)
- Versioning recommendations (strategy for evolving the API)

### Structured Emission Example

```json
{
  "panel_name": "api-design-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.80,
  "risk_level": "medium",
  "compliance_score": 0.78,
  "policy_flags": [
    {
      "flag": "inconsistent_error_format",
      "severity": "high",
      "description": "Validation errors return a flat string message while authorization errors return a structured error object. Consumers cannot parse errors consistently.",
      "remediation": "Adopt a single error envelope format (e.g., RFC 7807 Problem Details) across all error responses.",
      "auto_remediable": false
    },
    {
      "flag": "missing_rate_limit_headers",
      "severity": "medium",
      "description": "Rate limiting is enforced but no X-RateLimit-* headers are returned, preventing clients from implementing proactive throttling.",
      "remediation": "Add X-RateLimit-Limit, X-RateLimit-Remaining, and X-RateLimit-Reset headers to all responses.",
      "auto_remediable": true
    }
  ],
  "requires_human_review": false,
  "timestamp": "2026-02-25T12:00:00Z",
  "findings": [
    {
      "persona": "architecture/api-designer",
      "verdict": "request_changes",
      "confidence": 0.85,
      "rationale": "POST /orders is not idempotent but lacks an idempotency key mechanism. Error response format is inconsistent across endpoints. Versioning is via URL path but no deprecation policy is documented.",
      "findings_count": { "critical": 0, "high": 1, "medium": 2, "low": 0, "info": 0 }
    },
    {
      "persona": "specialist/api-consumer",
      "verdict": "request_changes",
      "confidence": 0.80,
      "rationale": "Authentication requires three separate API calls before the first data request. Error messages do not include a machine-readable code for programmatic handling. No sandbox environment is documented.",
      "findings_count": { "critical": 0, "high": 1, "medium": 1, "low": 1, "info": 0 }
    },
    {
      "persona": "compliance/security-auditor",
      "verdict": "approve",
      "confidence": 0.88,
      "rationale": "OAuth 2.0 with PKCE is used for authentication. Input validation is present on all endpoints. Rate limiting is enforced. No PII is exposed in URLs or logs.",
      "findings_count": { "critical": 0, "high": 0, "medium": 1, "low": 0, "info": 1 }
    },
    {
      "persona": "domain/backend-engineer",
      "verdict": "approve",
      "confidence": 0.82,
      "rationale": "Pagination uses cursor-based approach which scales well. List endpoints support field filtering to reduce payload size. Bulk operations endpoint limits batch size to 100, which is within database transaction limits.",
      "findings_count": { "critical": 0, "high": 0, "medium": 0, "low": 1, "info": 1 }
    },
    {
      "persona": "domain/frontend-engineer",
      "verdict": "approve",
      "confidence": 0.78,
      "rationale": "JSON responses are well-structured for client-side rendering. Cache-Control headers are present on GET endpoints. However, no ETag support exists for conditional requests, and webhook payloads lack a schema reference for client-side validation.",
      "findings_count": { "critical": 0, "high": 0, "medium": 2, "low": 0, "info": 0 }
    }
  ],
  "aggregate_verdict": "request_changes",
  "execution_context": {
    "repository": "org/api-service",
    "branch": "feat/v2-api-design",
    "commit_sha": "abc123def456abc123def456abc123def456abc1",
    "policy_profile": "default",
    "triggered_by": "manual"
  }
}
```

## Pass/Fail Criteria

| Criterion | Threshold | Action on Failure |
|---|---|---|
| Confidence score | >= 0.70 | Request human review |
| Critical findings | 0 | Block API publication |
| High findings | <= 2 | Request changes if exceeded |
| Aggregate verdict | `approve` | Block publication if `block` or `request_changes` |
| Compliance score | >= 0.70 | Escalate to security review |

## Confidence Score Calculation

**Formula:** `final = base - sum(severity_penalties)`

| Parameter | Value |
|-----------|-------|
| Base confidence | 0.85 |
| Per critical finding | -0.25 |
| Per high finding | -0.15 |
| Per medium finding | -0.05 |
| Per low finding | -0.01 |
| Floor | 0.0 |
| Cap | 1.0 |

## Execution Trace

To provide evidence of actual code evaluation, include an `execution_trace` object in your structured emission:

- **`files_read`** (required) — List every file you read during this review. Include the full relative path for each file (e.g., `src/auth/login.ts`, `infrastructure/main.bicep`). Do not omit files — this is the audit record of what was actually evaluated.
- **`diff_lines_analyzed`** — Count the total number of diff lines (added + removed + modified) you analyzed.
- **`analysis_duration_ms`** — Approximate wall-clock time spent on the analysis in milliseconds.
- **`grounding_references`** — For each finding, link it to a specific code location. Each entry must include `file` (file path) and `finding_id` (matching the finding's persona or a unique identifier). Include `line` (line number) when the finding maps to a specific line.

The `execution_trace` field is optional in the schema but **strongly recommended** for auditability. When present, it provides verifiable evidence that the panel agent actually read and analyzed the code rather than producing a generic assessment.

## Grounding Requirement

**Grounding Requirement**: Every finding with severity 'medium' or above MUST include an `evidence` block containing the file path, line range, and a code snippet (max 200 chars) from the actual code. Findings without evidence may be treated as hallucinated and discarded. If the review produces zero findings, you must still demonstrate analysis by populating `execution_trace.grounding_references` with at least one file+line reference showing what was examined.

Each finding's severity contributes its penalty once. If multiple perspectives flag the same issue, count it once at the highest severity. The score is floored at 0.0 and capped at 1.0.
## Constraints

- Prioritize backward compatibility in all design recommendations. Breaking changes should be a last resort with a documented migration path for existing consumers.
- Consider multiple client types (web, mobile, server-to-server, CLI) when evaluating the API surface. An API that works well for one client type but poorly for others needs revision.
- Ensure consistent error semantics across all endpoints. Consumers should be able to write a single error-handling path that works regardless of which endpoint returned the error.
- Design for evolution. Every contract decision should be evaluated for how it constrains future changes. Prefer designs that leave room for additive extension.
