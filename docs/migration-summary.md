# Dark Factory Governance — Migration Summary

## Required Repo Structure Changes

### New Directories

| Directory | Purpose | Contents |
|-----------|---------|----------|
| `docs/` | Architecture and design documents | 7 governance documents |
| `schemas/` | JSON Schema enforcement artifacts | panel-output, run-manifest schemas |
| `policy/` | Deterministic policy profiles | default, fin_pii_high, infrastructure_critical |
| `manifests/` | Append-only audit trail | Run manifests (one per merge decision) |
| `personas/panels/` | Formal review panel definitions | copilot-review.md |
| `personas/governance/` | Governance-specific personas | Governance Auditor, Policy Evaluator |
| `personas/agentic/` | Autonomous agent personas | Code Manager, Coder |

### New Files

| File | Type | Purpose |
|------|------|---------|
| `docs/dark-factory-governance-model.md` | Cognitive | 5-layer governance architecture |
| `docs/artifact-classification.md` | Cognitive | Cognitive/Enforcement/Audit artifact taxonomy |
| `docs/context-management.md` | Cognitive | JIT loading, context budgets, reset protection |
| `docs/runtime-feedback-architecture.md` | Cognitive | Phase 5 design: drift detection, incident-to-DI |
| `docs/autonomy-metrics.md` | Cognitive | Autonomy index, weekly reporting specification |
| `docs/ci-gating-blueprint.md` | Cognitive | CI checks, branch protection, auto-merge config |
| `docs/naming-review.md` | Cognitive | Persona/panel naming consistency proposals |
| `schemas/panel-output.schema.json` | Enforcement | Structured emission validation schema |
| `schemas/run-manifest.schema.json` | Enforcement | Merge audit manifest validation schema |
| `policy/default.yaml` | Enforcement | Baseline policy profile |
| `policy/fin_pii_high.yaml` | Enforcement | Financial/PII compliance profile |
| `policy/infrastructure_critical.yaml` | Enforcement | Infrastructure stability profile |
| `policy/README.md` | Cognitive | Policy framework documentation |
| `personas/panels/copilot-review.md` | Cognitive | Copilot as formal governance panel |
| `personas/governance/governance-auditor.md` | Cognitive | Pipeline audit persona |
| `personas/governance/policy-evaluator.md` | Cognitive | Deterministic policy application persona |
| `personas/agentic/code-manager.md` | Cognitive | Orchestration persona |
| `personas/agentic/coder.md` | Cognitive | Execution persona |
| `prompts/plan-template.md` | Cognitive | Standardized plan template |
| `manifests/.gitkeep` | — | Placeholder for manifest directory |

### Modified Files

| File | Change |
|------|--------|
| `README.md` | Rewritten to document governance platform |
| `personas/index.md` | Added Governance, Agentic, and Copilot Review entries |

### Removed Files

| File | Reason |
|------|--------|
| `mcp/servicenow-mcp/servicenow_mcp.egg-info/*` | Build artifact cruft |

## Risk Areas

| Risk | Severity | Mitigation |
|------|----------|------------|
| Context window overflow from loading too many personas | Medium | Context management tiers with JIT loading (docs/context-management.md) |
| Policy profiles are not yet machine-executable | Medium | Profiles are declarative YAML; a policy engine runtime needs to be built |
| Structured emissions require panel modification | Medium | Panels continue emitting Markdown; JSON block is appended, not replacing |
| Naming renames break existing project.yaml references | Low | Renames are proposed only, not executed (docs/naming-review.md) |
| jm-compliance.yml cannot be modified | Low | New CI workflow runs alongside it, no conflicts |
| Manifest storage grows unbounded | Low | Retention policy needed; gitignore manifests from submodule, store per-repo |
| Override procedure requires cultural adoption | Medium | Document and train; start with logging-only mode |

## Migration Steps

### Phase 4a (Current Deliverables)

