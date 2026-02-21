# Context Management and JIT Loading Strategy

## Problem

AI agents have finite context windows. Loading all personas, prompts, workflows, policies, and instructions simultaneously wastes context capacity, reduces reasoning quality, and risks context resets that lose critical guidance. The Dark Factory system contains 15,000+ lines of Markdown — loading everything is neither feasible nor desirable.

## Design Principles

1. **Load what you need, when you need it** — JIT loading based on task phase
2. **Never lose critical instructions** — Base instructions survive context resets
3. **Maximize parallel execution** — Independent agents work with minimal shared context
4. **Decompose for reuse** — Small, composable instruction units over monolithic files
5. **Context budget enforcement** — Hard limits on what gets loaded per phase

## Context Tiers

### Tier 0: Persistent Context (Always Loaded)

Content that must survive context resets. Kept minimal.

| Content | Source | Max Tokens |
|---------|--------|------------|
| Base instructions | `instructions.md` | 200 |
| Project identity | `project.yaml` (name, language, framework only) | 100 |
| Active governance profile | Profile name + decision thresholds only | 50 |
| Current task reference | Issue/DI ID + objective statement | 50 |

**Total Tier 0 budget: ~400 tokens**

Design rule: If `instructions.md` exceeds 500 tokens, decompose it. The base file must contain only universal principles. Everything else belongs in Tier 1 or 2.

### Tier 1: Session Context (Loaded at Session Start)

Content loaded once when an agent begins a task session. Stays in context for the session duration.

| Content | Source | Loaded When |
|---------|--------|-------------|
| Language conventions | `templates/{language}/instructions.md` | Session start, based on `project.yaml` language |
| Active persona set | Persona files listed in `project.yaml` | Session start |
| Current plan | `.plans/{active-plan}.md` | Session start if plan exists |

**Total Tier 1 budget: ~2,000 tokens**

Design rule: If the persona set exceeds the budget, load only the persona headers (Role + Evaluate For sections). Full persona content moves to Tier 2.

### Tier 2: Phase Context (Loaded Per Workflow Phase)

Content loaded and unloaded as the agent moves through workflow phases. Previous phase context is released.

| Content | Source | Loaded When |
|---------|--------|-------------|
| Workflow phase definition | `prompts/workflows/{workflow}.md` (single phase) | Phase entry |
| Phase-specific prompt | `prompts/{prompt}.md` | When the phase invokes it |
| Panel definition | `personas/panels/{panel}.md` | Panel invocation |
| Panel persona details | Individual persona files | Panel invocation |

**Total Tier 2 budget: ~3,000 tokens**

Design rule: Workflow files must be decomposable by phase. Each phase section should work independently without requiring the full workflow in context.

### Tier 3: Reference Context (Never Loaded, Queried On-Demand)

Content accessed via tool calls or file reads, never pre-loaded.

| Content | Source | Access Method |
|---------|--------|--------------|
| Policy profiles | `policy/*.yaml` | Programmatic evaluation |
| JSON schemas | `schemas/*.schema.json` | Schema validation tool |
| Run manifests | `manifests/*.json` | File read on-demand |
| Architecture docs | `docs/*.md` | File read when referenced |
| Other personas | `personas/**/*.md` not in active set | File read when invoked |

**Tier 3 budget: 0 tokens (no context cost)**

## Instruction Decomposition

### Current Problem

Monolithic instruction files force full loading even when only a fraction is relevant. A 2,000-token `instructions.md` wastes 1,800 tokens when only the base principles apply.

### Decomposition Strategy

Split instructions into composable units:

```
instructions.md                  (Tier 0 — universal principles, < 200 tokens)
instructions/
  code-quality.md               (Tier 1 — loaded for code tasks)
  testing.md                    (Tier 1 — loaded for test tasks)
  security.md                   (Tier 1 — loaded for security-sensitive tasks)
  communication.md              (Tier 1 — loaded for PR/issue tasks)
  governance.md                 (Tier 1 — loaded for governance tasks)
```

Each decomposed file:
- Has a clear, single responsibility
- Is under 500 tokens
- Can be loaded independently
- Has no dependencies on other decomposed files

### Persona Decomposition

Personas are already well-decomposed (one file per persona). Optimization:

1. **Header extraction**: For Tier 1 loading, extract only `## Role` and `## Evaluate For` (~100 tokens per persona vs. ~400 for the full file)
2. **Full load on invocation**: Load the complete persona only when it is actively executing a review
3. **Panel optimization**: Load only the moderator pattern and persona names; load individual personas as they speak

