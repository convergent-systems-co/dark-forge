# Developer Quick Guide

TLDR for developers adopting the Dark Factory Governance Platform.

## What Is This?

A git submodule (`.ai/`) that gives your repository AI-powered governance: automated code review panels, deterministic merge policies, structured audit trails, and agentic workflows. No application code — just configuration, personas, policies, and schemas.

## Quick Start

### 1. Add to your repo

```bash
git submodule add git@github.com:SET-Apps/ai-submodule.git .ai
bash .ai/init.sh   # creates symlinks for Claude Code, Copilot, and Cursor
git commit -m "Add .ai governance submodule"
```

### 2. Configure for your stack

```bash
cp .ai/templates/python/project.yaml .ai/project.yaml   # or go/, node/, react/, csharp/
```

Edit `.ai/project.yaml` to review and customize your project configuration. Policy profiles are defined under `governance/policy/`; choose the one that matches your use case (see the table below for guidance).

### 3. Update when the submodule changes

```bash
git submodule update --remote .ai
git add .ai && git commit -m "Update .ai submodule"
```

## Key Concepts

| Concept | What It Is | Where It Lives |
|---------|-----------|----------------|
| **Personas** | 44 AI reasoning roles (Security Auditor, Architect, etc.) | `governance/personas/` |
| **Panels** | Multi-persona review workflows that emit structured JSON | `governance/personas/panels/` |
| **Policy profiles** | Deterministic rules for merge decisions (no AI interpretation) | `governance/policy/` |
| **Structured emissions** | JSON output from panels, validated against schema | `governance/schemas/panel-output.schema.json` |
| **Run manifests** | Immutable audit records for every merge decision | `governance/manifests/` |
| **Code Manager** | Orchestrator persona — triages issues, invokes panels, merges PRs | `governance/personas/agentic/code-manager.md` |
| **Coder** | Executor persona — writes plans, implements code, responds to reviews | `governance/personas/agentic/coder.md` |

## Three Policy Profiles

| Profile | Use When | Auto-Merge | Key Rules |
|---------|----------|------------|-----------|
| `default` | Standard internal apps | Yes (with conditions) | Balanced automation and oversight |
| `fin_pii_high` | Financial, PII, regulated data | No | SOC2/PCI-DSS/HIPAA/GDPR, 3-approver override |
| `infrastructure_critical` | Infra-as-code, deployments | No | Mandatory architecture + SRE review |

## How a Change Flows Through Governance

```
Issue/DI  -->  Intent validation  -->  Panel review  -->  Policy engine  -->  Merge decision
              (is it clear?)         (AI personas)     (deterministic)     (auto/human/block)
```

1. **Intent** — Issue or Design Intent is validated for completeness
2. **Cognitive** — Relevant persona panels review the change and emit structured JSON
3. **Execution** — Policy engine reads emissions + profile, produces a decision (no AI involved)
4. **Audit** — Run manifest is logged (immutable, append-only)

## Common Operations

### Start the agentic loop

The Code Manager scans issues, creates plans, implements, reviews, and merges autonomously:

```
# In Claude Code or similar AI tool, invoke:
/startup
```

This runs `governance/prompts/startup.md` — the entry point for autonomous operation.

### Write a plan before coding

Every non-trivial change needs a plan in `.plans/`:

```bash
# Use the template
cp governance/prompts/plan-template.md .plans/42-my-feature.md
# Fill in all sections, then implement
```

### Branch naming

```
itsfwcp/{type}/{issue-number}/{short-name}
# Examples:
itsfwcp/feat/42/add-auth
itsfwcp/fix/99/null-check
itsfwcp/docs/36/next-steps
```

### Commit style

Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`

## Context Management

AI context windows are finite. The framework uses tiered loading:

| Tier | Loaded | Budget |
|------|--------|--------|
| 0 | Always (base instructions) | ~400 tokens |
| 1 | Per session (language conventions, active personas) | ~2,000 tokens |
| 2 | Per phase (workflow context, panel context) | ~3,000 tokens |
| 3 | On demand (policies, schemas, full docs) | 0 tokens until needed |

**Hard rule:** Stop at 80% context capacity. Checkpoint. Request `/clear`. Never compact with dirty state.

## File Structure at a Glance

```
.ai/
  CLAUDE.md                  # Instructions for Claude Code (symlinked)
  DEVELOPER_GUIDE.md         # This file
  GOALS.md                   # Phase tracking and completed work
  README.md                  # Full documentation
  instructions.md            # Base AI instructions (Tier 0)
  instructions/              # Decomposed instruction modules
  config.yaml                # Symlink configuration
  init.sh                    # Bootstrap script
  templates/                 # Language-specific scaffolding (go, python, node, react, csharp)
  governance/
    personas/                # 44 persona definitions (including 2 agentic) + 15 panels
    policy/                  # 3 deterministic policy profiles (YAML)
    schemas/                 # JSON Schema for emissions and manifests
    prompts/                 # Reusable prompts and workflows
    docs/                    # Architecture and design documents
    emissions/               # Panel output (structured JSON)
    manifests/               # Run manifests (audit trail)
  .plans/                    # Implementation plans
  .checkpoints/              # Session state checkpoints
  .governance/               # Policy engine runtime (Python)
```

## Further Reading

- [README.md](README.md) — Full documentation with architecture details
- [GOALS.md](GOALS.md) — Phase status and completed work tracking
- [governance/docs/](governance/docs/) — Architecture documents
- [governance/personas/index.md](governance/personas/index.md) — Persona and panel reference
