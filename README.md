# .ai — Dark Factory Governance Platform

AI governance framework for autonomous software delivery. Provides personas, panels, policy enforcement, structured emissions, and audit manifests — distributed as a git submodule to any repository.

## Governance Maturity Model

| Phase | Name | Description | Status |
|-------|------|-------------|--------|
| 3 | Agentic Orchestration | Personas, panels, workflows with human gates | Implemented |
| 4a | Policy-Bound Autonomy | Deterministic merge decisions, structured emissions | **Current** |
| 4b | Autonomous Remediation | Auto-fix, drift detection, remediation loops | Designed |
| 5 | Dark Factory | Full automation with runtime feedback and self-evolution | Architecture defined |

## Repository Structure

```
.ai/
  instructions.md              Base AI instructions (< 200 tokens, Tier 0)
  config.yaml                  Symlink and sync configuration

  personas/                    AI persona definitions (Markdown)
    architecture/              System design (3 personas)
    quality/                   Code review (3 personas)
    compliance/                Security, regulatory, accessibility (3 personas)
    documentation/             Content creation and review (2 personas)
    domain/                    Frontend, backend, data, ML, mobile (5 personas)
    engineering/               Testing, performance, debugging (6 personas)
    operations/                SRE, DevOps, infrastructure (6 personas)
    leadership/                Technical leadership, product, mentoring (4 personas)
    specialist/                Legacy, incidents, migrations (4 personas)
    governance/                Governance Auditor, Policy Evaluator (2 personas)
    agentic/                   Code Manager, Coder (2 personas)
    panels/                    Multi-persona review panels (13 panels incl. Copilot)
    index.md                   Persona reference grid

  prompts/                     Reusable prompt templates
    workflows/                 Multi-phase orchestration (8 workflows)
    plan-template.md           Standardized plan template for AI and humans

  schemas/                     Enforcement artifacts (JSON Schema)
    panel-output.schema.json   Structured emission standard for panel reviews
    run-manifest.schema.json   Audit manifest for every merge decision

  policy/                      Deterministic policy profiles (YAML)
    default.yaml               Standard risk tolerance
    fin_pii_high.yaml          Financial/PII — SOC2, PCI-DSS, HIPAA, GDPR
    infrastructure_critical.yaml  Infrastructure-as-code, deployment configs

  manifests/                   Run manifests (audit trail, append-only)

  templates/                   Language-specific scaffolding
    go/                        Go conventions and project config
    python/                    Python conventions and project config
    node/                      Node.js/TypeScript conventions
    react/                     React conventions
    csharp/                    C#/.NET conventions

  mcp/                         MCP server configurations
    servers/                   Server definitions (gitignore, ServiceNow)

  docs/                        Architecture and design documents
    dark-factory-governance-model.md    Governance layers and decision authority
    artifact-classification.md          Cognitive, Enforcement, Audit artifact types
    context-management.md               JIT loading and context reset protection
    runtime-feedback-architecture.md    Drift detection and incident-to-DI generation
    autonomy-metrics.md                 Autonomy index and weekly reporting
    ci-gating-blueprint.md              CI checks, branch protection, auto-merge
    naming-review.md                    Persona/panel naming consistency review

  .plans/                      Implementation plans (per-task)
  .github/workflows/           CI/CD (jm-compliance.yml — enterprise-locked)
```

## How It Works

### For Code Changes (Phase 4a)

```
Issue / Design Intent
        |
        v
Code Manager validates intent (Layer 1: Intent Governance)
        |
        v
Panel graph activated (Layer 2: Cognitive Governance)
  - Personas assigned based on change type and risk
  - Panels execute in parallel where possible
        |
        v
Panels emit structured JSON (Layer 3: Execution Governance)
  - Confidence scores, risk levels, policy flags
  - Validated against schemas/panel-output.schema.json
        |
        v
Policy engine evaluates (deterministic, no prose)
  - Reads active policy profile (default, fin_pii_high, etc.)
  - Produces decision: auto_merge | auto_remediate | human_review_required | block
        |
        v
Run manifest logged (schemas/run-manifest.schema.json)
  - Complete audit trail for replay and compliance
```

