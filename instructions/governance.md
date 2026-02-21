# Governance Instructions

<!-- PHASE:governance -->

Loaded for governance pipeline tasks — panel coordination, policy evaluation, manifest generation.

## Structured Emissions

- All panel output must include JSON between `<!-- STRUCTURED_EMISSION_START -->` and `<!-- STRUCTURED_EMISSION_END -->` markers
- Validate emissions against `schemas/panel-output.schema.json`
- Missing markers or invalid JSON means panel execution failed

## Policy

- Policy profiles are evaluated programmatically — never interpret policy rules as prose
- Use the active profile from `project.yaml` governance configuration
- Escalate to human review when confidence is below profile thresholds

## Manifests

- Run manifests are immutable — never edit after creation
- Every merge decision must produce a manifest conforming to `schemas/run-manifest.schema.json`
- Record the persona set commit, policy profile, and all panel emissions
