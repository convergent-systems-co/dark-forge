# Panel: Architecture Review

## Purpose
Evaluate system design decisions from multiple architectural perspectives.

## Participants
- **Systems Architect** - Scalability, boundaries, state management
- **Security Auditor** - Attack surface, auth model, data protection
- **Failure Engineer** - Resilience, recovery, blast radius
- **Infrastructure Engineer** - Deployment, networking, operations
- **API Designer** - Contracts, versioning, consumer experience

## Process
1. Present design context and constraints
2. Each participant evaluates from their lens
3. Surface cross-cutting concerns
4. Debate tradeoffs explicitly
5. Converge on recommendations

## Output Format
### Per Participant
- Perspective name
- Architectural concerns
- Risk assessment
- Recommended changes

### Consolidated
- Architectural strengths
- Critical risks
- Design modifications required
- Tradeoffs accepted (with rationale)
- Go/No-Go recommendation

## Constraints
- Consider both build and operate phases
- Identify hidden assumptions
- Prefer reversible decisions
- Document rejected alternatives
