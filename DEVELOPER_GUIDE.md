# Developer Quick Guide

TLDR for developers adopting the Dark Factory Governance Platform.

## What Is This?

A git submodule (`.ai/`) that gives your repository AI-powered governance: automated code review panels, deterministic merge policies, structured audit trails, and agentic workflows. No application code — just configuration, personas, policies, and schemas.

## Quick Start

### 1. Add to your repo

```bash
git submodule add git@github.com:SET-Apps/ai-submodule.git .ai
bash .ai/init.sh   # macOS/Linux — creates symlinks for Claude Code, Copilot, and Cursor
git commit -m "Add .ai governance submodule"
```

**Windows (PowerShell):**
```powershell
git submodule add git@github.com:SET-Apps/ai-submodule.git .ai
powershell -ExecutionPolicy Bypass -File .ai\init.ps1
git commit -m "Add .ai governance submodule"
```

> Windows requires Python 3.12+ for the policy engine. Install from [python.org](https://www.python.org/downloads/), then run `pip install jsonschema pyyaml`.

### 2. Configure for your stack

```bash
cp .ai/templates/python/project.yaml project.yaml   # or go/, node/, react/, csharp/
```

Edit `project.yaml` to review and customize your project configuration. Policy profiles are defined under `governance/policy/`; choose the one that matches your use case (see the table below for guidance).

### 3. Update when the submodule changes

```bash
git submodule update --remote .ai
git add .ai && git commit -m "Update .ai submodule"
```

## Key Concepts

| Concept | What It Is | Where It Lives |
|---------|-----------|----------------|
| **Personas** | 60 AI reasoning roles (Security Auditor, Architect, Rust Engineer, etc.) | `governance/personas/` |
| **Panels** | Multi-persona review workflows that emit structured JSON | `governance/personas/panels/` |
| **Policy profiles** | Deterministic rules for merge decisions (no AI interpretation) | `governance/policy/` |
| **Structured emissions** | JSON output from panels, validated against schema | `governance/schemas/panel-output.schema.json` |
| **Run manifests** | Immutable audit records for every merge decision | `governance/manifests/` |
| **Code Manager** | Orchestrator persona — triages issues, invokes panels, merges PRs | `governance/personas/agentic/code-manager.md` |
| **Coder** | Executor persona — writes plans, implements code, responds to reviews | `governance/personas/agentic/coder.md` |

## Four Policy Profiles

| Profile | Use When | Auto-Merge | Key Rules |
|---------|----------|------------|-----------|
| `default` | Standard internal apps | Yes (with conditions) | Balanced automation and oversight |
| `fin_pii_high` | Financial, PII, regulated data | No | SOC2/PCI-DSS/HIPAA/GDPR, 3-approver override |
| `infrastructure_critical` | Infra-as-code, deployments | No | Mandatory architecture + SRE review |
| `reduced_touchpoint` | Mature repos wanting minimal human gates | Yes (broader) | Human review only for policy overrides, dismissed security findings, or critical risk |

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
cp governance/prompts/templates/plan-template.md .plans/42-my-feature.md
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

## Repository Configuration

The `.ai` governance framework can configure GitHub repository settings to support the autonomous agentic workflow. Settings are declared in `config.yaml` (defaults) and overridden in `project.yaml` (per-project).

### Required Settings for Agentic Loop

| Setting | Required Value | Why |
|---------|---------------|-----|
| `allow_auto_merge` | `true` | PRs auto-merge after CI + approval |
| `delete_branch_on_merge` | `true` | Clean up feature branches |
| CODEOWNERS populated | Non-empty | `require_code_owner_review` ruleset needs owners |

### Applying Settings

Run `bash .ai/init.sh` -- the script will:
1. Create symlinks (existing behavior)
2. Copy issue templates and symlink governance workflows to `.github/` (submodule context only)
3. Configure repository settings via `gh api` (requires admin permissions)
4. Generate CODEOWNERS if empty or missing

If the script lacks admin permissions, it will print instructions for a repository admin to apply the settings manually. All steps degrade gracefully -- missing `gh` CLI or insufficient permissions are warnings, not errors.

### Per-Project Overrides

Add a `repository` section to your `project.yaml` to override defaults:

```yaml
repository:
  codeowners:
    rules:
      - pattern: "/src/**/Authentication/"
        owners: ["@my-org/security"]
```

See `governance/docs/repository-configuration.md` for full documentation and schema details.

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
  init.sh                    # Bootstrap script (macOS/Linux)
  init.ps1                   # Bootstrap script (Windows)
  templates/                 # Language-specific scaffolding (go, python, node, react, csharp)
  governance/
    personas/                # 60 persona definitions (including 2 agentic) + 19 panels
    policy/                  # 4 policy profiles + supporting rules (16 YAML files + signal-adapters/)
    schemas/                 # 20 JSON Schemas for emissions, manifests, metrics, and validation
    prompts/                 # Reusable prompts and workflows
    docs/                    # Architecture and design documents
    emissions/               # Panel output (structured JSON)
    manifests/               # Run manifests (audit trail)
  .plans/                    # Implementation plans (created in consuming repos by init.sh)
  .panels/                   # Panel review reports (created in consuming repos by init.sh)
  .checkpoints/              # Session state checkpoints
  .governance/               # Policy engine runtime (Python)
```

## Recovery & Re-Entry Patterns

When the agentic loop stops — context reset, crash, stuck PR, dirty git state — use these patterns to get back in.

### Resume from a checkpoint (happy path)

After a `/clear` or context reset, the agent wrote a checkpoint before stopping:

```bash
# Find the most recent checkpoint
ls -t .checkpoints/*.json | head -1

# Read it to see where things left off
cat .checkpoints/<latest>.json
```

Then tell the agent: `continue` or `Resume from checkpoint: .checkpoints/<file>`. The agent will:
1. Validate the checkpoint (git state, issue state, PR state)
2. Re-enter the startup loop at the right step
3. Skip completed work, resume in-progress work

See [checkpoint-resumption-workflow.md](governance/prompts/checkpoint-resumption-workflow.md) for the full protocol.

### No checkpoint exists

If the session ended without writing a checkpoint (crash, force quit, network loss):

```bash
# 1. Check git state — what branch are we on, is it clean?
git status
git branch --show-current

# 2. Check for open PRs the agent may have created
gh pr list --state open --author @me

# 3. Check for plans that were in progress
ls .plans/

# 4. Check open issues to find what was being worked on
gh issue list --state open --limit 10
```

Then tell the agent: `/startup`. It will run a fresh scan — checking open PRs first (Step 0), then open issues (Step 1). Any in-progress branches or PRs will be picked up automatically.

### Dirty git state

If `git status` shows uncommitted changes, merge conflicts, or in-progress operations:

```bash
# Option A: Commit what's there (if the changes are good)
git add -A && git commit -m "wip: checkpoint recovery — incomplete changes"

# Option B: Stash changes to inspect later
git stash push -m "recovery stash from $(date +%Y%m%d)"

# Option C: Abort an in-progress merge or rebase
git merge --abort   # if mid-merge
git rebase --abort  # if mid-rebase

# Option D: Nuclear option — discard everything and start clean
git checkout -- . && git clean -fd
```

Once `git status` shows `nothing to commit, working tree clean`, run `/startup` to re-enter the loop.

### Stuck or failed PR

If a PR has failing checks, unresolved reviews, or is stuck in the review cycle:

```bash
# Check PR status
gh pr view <pr-number> --json state,statusCheckRollup,reviews

# Check CI failures
gh pr checks <pr-number>

# Check for unresolved review threads
gh api graphql -f query='query($owner:String!,$repo:String!,$pr:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$pr){reviewThreads(first:100){nodes{isResolved,isOutdated,comments(first:1){nodes{author{login}body}}}}}}}' -f owner=SET-Apps -f repo=ai-submodule -F pr=<pr-number>
```

Then tell the agent: `Resume PR #<number>`. It will check out the branch and enter Step 7 (PR Monitoring & Review Loop). After 3 failed review cycles, it escalates to human review.

### Context loss mid-session

If you suspect the agent lost context (repeating itself, forgetting decisions, re-reading files):

1. **Don't wait** — this means the context is already under pressure
2. Tell the agent: `Write a checkpoint and stop`
3. Run `/clear` to reset context
4. Resume from the checkpoint in a fresh session

The 80% context capacity rule exists to prevent this. If it happens, the agent was too deep before checkpointing.

### Closed issues discovered mid-session

The agent validates issue state before starting work. If an issue is closed between sessions:

```bash
gh issue view <number> --json state --jq '.state'
```

Closed issues are automatically skipped. If the agent has an open PR for a closed issue, it will not merge it — the PR should be closed manually or by the agent.

### Manual re-entry at specific steps

You can tell the agent to enter the startup loop at any step:

| Situation | What to Say |
|-----------|-------------|
| Open PRs need resolution | `Start at Step 0 — resolve open PRs` |
| Need a fresh issue scan | `Start at Step 1 — scan open issues` |
| Have a specific issue to work on | `Work on issue #N` (agent enters at Step 4) |
| PR needs review cycle | `Resume PR #N at Step 7` |
| Want to fall back to GOALS.md | `Start at Step 8 — check GOALS.md for unchecked items` |

## Diagnostic Commands

Quick reference for checking system state:

| What | Command |
|------|---------|
| Git state | `git status` |
| Current branch | `git branch --show-current` |
| Recent checkpoints | `ls -t .checkpoints/*.json \| head -5` |
| Open PRs | `gh pr list --state open` |
| Open issues | `gh issue list --state open --limit 20` |
| Issue state | `gh issue view <N> --json state --jq '.state'` |
| PR checks | `gh pr checks <N>` |
| PR review threads | `gh api graphql -f query='...' -F pr=<N>` (see above) |
| Governance workflow health | `gh api repos/{owner}/{repo}/actions/workflows/dark-factory-governance.yml/runs --jq '[.workflow_runs[:5][] \| .conclusion]'` |
| Auto-merge enabled | `gh api repos/{owner}/{repo} --jq '.allow_auto_merge'` |
| Submodule status | `git submodule status .ai` |
| Existing branches | `git branch -r \| grep itsfwcp` |
| Plans in progress | `ls .plans/` |

## Troubleshooting

**The agent creates a PR but never merges it.**
The review loop (Step 7) requires all CI checks to pass, all Copilot recommendations to be addressed, and all review threads to be resolved. Check `gh pr checks <N>` and the PR's review threads. After 3 review cycles, the agent escalates to human review.

**The agent skips my issue.**
Issues are skipped if they: have a `blocked`, `wontfix`, or `duplicate` label; already have a branch matching `itsfwcp/*/*`; are assigned to a human; were updated by a human in the last 24 hours; or are labeled `refine` without new human input. Check `gh issue view <N> --json labels,assignees,updatedAt`.

**The agent labels my issue `refine` and moves on.**
The intent was unclear — the agent needs clearer acceptance criteria or fewer decision points. Update the issue body or add a comment with clarification. The agent will re-evaluate `refine` issues in the next session if a human has updated them.

**The governance workflow isn't running.**
Check if it exists and is enabled: `gh workflow list`. If disabled, re-enable with `gh workflow enable dark-factory-governance.yml`. If missing, run `bash .ai/init.sh` to set up workflows.

**Checkpoint is older than 24 hours.**
Stale checkpoints may reference closed issues or merged PRs. The agent treats these as stale and runs a fresh scan instead of resuming. This is expected behavior.

**The agent stops after 3 issues.**
The 3-issue-per-session cap is a hard safety limit to prevent context overflow. It checkpoints and requests `/clear`. Resume from the checkpoint in a fresh session.

**Auto-merge fails.**
Check that `allow_auto_merge` is enabled (`gh api repos/{owner}/{repo} --jq '.allow_auto_merge'`), branch protection rules allow it, and CODEOWNERS is populated. Run `bash .ai/init.sh` to apply settings.

**The agent keeps re-reading files it already read.**
This is a context pressure signal — the agent's context window is filling up. Tell it to checkpoint and stop, then `/clear` and resume.

## Further Reading

- [README.md](README.md) — Full documentation with architecture details and [Documentation Index](README.md#documentation-index)
- [GOALS.md](GOALS.md) — Phase status and completed work tracking
- [governance/docs/](governance/docs/) — Architecture and design documents
- [governance/personas/index.md](governance/personas/index.md) — Persona and panel reference grid
- [governance/prompts/startup.md](governance/prompts/startup.md) — Agentic loop entry point
- [governance/docs/repository-configuration.md](governance/docs/repository-configuration.md) — Repository settings and CODEOWNERS setup
- [governance/prompts/checkpoint-resumption-workflow.md](governance/prompts/checkpoint-resumption-workflow.md) — Full checkpoint recovery protocol
- [governance/docs/context-management.md](governance/docs/context-management.md) — Context tiers, capacity detection, and shutdown protocol