### Workflow Phase Decomposition

Workflows must support phase-level loading. Convention:

```markdown
<!-- PHASE:1 -->
## Phase 1: Requirements Analysis
...
<!-- /PHASE:1 -->

<!-- PHASE:2 -->
## Phase 2: Design
...
<!-- /PHASE:2 -->
```

The agent loader extracts only the current phase section, keeping previous phases out of context. Phase artifacts (e.g., `[FEAT-1]`) are passed forward as compact references, not full content.

## Parallel Execution Model

### Agent Independence

Each parallel agent receives:
- Tier 0 context (identical across all agents)
- Its own Tier 1 context (specific to its role)
- Its own Tier 2 context (specific to its current phase)

No shared mutable state between agents. Results are aggregated by the Code Manager after all agents complete.

### Panel Parallelism

Panels can execute personas in parallel:

```
Code Review Panel
  |
  +---> [Agent 1] Code Reviewer (Tier 0 + persona context)
  +---> [Agent 2] Security Auditor (Tier 0 + persona context)
  +---> [Agent 3] Performance Engineer (Tier 0 + persona context)
  +---> [Agent 4] Test Engineer (Tier 0 + persona context)
  +---> [Agent 5] Refactor Specialist (Tier 0 + persona context)
  |
  v
Moderator aggregates findings into structured emission
```

Each persona agent:
- Loads only Tier 0 + its own persona definition + the code diff
- Produces independent findings
- Has no dependency on other persona agents
- Can be terminated independently on timeout

### Workflow Parallelism

Independent workflow phases can execute in parallel:

```
Feature Implementation
  |
  Phase 1: Requirements  -----> Phase 2: Design (depends on Phase 1)
                                    |
                                    +---> Phase 3a: Implementation (parallel)
                                    +---> Phase 3b: Test Planning (parallel)
                                    |
                                    v
                                Phase 4: Review (depends on 3a + 3b)
```

## Context Reset Protection

### The Reset Problem

When a context window fills, the AI runtime may truncate or summarize early context. This risks losing:
- Base instructions (Tier 0)
- Active persona definitions (Tier 1)
- Governance constraints

### Protection Mechanisms

1. **Tier 0 pinning**: Base instructions are re-injected at every agent turn as system-level context. They are never part of the conversation history that gets truncated.

2. **Checkpoint artifacts**: At each workflow gate, the agent writes a checkpoint file:
   ```
   .checkpoints/{task-id}-phase-{n}.json
   ```
   Contains: current state, decisions made, findings so far. If context resets, the agent reads the checkpoint to resume.

3. **Context budget monitoring**: Track approximate token usage per tier. When Tier 2 exceeds budget, the agent must:
   - Write current findings to a checkpoint
   - Release Tier 2 context
   - Load the next phase's Tier 2 context
   - Read the checkpoint to restore state

4. **Instruction anchoring**: Critical instructions include a marker:
   ```markdown
   <!-- ANCHOR: This instruction must survive context resets -->
   ```
   The agent loader treats anchored content as Tier 0, ensuring it is always present.

5. **Decomposed re-loading**: If context is reset mid-task, the agent:
   1. Reads Tier 0 (always available as system context)
   2. Reads the checkpoint file for current state
   3. Loads only the Tier 1 + Tier 2 context needed for the current phase
   4. Continues from the checkpoint

## Implementation Requirements

### For Persona Authors

- Keep persona files under 500 tokens
- Put the most critical information in `## Role` and `## Evaluate For` (loaded first)
- Put detailed guidance in `## Principles` and `## Anti-patterns` (loaded on full invocation)

### For Workflow Authors

- Use `<!-- PHASE:N -->` markers to enable phase-level extraction
- Keep each phase under 1,000 tokens
- Pass forward only artifact references, not full artifact content
- Design phases to be resumable from a checkpoint

### For Instruction Authors

- Keep `instructions.md` under 200 tokens (universal principles only)
- Decompose domain-specific guidance into `instructions/` subdirectory
- Mark critical instructions with `<!-- ANCHOR -->` markers
- Never put implementation details in base instructions

### For the Agent Runtime

- Implement a context loader that respects tier budgets
- Re-inject Tier 0 at every turn
- Monitor approximate token usage and warn at 80% budget
- Write checkpoints at every workflow gate
- Support phase-level extraction from workflow files
