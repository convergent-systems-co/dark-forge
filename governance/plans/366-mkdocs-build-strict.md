# Add mkdocs build --strict to CI Pipeline

**Author:** Code Manager (agent)
**Date:** 2026-02-26
**Status:** approved
**Issue:** https://github.com/SET-Apps/ai-submodule/issues/366
**Branch:** itsfwcp/fix/366/mkdocs-build-strict

---

## 1. Objective

Enable strict mode for mkdocs builds in the deploy-docs CI workflow to catch broken links, missing nav references, and configuration issues.

## 2. Rationale

Without `--strict`, broken internal links and missing nav references pass CI silently, leading to broken documentation on the live site.

| Alternative | Considered | Rejected Because |
|-------------|-----------|------------------|
| Strict mode (chosen) | Yes | — |
| Separate link-checking step | Yes | Redundant — `--strict` already covers this |

## 3. Scope

### Files to Create

| File | Purpose |
|------|---------|
| N/A | — |

### Files to Modify

| File | Change Description |
|------|-------------------|
| `.github/workflows/deploy-docs.yml` | Change `mkdocs build` to `mkdocs build --strict` |

### Files to Delete

| File | Reason |
|------|--------|
| N/A | — |

## 4. Approach

1. Edit `.github/workflows/deploy-docs.yml` line 36: change `run: mkdocs build` to `run: mkdocs build --strict`

## 5. Testing Strategy

| Test Type | Coverage | Description |
|-----------|----------|-------------|
| CI validation | deploy-docs workflow | The next docs push will validate strict mode catches errors |

## 6. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Existing docs have warnings that become errors | Medium | Low | Fix any broken links in the same PR |

## 7. Dependencies

- None

## 8. Backward Compatibility

N/A — CI-only change.

## 9. Governance

| Panel | Required | Rationale |
|-------|----------|-----------|
| security-review | Yes | Default policy requirement |
| threat-modeling | Yes | Default policy requirement |
| cost-analysis | Yes | Default policy requirement |
| documentation-review | Yes | Default policy requirement |
| data-governance-review | Yes | Default policy requirement |

**Policy Profile:** default
**Expected Risk Level:** negligible

## 10. Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-02-26 | Single-line change | Issue is clear and scoped |
