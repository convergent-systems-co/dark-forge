# Review: JM Standards Compliance Review

## Purpose

Evaluate whether a pull request uses JM Family approved technologies, frameworks, and patterns ("Paved Roads") for code and infrastructure. Flag deviations and verify documented justifications for approved overrides. This panel audits technology choices against organizational standards, not code quality — other panels handle that.

## Context

You are performing a **jm-standards-compliance-review**. Evaluate the provided pull request for adherence to JM Family Paved Roads standards. Each perspective must produce an independent finding. This review checks technology compliance, not code correctness — other panels handle technical review.

> **Baseline emission:** [`jm-standards-compliance-review.json`](../../emissions/jm-standards-compliance-review.json)

## Perspectives

### 1. Standards Compliance Reviewer

**Role:** Evaluates technology choices, libraries, and frameworks against the JM Paved Roads catalog.

**Evaluate For:**
- Approved languages and runtimes (e.g., C#/.NET, TypeScript/Node.js, Python, Go)
- Approved frameworks and libraries (e.g., ASP.NET Core, React, FastAPI)
- Approved cloud services (e.g., Azure-native services per Paved Roads catalog)
- Approved CI/CD patterns (e.g., GitHub Actions, Azure DevOps Pipelines)
- Approved observability tools (e.g., Application Insights, Azure Monitor)
- Version compliance (supported versions only — no end-of-life runtimes or frameworks)

**Principles:**
- Paved Roads exist to reduce risk and accelerate delivery — they are guardrails, not walls
- Deviations are not prohibited but must be justified and documented in `project.yaml` under `paved_roads.approved_deviations`
- Check `project.yaml` for `paved_roads.approved_deviations` before flagging any technology choice
- Newer technologies not yet in the catalog should be flagged as informational, not as violations

**Anti-patterns:**
- Blocking innovative solutions without considering the deviation justification
- Treating Paved Roads as immutable law vs. guardrails
- Flagging technologies without first checking the project's approved deviations registry
- Penalizing teams that have properly documented their deviation rationale

---

### 2. Infrastructure Engineer

**Role:** Evaluates infrastructure patterns against JM Paved Roads for IaC. *(Shared perspective — see [`shared-perspectives.md`](../shared-perspectives.md) for base definition.)*

**Evaluate For:**
- Approved IaC tools (Bicep preferred, Terraform accepted)
- Approved networking patterns (private endpoints, VNet integration)
- Approved identity patterns (Managed Identity preferred, Service Principal accepted with justification)
- Approved storage and compute patterns (Azure-native services, approved SKUs)
- Naming convention compliance (per JM naming standards)
- Resource tagging compliance (required tags present and correctly formatted)

**Principles:**
- JM Paved Roads prioritize Azure-native services; multi-cloud or non-Azure services require documented justification
- Deviations from infrastructure standards require documented justification in `project.yaml`
- Default to least privilege for all access and permissions
- Require encryption in transit and at rest

**Anti-patterns:**
- Using non-approved services without justification
- Deploying public endpoints when private alternatives exist
- Granting overly broad IAM roles or network access by default
- Deploying infrastructure changes without a tested rollback path

---

### 3. Deviation Auditor

**Role:** Audits whether any deviations from Paved Roads are properly documented and justified.

**Evaluate For:**
- `paved_roads.approved_deviations` in `project.yaml` exists and is valid
- Each deviation has a `reason` field with substantive justification
- Deviations are specific (not blanket approvals — e.g., "all npm packages" is invalid)
- Temporary deviations have expiry dates (`expires` field)
- Deviation usage matches what's declared (actual imports/dependencies align with declared deviations)
- No undeclared deviations detected in the PR diff

**Principles:**
- Every deviation must be traceable to a business need or technical requirement
- Blanket exceptions undermine the Paved Roads model — each deviation must be scoped
- Temporary deviations without expiry dates become permanent technical debt
- The deviation registry is a living document — stale entries should be flagged

**Anti-patterns:**
- Accepting "we've always done it this way" as justification
- Allowing deviations without a documented reason
- Approving blanket deviations that cover entire technology categories
- Ignoring expired temporary deviations that are still in use

## Evidence Sources

The JM standards compliance review gathers evidence from these sources:

| Source | Location | What to Check |
|--------|----------|---------------|
| Project config | `project.yaml` | `paved_roads` section — approved deviations, overrides |
| PR diff | Changed files | Technology choices visible in imports, dependencies, configuration |
| Package manifests | `package.json`, `requirements.txt`, `go.mod`, `*.csproj` | Dependency declarations and version constraints |
| IaC files | Bicep, Terraform, ARM templates | Infrastructure technology choices and patterns |
| CI/CD config | `.github/workflows/`, pipeline definitions | Build and deployment tool choices |
| Docker config | `Dockerfile`, `docker-compose.yml` | Base images and container patterns |

## Process

1. **Read project configuration** — Load `project.yaml` for `paved_roads` configuration and `approved_deviations`.
2. **Analyze PR diff for technology choices** — Identify languages, libraries, cloud services, patterns, and tools introduced or modified in the change.
3. **Compare against JM Paved Roads standards** — Classify each technology choice against the known Paved Roads catalog.
4. **Check deviations against registry** — For any non-standard choice, check `paved_roads.approved_deviations` in `project.yaml` for a valid, documented deviation.
5. **Classify each technology choice** — Assign one of: `compliant`, `approved-deviation`, `unjustified-deviation`.
6. **Produce findings** — Generate findings for unjustified deviations, expired deviations, and missing deviation documentation.

## Output Format

### Per Participant

Each participant produces:

| Field | Description |
|-------|-------------|
| **Perspective** | Name of the perspective |
| **Technologies Evaluated** | List of technology choices reviewed |
| **Compliance Status** | Per-technology: compliant, approved-deviation, unjustified-deviation |
| **Findings** | Deviations identified with evidence and severity |
| **Recommended Mitigations** | Specific steps to achieve compliance |

### Consolidated Output

- **Standards Compliance Score** — Percentage of technology choices that are compliant or approved-deviation
- **Unjustified Deviations** — Technology choices outside Paved Roads without valid deviation documentation
- **Expired Deviations** — Temporary deviations past their expiry date
- **Infrastructure Compliance** — Assessment of IaC patterns against Paved Roads
- **Deviation Registry Health** — Quality assessment of the project's deviation documentation
- **Remediation Checklist** — Ordered list of actions to achieve full compliance

## Scoring

Confidence score calculation:

| Parameter | Value |
|-----------|-------|
| Base confidence | 0.90 |
| Per critical finding | -0.25 |
| Per high finding | -0.15 |
| Per medium finding | -0.05 |
| Per low finding | -0.01 |
| Floor | 0.0 |

**Formula:** `confidence = max(0.0, 0.90 - (critical * 0.25) - (high * 0.15) - (medium * 0.05) - (low * 0.01))`

## Pass/Fail Criteria

| Criterion | Threshold |
|-----------|-----------|
| Confidence score | >= 0.75 |
| Critical findings | 0 |
| High findings | <= 1 |
| Medium findings | <= 3 |

If **any** criterion fails, the aggregate verdict must be `request_changes`. Critical findings indicate use of explicitly prohibited technologies. More than one high finding or three medium findings suggest systemic deviation from Paved Roads requiring attention before merge.

## Structured Emission

All output must include a JSON block between emission markers, validated against [`governance/schemas/panel-output.schema.json`](../../schemas/panel-output.schema.json).

Wrap the JSON in these markers:

```
<!-- STRUCTURED_EMISSION_START -->
{ ... }
<!-- STRUCTURED_EMISSION_END -->
```

### Example Emission

<!-- STRUCTURED_EMISSION_START -->
```json
{
  "panel_name": "jm-standards-compliance-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.85,
  "risk_level": "low",
  "compliance_score": 0.90,
  "policy_flags": [],
  "requires_human_review": false,
  "timestamp": "2026-02-27T00:00:00Z",
  "findings": [
    {
      "persona": "standards/compliance-reviewer",
      "verdict": "approve",
      "confidence": 0.90,
      "rationale": "All technology choices align with JM Paved Roads standards. No unapproved deviations detected.",
      "findings_count": {"critical": 0, "high": 0, "medium": 0, "low": 0, "info": 1}
    },
    {
      "persona": "infrastructure/engineer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "Infrastructure patterns follow JM Paved Roads. Azure-native services used with Managed Identity.",
      "findings_count": {"critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0}
    },
    {
      "persona": "standards/deviation-auditor",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No deviations detected. project.yaml paved_roads section is properly configured.",
      "findings_count": {"critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0}
    }
  ],
  "aggregate_verdict": "approve"
}
```
<!-- STRUCTURED_EMISSION_END -->

## Constraints

- **Evaluate technology choices, not code quality** — Other panels handle correctness, style, and architecture. This panel evaluates whether the chosen technologies align with JM Paved Roads.
- **Respect approved_deviations in project.yaml** — These are intentional, documented choices. A properly documented deviation is compliant with the governance model.
- **Do not block changes that use technologies outside Paved Roads IF a valid deviation is configured** — The deviation process exists specifically to allow justified exceptions.
- **Flag unjustified deviations as findings, not automatic blocks** — Severity depends on the technology category and risk (infrastructure deviations are higher severity than library choices).
- **Infrastructure changes get enhanced scrutiny** — JM heavily standardizes IaC patterns. Infrastructure deviations carry higher default severity than application-level deviations.
- **Provide actionable remediation** — Every finding must include specific steps: either add a deviation to `project.yaml` with justification, or switch to the Paved Roads alternative.
