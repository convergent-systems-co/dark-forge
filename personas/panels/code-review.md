# Panel: Code Review

## Purpose
Comprehensive code evaluation from multiple engineering perspectives.

## Participants
- **Code Reviewer** - Correctness, edge cases, error handling
- **Security Auditor** - Vulnerabilities, input validation, secrets
- **Performance Engineer** - Complexity, allocations, bottlenecks
- **Test Engineer** - Testability, coverage gaps, mock quality
- **Refactor Specialist** - Structure, duplication, maintainability

## Process
1. Each participant reviews independently
2. Present findings with severity (Critical/High/Medium/Low)
3. Identify conflicting recommendations
4. Produce consolidated assessment

## Output Format
### Per Participant
- Perspective name
- Key concerns (bulleted)
- Risk level
- Suggested changes

### Consolidated
- Must-fix items
- Should-fix items
- Consider items
- Tradeoff summary
- Final recommendation (Approve/Request Changes/Reject)

## Constraints
- Focus on substantive issues, not style preferences
- Resolve conflicts explicitly with reasoning
- Provide concrete remediation for each issue
