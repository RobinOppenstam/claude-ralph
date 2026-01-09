# claude-ralph

An autonomous AI agent loop that runs Claude Code repeatedly until all PRD items are complete.
Each iteration is a fresh Claude Code instance with clean context.
Memory persists via git history, `progress.txt`, and `prd.json`.

## Quick Start

```bash
# 1. Copy claude-ralph files to your project
mkdir -p scripts/ralph
cp ralph.sh prompt.md prd.json.example scripts/ralph/
chmod +x scripts/ralph/ralph.sh

# 2. Create your prd.json (copy from example and edit)
cp scripts/ralph/prd.json.example scripts/ralph/prd.json

# 3. Run claude-ralph
./scripts/ralph/ralph.sh [max_iterations]
```

## File Structure

```
scripts/ralph/
├── ralph.sh          # Main loop script
├── ralph-once.sh     # Single iteration script
├── prompt.md         # Instructions for each Claude iteration
├── prd.json          # User stories with passes status
├── prd.json.example  # Example PRD format
├── progress.txt      # Append-only learnings log
└── skills/           # Claude Code skills
    ├── prd/SKILL.md      # PRD generation skill
    └── ralph/SKILL.md    # PRD to JSON conversion skill
```

## How It Works

1. **Loop starts** - Ralph reads `prd.json`
2. **Pick story** - Selects highest priority story where `passes: false`
3. **Implement** - Claude Code implements the story
4. **Quality check** - Runs typecheck, tests, lint
5. **Commit** - If checks pass, commits changes
6. **Update PRD** - Marks story as `passes: true`
7. **Log learnings** - Appends to `progress.txt`
8. **Repeat** - Until all stories pass or max iterations reached

## Key Concepts

### Fresh Context Each Iteration
Each iteration spawns a NEW Claude Code instance with clean context.
Memory persists only through:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

### Small Stories
Each story must be small enough to complete in one context window.
Right-sized examples:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

Too big (split these):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### CLAUDE.md Updates
Ralph updates CLAUDE.md files with learnings so future iterations benefit.
These are automatically read by Claude Code in subsequent runs.

## Commands

```bash
# Run Ralph loop
./scripts/ralph/ralph.sh 10

# Run single iteration
./scripts/ralph/ralph-once.sh

# Check status
cat scripts/ralph/prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings
cat scripts/ralph/progress.txt

# Check git history
git log --oneline -10
```

## Tips

- **Start small**: Begin with 3-4 iterations, review, then continue
- **Clear criteria**: Vague acceptance criteria = vague code
- **Include quality checks**: Always have typecheck/test in criteria
- **Browser verify UI**: Frontend stories need visual verification
- **Review progress.txt**: See what Ralph learned
