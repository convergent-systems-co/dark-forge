# Panel: Production Readiness Review

## Purpose


Assess whether a system is ready for production deployment.


## Participants

- **SRE** - SLOs, runbooks, on-call readiness
- **Infrastructure Engineer** - Deployment, security, networking
- **Observability Engineer** - Logging, metrics, alerting
- **Failure Engineer** - Recovery, rollback, graceful degradation
- **DevOps Engineer** - CI/CD, artifact management, environments


## Process

1. Review deployment architecture
2. Each participant assesses operational readiness
3. Identify gaps in observability and recovery
4. Evaluate incident response capability

5. Determine launch blockers vs follow-ups


## Output Format

### Per Participant

- Perspective name

- Readiness gaps
- Risk level
- Required before launch

### Consolidated

- Launch blockers (must fix)

- Launch risks (accepted with mitigation)
- Post-launch requirements
- Operational runbook status
- Go/No-Go recommendation

## Constraints

- Ensure rollback capability exists
- Verify alerting covers critical paths
- Require runbooks for known failure modes
- Document accepted risks explicitly
