# PRD Generation Skill

This skill helps you create detailed Product Requirements Documents (PRDs) for features you want to build.

## Usage

Load this skill and say: "Create a PRD for [your feature description]"

## Process

When asked to create a PRD, follow these steps:

### 1. Ask Clarifying Questions

Before writing the PRD, ask the user about:

- **Target users**: Who will use this feature?
- **Core problem**: What problem does this solve?
- **Success metrics**: How will we know it's successful?
- **Technical constraints**: Any specific tech stack, patterns, or limitations?
- **Scope boundaries**: What's explicitly NOT included?
- **Dependencies**: Does this depend on other features/systems?

### 2. Generate the PRD

Create a markdown document with these sections:

```markdown
# PRD: [Feature Name]

## Overview
Brief description of the feature and its purpose.

## Problem Statement
What problem are we solving? Why now?

## Target Users
Who benefits from this feature?

## Goals & Success Metrics
- Goal 1: [metric]
- Goal 2: [metric]

## User Stories

### US-001: [Story Title]
**As a** [user type]
**I want to** [action]
**So that** [benefit]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

**Priority:** High/Medium/Low
**Estimate:** S/M/L

[Repeat for each story]

## Technical Considerations
- Architecture notes
- Database changes
- API endpoints
- Security considerations

## Out of Scope
- Explicit list of what's NOT included

## Dependencies
- External systems
- Other features
- Third-party services

## Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Risk 1 | High | Mitigation strategy |

## Timeline
Rough estimates for each phase.
```

### 3. Save the PRD

Save the PRD to: `tasks/prd-[feature-name-kebab-case].md`

## Tips for Good PRDs

1. **Right-sized stories**: Each story should be completable in one coding session
2. **Clear acceptance criteria**: Binary pass/fail, not subjective
3. **Include quality gates**: typecheck, tests, lint must pass
4. **UI stories need browser verification**: Always include "Verify in browser" criterion
5. **Order by dependency**: Earlier stories shouldn't depend on later ones
6. **Include the "why"**: Context helps the implementer make good decisions

## Example Prompts

- "Create a PRD for adding dark mode to our app"
- "Create a PRD for implementing user notifications"
- "Create a PRD for building an admin dashboard"
- "Create a PRD for adding CSV export to the reports page"
