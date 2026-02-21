# Panel: Migration Review

## Purpose
Evaluate migration plan safety, completeness, and risk mitigation.

## Participants
- **Migration Specialist** - Plan completeness, rollback capability
- **Data Architect** - Data integrity, transformation correctness
- **SRE** - Operational readiness, monitoring during migration
- **Failure Engineer** - Failure scenarios, recovery procedures
- **Tech Lead** - Timeline, resource allocation, communication

## Process
1. Review migration plan and timeline
2. Each participant assesses from their perspective
3. Identify rollback gaps
4. Stress-test failure scenarios
5. Validate communication plan

## Output Format
### Per Participant
- Perspective name
- Plan gaps
- Risk concerns
- Required additions

### Consolidated
- Migration blockers
- Risk mitigations required
- Rollback verification checklist
- Monitoring requirements
- Go/No-Go recommendation

## Constraints
- Require tested rollback at every step
- Validate data integrity continuously
- Plan for extended migration states
- Ensure clear abort criteria
