# Panel: AI Expert Review

> **DEPRECATED:** This panel has been consolidated into `governance/prompts/reviews/ai-expert-review.md`.
> The new format is a self-contained review prompt with inlined perspectives.
> This file will be removed in a future release.

## Purpose

Evaluate changes to AI governance artifacts — personas, prompts, workflows, policies, and schemas — for their impact on AI agent behavior, prompt engineering quality, governance pipeline integrity, and AI safety. This panel is critical for repositories that drive AI agent behavior through configuration rather than application code.

## Participants

- **AI Safety Specialist** - Agent behavior predictability, guardrail integrity, context capacity risks, misuse potential
- **Prompt Engineer** - Prompt clarity, injection resistance, structured output reliability, instruction anchoring
- **Governance Architect** - Pipeline gate integrity, emission schema compliance, policy rule soundness, audit trail completeness

## Scope

This panel triggers when changes affect:
- Persona definitions (`governance/personas/`)
- Prompt templates and workflows (`governance/prompts/`)
- Policy profiles (`governance/policy/`)
- Validation schemas (`governance/schemas/`)
- Base instructions (`instructions/`, `instructions.md`)

## Process

1. Each participant reviews the change independently from their perspective
2. AI Safety Specialist evaluates agent behavior implications and guardrail preservation
3. Prompt Engineer evaluates instruction quality, injection vectors, and output determinism
4. Governance Architect evaluates pipeline integrity and policy consistency
5. Surface cross-cutting concerns (e.g., a prompt change that weakens a policy gate)
6. Produce consolidated assessment with severity-classified findings

## Evaluation Criteria

### AI Safety Specialist Evaluates For
- **Behavioral predictability**: Do changes create non-deterministic or unpredictable agent behavior?
- **Guardrail integrity**: Are context capacity limits, shutdown protocols, and hard stops preserved?
- **Scope containment**: Do persona changes expand authority beyond defined boundaries?
- **Misuse resistance**: Could changes be exploited to bypass governance gates?
- **Checkpoint safety**: Are checkpoint and recovery mechanisms maintained?
- **Anti-pattern introduction**: Do changes introduce patterns listed in persona anti-patterns?

### Prompt Engineer Evaluates For
- **Instruction clarity**: Are prompts unambiguous with concrete evaluation criteria?
- **Injection resistance**: Are prompt templates resistant to injection via user-controlled inputs (issue titles, PR bodies, commit messages)?
- **Output determinism**: Do prompts produce consistent structured output across runs?
- **Context efficiency**: Do prompts respect token budget constraints (Tier 0-3 loading)?
- **Instruction anchoring**: Are critical instructions anchored to survive context compaction?
- **Structured emission compliance**: Do workflow changes maintain the `STRUCTURED_EMISSION_START/END` marker protocol?

### Governance Architect Evaluates For
- **Gate integrity**: Are governance gates preserved (no shortcircuits or bypasses introduced)?
- **Policy consistency**: Do policy changes maintain internal consistency (weights sum to 1.0, thresholds are coherent)?
- **Schema compatibility**: Do schema changes maintain backward compatibility with existing emissions?
- **Audit trail completeness**: Are all decisions still captured in run manifests?
- **Panel orchestration**: Does the change affect which panels execute and under what conditions?
- **Merge decision determinism**: Are merge decisions still fully deterministic from structured data?

## Output Format

> **Schema:** All emissions must conform to [`panel-output.schema.json`](../../schemas/panel-output.schema.json). Wrap the JSON block in `<!-- STRUCTURED_EMISSION_START -->` and `<!-- STRUCTURED_EMISSION_END -->` markers.

### Per Participant
- Perspective name
- Findings with severity (Critical/High/Medium/Low/Info)
- Risk assessment specific to AI governance impact
- Recommended changes with rationale

### Consolidated
- Must-fix items (critical or high severity — blocks merge)
- Should-fix items (medium severity — may block merge)
- Consider items (low severity — advisory)
- AI safety impact summary
- Governance integrity assessment
- Final recommendation (Approve/Request Changes/Block)

### Structured Emission Example

```json
{
  "panel_name": "ai-expert-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.85,
  "risk_level": "low",
  "compliance_score": 0.92,
  "policy_flags": [],
  "requires_human_review": false,
  "timestamp": "2026-01-15T10:30:00Z",
  "findings": [
    {
      "persona": "AI Safety Specialist",
      "verdict": "approve",
      "confidence": 0.90,
      "rationale": "No significant issues found."
    },
    {
      "persona": "Prompt Engineer",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    },
    {
      "persona": "Governance Architect",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No significant issues found."
    }
  ],
  "aggregate_verdict": "approve"
}
```

## Structured Emission

Emits standard `panel-output.schema.json` output:

```json
{
  "panel_name": "ai-expert-review",
  "panel_version": "1.0.0",
  "confidence_score": 0.85,
  "risk_level": "low",
  "compliance_score": 0.90,
  "policy_flags": [],
  "requires_human_review": false,
  "timestamp": "ISO-8601",
  "findings": [
    {
      "persona": "ai-safety-specialist",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "No behavioral predictability concerns. Guardrails preserved.",
      "findings_count": { "critical": 0, "high": 0, "medium": 0, "low": 1, "info": 0 }
    },
    {
      "persona": "prompt-engineer",
      "verdict": "approve",
      "confidence": 0.90,
      "rationale": "Instructions clear and injection-resistant.",
      "findings_count": { "critical": 0, "high": 0, "medium": 0, "low": 0, "info": 1 }
    },
    {
      "persona": "governance-architect",
      "verdict": "approve",
      "confidence": 0.85,
      "rationale": "Pipeline gates intact. Policy consistency maintained.",
      "findings_count": { "critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0 }
    }
  ],
  "aggregate_verdict": "approve"
}
```

## Confidence Score Calculation

```
base_confidence = 0.85

Per finding deductions:
  critical  -> confidence -= 0.25 (agent behavior or safety compromise)
  high      -> confidence -= 0.15 (governance gate bypass or policy inconsistency)
  medium    -> confidence -= 0.05 (reduced determinism or missing coverage)
  low       -> confidence -= 0.01 (advisory improvement)
  info      -> no change

confidence = max(0.0, base_confidence - deductions)
```

## Severity Classification

| Pattern | Severity | Description |
|---------|----------|-------------|
| Governance gate bypass, shutdown protocol removal, unbounded agent authority | `critical` | Direct compromise of governance pipeline safety |
| Prompt injection vector, non-deterministic merge decision, policy weight inconsistency | `high` | Material risk to governance integrity |
| Missing anti-pattern, unclear instruction, context budget exceeded | `medium` | Reduced governance quality or efficiency |
| Style improvement, additional guard, minor clarity enhancement | `low` | Advisory improvement suggestion |
| Alternative approach, context for reviewers | `info` | Informational, no action required |

## Constraints

- Evaluate AI governance impact, not general code quality (defer to code-review panel)
- Every finding must identify the specific governance risk, not just the code change
- Distinguish between agent-behavior changes and documentation-only changes
- Prompt injection analysis must consider all user-controlled inputs that feed into prompts
- Policy consistency checks must verify mathematical properties (weight sums, threshold ordering)
- Never approve changes that weaken the 80% context capacity shutdown protocol
