# claude-ralph

An autonomous AI agent loop that runs Claude Code repeatedly until all PRD items are complete.
Each iteration is a fresh Claude Code instance with clean context.
Memory persists via git history, `progress.txt`, and `prd.json`.

## Quick Start

```bash
# 1. Install ralph in scripts directory
mkdir -p scripts && cd scripts
git clone https://github.com/RobinOppenstam/claude-ralph ralph
chmod +x ralph/*.sh
cd ..

# 2. Create your prd.json (copy from example and edit)
cp scripts/ralph/prd.json.example scripts/ralph/prd.json

# 3. Run ralph from project root
./scripts/ralph/ralph.sh [max_iterations]
```

## File Structure

```
your-project/
├── scripts/
│   └── ralph/                    # Ralph files (self-contained)
│       ├── ralph.sh             # Main loop script
│       ├── ralph-once.sh        # Single iteration script
│       ├── ralph-status.sh      # Status checker
│       ├── prompt.md            # Instructions for each iteration
│       ├── prd.json             # User stories with passes status
│       ├── progress.txt         # Append-only learnings log
│       ├── ralph.log            # Execution log
│       ├── .last-branch         # Current branch tracker
│       ├── archive/             # Previous runs
│       └── skills/              # Claude Code skills
│
└── [Project root]                # Your project files
    ├── src/                      # Source code (created by Ralph)
    ├── package.json              # Dependencies (created by Ralph)
    └── ...                       # Other project files
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

Run these from your project root:

```bash
# Run Ralph loop
./scripts/ralph/ralph.sh 10

# Run single iteration
./scripts/ralph/ralph-once.sh

# Check status
./scripts/ralph/ralph-status.sh
# Or manually
cat scripts/ralph/prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings
cat scripts/ralph/progress.txt

# Check execution log
cat scripts/ralph/ralph.log

# Check git history
git log --oneline -10
```

## Tips

- **Start small**: Begin with 3-4 iterations, review, then continue
- **Clear criteria**: Vague acceptance criteria = vague code
- **Include quality checks**: Always have typecheck/test in criteria
- **Browser verify UI**: Frontend stories need visual verification
- **Review progress.txt**: See what Ralph learned