### For Runtime Feedback (Phase 5 — Designed)

```
Runtime anomaly detected
        |
        v
Signal classified and deduplicated
        |
        v
Design Intent generated automatically
        |
        v
Feeds back into Layer 1 (closes the autonomous loop)
```

## Compliance and Security

Security, regulatory compliance, and code quality are embedded at every governance layer:

| Layer | Compliance Mechanism |
|-------|---------------------|
| Intent | Risk classification at intake; PII/financial flags trigger `fin_pii_high` profile |
| Cognitive | Security Auditor and Compliance Officer personas activated for regulated changes |
| Execution | Policy engine enforces compliance scores, blocks PII exposure, requires security panel |
| Runtime | Drift detection monitors compliance regression; incidents generate remediation DIs |
| Evolution | Backward compatibility checks; breaking changes require migration plans |

Policy profiles provide pre-configured compliance postures:
- **`fin_pii_high`** — SOC2, PCI-DSS, HIPAA, GDPR. Auto-merge disabled. 3-approver override.
- **`infrastructure_critical`** — Production stability. Mandatory architecture and SRE review.
- **`default`** — Standard internal applications. Balanced automation and oversight.

## Context Management

The framework uses JIT (Just-In-Time) loading to minimize AI context window usage:

| Tier | Content | Budget | Survives Reset |
|------|---------|--------|----------------|
| 0 | Base instructions + project identity | ~400 tokens | Yes (pinned) |
| 1 | Language conventions + active personas | ~2,000 tokens | Session duration |
| 2 | Current workflow phase + panel context | ~3,000 tokens | Released per phase |
| 3 | Policies, schemas, docs | 0 tokens | Queried on-demand |

See `docs/context-management.md` for the full strategy including checkpoint-based reset protection and instruction decomposition.

## Repo Rename Recommendation

This repository is currently named `ai-submodule`. Given its evolution into a governance platform, a more descriptive name is recommended:

| Candidate | Rationale |
|-----------|-----------|
| **`dark-factory`** | Aligns with the governance model name and Phase 5 goal |
| **`ai-governance`** | Descriptive of current function |
| **`forge`** | Short, evocative of autonomous manufacturing |

The rename should be coordinated across all consuming repositories that reference the submodule URL.

## Why a Git Submodule?

| Approach | Drawback |
|----------|----------|
| Copy-paste | Drifts immediately. No propagation across repos. |
| Package manager | Runtime dependency for static text. Overkill. |
| Monorepo | Forces all projects into one repo. |
| Template repo | One-time only. Updates don't flow. |
| Git subtree | Merges history into host repo. Hard to update cleanly. |

Submodules provide version-pinned, single-source-of-truth distribution with no toolchain requirement.

## Usage

### Adding to a Project

```bash
git submodule add git@github.com:SET-Apps/ai-submodule.git .ai
git commit -m "Add .ai submodule"
```

### Cloning with Submodule

```bash
git clone --recurse-submodules <PROJECT_URL>
```

### Updating

```bash
git submodule update --remote .ai
git add .ai
git commit -m "Update .ai submodule"
```

### Pinning a Version

```bash
cd .ai
git checkout v2.0.0
cd ..
git add .ai
git commit -m "Pin .ai submodule to v2.0.0"
```

### Project-Specific Configuration

1. Copy a language template: `cp .ai/templates/python/project.yaml .ai/project.yaml`
2. Customize personas, panels, and conventions
3. Set the governance policy profile:
   ```yaml
   governance:
     policy_profile: default
   ```

### Removing

```bash
git submodule deinit -f .ai
git rm -f .ai
rm -rf .git/modules/.ai
git commit -m "Remove .ai submodule"
```