1. **Merge this branch** — All governance framework files are in place
2. **Update consuming repos** — `git submodule update --remote .ai` in each project
3. **Configure project.yaml** — Add `governance.policy_profile` to each project
4. **Add CI workflow** — Copy `dark-factory-governance.yml` from ci-gating-blueprint into each repo's `.github/workflows/`
5. **Configure branch protection** — Add Dark Factory status checks as required
6. **Train teams** — Introduce the governance model, plan template, and override procedure

### Phase 4b (Next Iteration)

1. **Build policy engine runtime** — Implement YAML policy evaluation as a CLI tool or GitHub Action
2. **Implement structured emission parsing** — Extract JSON from panel output Markdown
3. **Implement manifest generation** — Produce run-manifest.schema.json artifacts in CI
4. **Execute proposed renames** — If approved, rename persona directories per naming-review.md
5. **Implement instruction decomposition** — Split instructions.md per context-management.md
6. **Add checkpoint system** — Implement `.checkpoints/` for context reset recovery

### Phase 5 (Future)

1. **Implement runtime anomaly ingestion** — Per runtime-feedback-architecture.md
2. **Build incident-to-DI generator** — Automatic Design Intent creation from incidents
3. **Implement drift detection** — Baseline capture and deviation monitoring
4. **Enable automatic panel re-execution** — With circuit breakers and rate limiting
5. **Build autonomy dashboard** — Weekly metrics per autonomy-metrics.md
6. **Achieve self-evolution** — Governance model proposes its own improvements

## Breaking Changes

**None.** All changes are additive:

- Existing personas, prompts, workflows, and templates are unchanged
- No file paths were renamed (renames are proposed but not executed)
- The `jm-compliance.yml` workflow is untouched
- `config.yaml` and `instructions.md` are unchanged
- New directories and files do not conflict with existing structure
- Consuming repositories continue to work without changes until they opt into governance features

## Repo Rename

The repository is currently `SET-Apps/ai-submodule`. Given its evolution into a governance platform, renaming is recommended. Top candidates:

| Name | Pros | Cons |
|------|------|------|
| `dark-factory` | Aligns with governance model, memorable | May not be immediately clear to newcomers |
| `ai-governance` | Descriptive, professional | Less distinctive |
| `forge` | Short, manufacturing metaphor | May be confused with other tools |

The rename should be done via GitHub repository settings and requires updating the submodule URL in all consuming repos:

```bash
# In each consuming repo
git submodule set-url .ai git@github.com:SET-Apps/<new-name>.git
git commit -m "Update .ai submodule URL after rename"
```

## Deliverable Checklist

| # | Deliverable | File | Status |
|---|-------------|------|--------|
| 1 | Governance model document | `docs/dark-factory-governance-model.md` | Complete |
| 2 | Artifact classification | `docs/artifact-classification.md` | Complete |
| 3 | Structured emission schema | `schemas/panel-output.schema.json` | Complete |
| 4 | Policy framework | `policy/` (3 profiles + README) | Complete |
| 5 | Copilot panel design | `personas/panels/copilot-review.md` | Complete |
| 6 | Manifest schema | `schemas/run-manifest.schema.json` | Complete |
| 7 | CI gating blueprint | `docs/ci-gating-blueprint.md` | Complete |
| 8 | Runtime feedback architecture | `docs/runtime-feedback-architecture.md` | Complete |
| 9 | Autonomy metrics specification | `docs/autonomy-metrics.md` | Complete |
| + | Context management strategy | `docs/context-management.md` | Complete |
| + | Naming review | `docs/naming-review.md` | Complete |
| + | Plan template | `prompts/plan-template.md` | Complete |
| + | Code Manager persona | `personas/agentic/code-manager.md` | Complete |
| + | Coder persona | `personas/agentic/coder.md` | Complete |
| + | Governance Auditor persona | `personas/governance/governance-auditor.md` | Complete |
| + | Policy Evaluator persona | `personas/governance/policy-evaluator.md` | Complete |
| + | Updated README | `README.md` | Complete |
| + | Updated personas index | `personas/index.md` | Complete |
