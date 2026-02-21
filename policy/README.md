# Policy Engine Framework

Policy profiles define deterministic rules for merge decisions. The policy engine evaluates structured panel emissions against these rules to produce one of four outcomes:

| Decision | Description |
|----------|-------------|
| `auto_merge` | All thresholds satisfied. Merge proceeds without human intervention. |
| `auto_remediate` | Issues detected but automatically fixable. Remediation attempted before re-evaluation. |
| `human_review_required` | Confidence, risk, or policy flags require human judgment. |
| `block` | Hard block. Merge cannot proceed without enterprise override. |

## Available Profiles

| Profile | File | Use When |
|---------|------|----------|
| Default | `default.yaml` | Standard internal repositories with moderate risk tolerance. |
| Financial PII High | `fin_pii_high.yaml` | Repositories handling financial data, PII, or regulated information (SOC2, PCI-DSS, HIPAA, GDPR). |
| Infrastructure Critical | `infrastructure_critical.yaml` | Infrastructure-as-code, CI/CD, deployment configs, platform services. |

## Profile Structure

Every policy profile defines:

1. **Weighting Model** - How panel confidence scores are aggregated.
2. **Risk Aggregation** - How individual risk assessments combine into a final risk level.
3. **Escalation Rules** - Conditions that trigger human review or block.
4. **Auto-merge Rules** - Conditions permitting automated merge.
5. **Auto-remediate Rules** - Conditions permitting automated fix attempts.
6. **Block Rules** - Hard stops that prevent merge.
7. **Override Rules** - Enterprise override procedure with audit requirements.
8. **Required Panels** - Panels that must execute for a valid decision.
9. **Optional Panels** - Panels triggered by change characteristics.

## Creating a New Profile

1. Copy `default.yaml` as a starting point.
2. Adjust thresholds, weights, and rules for your risk context.
3. Set `profile_name` and `profile_version`.
4. Reference the profile in your project's `project.yaml`:

```yaml
governance:
  policy_profile: fin_pii_high
```

## Design Principles

- **Deterministic**: Policy evaluation must produce the same result given the same inputs. No prose interpretation.
- **Auditable**: Every rule evaluation is logged in the run manifest.
- **Composable**: Profiles can be extended by overriding specific sections.
- **Backward Compatible**: New rules must not break existing profiles. Use additive changes only.
