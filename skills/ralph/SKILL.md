# Ralph PRD Conversion Skill

This skill converts a markdown PRD into the JSON format that Ralph needs to run autonomously.

## Usage

Load this skill and say: "Convert [path/to/prd.md] to prd.json"

## Process

### 1. Read the Markdown PRD

Parse the PRD document and extract:
- Feature name
- User stories with their acceptance criteria
- Technical context
- Quality check commands

### 2. Generate Branch Name

Create a branch name following the pattern: `ralph/[feature-name-kebab-case]`

### 3. Determine Priority Order

Order stories by:
1. Explicit priority if specified
2. Dependencies (stories that others depend on come first)
3. Order they appear in the document

### 4. Output JSON Format

Generate this structure:

```json
{
  "featureName": "Feature Name",
  "branchName": "ralph/feature-name",
  "description": "Brief description from PRD overview",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "priority": 1,
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "typecheck passes",
        "tests pass"
      ],
      "passes": false,
      "notes": "Any additional context"
    }
  ],
  "qualityChecks": {
    "typecheck": "npm run typecheck",
    "test": "npm test",
    "lint": "npm run lint"
  },
  "techStack": {
    "framework": "detected or specified",
    "database": "detected or specified",
    "testing": "detected or specified"
  }
}
```

### 5. Save to prd.json

Save the output to: `scripts/ralph/prd.json` (or the ralph directory in your project)

## Critical Conversion Rules

### Story Size
- Each story must be small enough to complete in one context window
- If a story seems too large, suggest breaking it down
- Rule of thumb: If you need more than ~1000 tokens to explain it, it's too big

### Acceptance Criteria
- Convert checkbox items to string array
- Always include quality checks:
  - "typecheck passes" for TypeScript projects
  - "tests pass" if tests are mentioned
  - "lint passes" if linting is mentioned
- For UI stories, include "Verify in browser"

### All Stories Start False
- Every story must have `"passes": false`
- Ralph will update this as stories complete

### Notes Field
- Include any context from the PRD that helps implementation
- Reference existing patterns mentioned
- Include file paths if specified

## Example Conversion

**Input (markdown):**
```markdown
### US-001: Add user avatar upload
**As a** user
**I want to** upload a profile picture
**So that** other users can identify me

**Acceptance Criteria:**
- [ ] Upload button in profile settings
- [ ] Accept PNG and JPG under 5MB
- [ ] Store in S3 bucket
- [ ] Display thumbnail in navbar
```

**Output (JSON):**
```json
{
  "id": "US-001",
  "title": "Add user avatar upload",
  "priority": 1,
  "acceptanceCriteria": [
    "Upload button in profile settings",
    "Accept PNG and JPG under 5MB",
    "Store in S3 bucket",
    "Display thumbnail in navbar",
    "typecheck passes",
    "tests pass",
    "Verify in browser that upload works"
  ],
  "passes": false,
  "notes": "UI story - requires browser verification"
}
```

## Commands

After conversion, remind the user:

```bash
# To start Ralph:
./scripts/ralph/ralph.sh [max_iterations]

# To check status:
cat scripts/ralph/prd.json | jq '.userStories[] | {id, title, passes}'

# To see progress:
cat scripts/ralph/progress.txt
```
