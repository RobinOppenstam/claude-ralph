<p align="center">
  <img src="https://github.com/RobinOppenstam/claude-ralph/releases/download/assets/banner.jpg" alt="claude-ralph" width="100%">
</p>

# claude-ralph

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Ship features while you sleep — using your Claude Pro or Max subscription.**

An autonomous AI agent loop that runs **Claude Code** repeatedly until all PRD items are complete. Drop in a PRD, run the loop, wake up to a finished feature branch.

This is a port of [snarktank/ralph](https://github.com/snarktank/ralph) for **Claude Code CLI**, so you can use your existing **Claude Max subscription** instead of Amp credits.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

## Why claude-ralph?

The original Ralph uses [Amp CLI](https://ampcode.com) which requires Amp credits. This port:

- ✅ Uses **Claude Code CLI** (`claude -p`) 
- ✅ Works with your Claude Pro or Max subscription
- ✅ Same autonomous loop pattern
- ✅ Same PRD-driven workflow
- ✅ Includes browser verification for UI stories

## Prerequisites

- [Claude Code CLI](https://claude.ai/code) installed and authenticated
- `jq` installed (`brew install jq` on macOS, `apt install jq` on Linux)
- A git repository for your project
- Claude Max subscription (for token usage)
- [Playwright](https://playwright.dev) for UI verification (optional, for frontend stories)

```bash
# Install Playwright for UI story verification
npm install -D playwright
npx playwright install chromium
```

## Installation

### Option 1: Per-Project Installation (Recommended)

Copy the ralph files to your project's scripts directory:

```bash
# From your project root
mkdir -p scripts
cd scripts
git clone https://github.com/RobinOppenstam/claude-ralph ralph
chmod +x ralph/*.sh
cd ..
```

All ralph files (`prd.json`, `progress.txt`, `ralph.log`) stay in `scripts/ralph/`, while your project files (`src/`, `package.json`, etc.) remain in the project root. This keeps ralph self-contained and your project organized.

The skills in `scripts/ralph/skills/` are available automatically when running ralph from your project directory.

### Option 2: Install Skills Globally

To use ralph skills (`prd`, `ralph`, `dev-browser`) across **all projects** in interactive Claude Code sessions:

```bash
# Quick install (recommended)
./scripts/ralph/install-skills.sh

# Or manually copy skills
mkdir -p ~/.claude/skills
cp -r scripts/ralph/skills/prd ~/.claude/skills/
cp -r scripts/ralph/skills/ralph ~/.claude/skills/
cp -r scripts/ralph/skills/dev-browser ~/.claude/skills/
```

Now you can use these skills in **any project** by loading them in Claude Code:

```bash
claude
# Then in the Claude conversation:
# "Load the prd skill and create a PRD for user authentication"
# "Load the ralph skill and convert tasks/prd-auth.md to prd.json"
# "Load the dev-browser skill and verify the login page"
```

**Note:** Global installation is optional. Skills work from `scripts/ralph/skills/` when running ralph autonomously.

## Workflow

### 1. Create a PRD (Interactive)

Use the PRD skill to generate a detailed requirements document. Start Claude Code interactively:

```bash
# From your project root
claude
```

Then in the Claude conversation, explicitly load the skill and request a PRD:

```
Load the prd skill and create a PRD for [your feature description]
```

**Example:**
```
Load the prd skill and create a PRD for user authentication with email and password
```

**Note:** If the skill doesn't load, make sure you've installed skills globally (see [Installation](#option-2-install-skills-globally)).

Claude will ask clarifying questions (framework, UI requirements, etc.). Answer them in the conversation. The skill saves output to `tasks/prd-[feature-name].md`.

### 2. Convert PRD to Ralph Format (if needed)

Use the Ralph skill to convert the markdown PRD to JSON. In the same Claude session (or start a new one with `claude`):

```
Load the ralph skill and convert tasks/prd-[feature-name].md to prd.json
```

**Example:**
```
Load the ralph skill and convert tasks/prd-user-authentication.md to prd.json
```

This creates `scripts/ralph/prd.json` with user stories structured for autonomous execution. Each story has a `passes: false` flag that Ralph will update.

Exit Claude (Ctrl+C or type `exit`).

### 3. Run Ralph (Autonomous)

Now Ralph takes over. From your terminal (not in Claude):

```bash
./scripts/ralph/ralph.sh [max_iterations]
```

**Example:**
```bash
./scripts/ralph/ralph.sh 10
```

Default is 10 iterations. Run this from your project root directory.

Ralph will autonomously:

1. Create a feature branch (from PRD `branchName`)
2. Pick the highest priority story where `passes: false`
3. Spawn a fresh Claude Code instance to implement that single story
4. Run quality checks (typecheck, tests)
5. Commit if checks pass
6. Update `prd.json` to mark story as `passes: true`
7. Append learnings to `progress.txt`
8. Repeat until all stories pass or max iterations reached

**Key difference:** Steps 1-2 are **interactive** (you guide Claude), Step 3 is **autonomous** (Ralph loops without you).

## File Structure

```
your-project/
├── scripts/
│   └── ralph/                    # Ralph files (self-contained)
│       ├── ralph.sh             # Main loop script
│       ├── ralph-once.sh        # Single iteration script
│       ├── ralph-status.sh      # Status checker
│       ├── prompt.md            # Instructions for each Claude iteration
│       ├── prd.json             # User stories with passes status
│       ├── prd.json.example     # Example PRD format
│       ├── progress.txt         # Append-only learnings log
│       ├── ralph.log            # Execution log with timestamps
│       ├── .last-branch         # Current branch tracker
│       ├── archive/             # Previous runs
│       └── skills/              # Claude Code skills
│           ├── prd/             # PRD generation skill
│           └── ralph/           # PRD to JSON conversion skill
│
└── [Project root]                # Your project files
    ├── src/                      # Source code (created by Ralph)
    ├── package.json              # Dependencies (created by Ralph)
    ├── tsconfig.json             # Config (created by Ralph)
    └── ...                       # Other project files
```

## Key Differences from Original Ralph

| Feature | Original (Amp) | claude-ralph |
|---------|---------------|--------------|
| CLI | `amp` | `claude` |
| Non-interactive flag | `--dangerously-allow-all` | `-p --dangerously-skip-permissions` |
| Pricing | Amp credits | Claude Max subscription |
| Skills location | `~/.config/amp/skills/` | `~/.claude/skills/` |
| Project config | `AGENTS.md` | `CLAUDE.md` |

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new Claude Code instance** with clean context. The only memory between iterations is:

- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

### Small Tasks

Each PRD item should be small enough to complete in one context window. If a task is too big, Claude runs out of context before finishing and produces poor code.

**Right-sized stories:**
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

**Too big (split these):**
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### CLAUDE.md Updates Are Critical

After each iteration, Ralph updates the relevant `CLAUDE.md` files with learnings. This is key because Claude Code automatically reads these files, so future iterations benefit from discovered patterns.

### Stop Condition

When all stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>` and the loop exits.

## Debugging

Run these commands from your project root:

```bash
# See which stories are done
cat scripts/ralph/prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat scripts/ralph/progress.txt

# Check ralph execution log
cat scripts/ralph/ralph.log

# Check git history
git log --oneline -10

# Run single iteration for debugging
./scripts/ralph/ralph-once.sh

# Check status with nice formatting
./scripts/ralph/ralph-status.sh
```

## Customizing prompt.md

Edit `scripts/ralph/prompt.md` to customize Ralph's behavior for your project:

- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## Archiving

Ralph automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `scripts/ralph/archive/YYYY-MM-DD-feature-name/` and include the `prd.json`, `progress.txt`, and `ralph.log` from the previous run.

## Troubleshooting

### Claude Code not found
```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code
# Authenticate
claude
```

### Permission denied on ralph.sh
```bash
chmod +x scripts/ralph/*.sh
```

### jq not found
```bash
# macOS
brew install jq

# Ubuntu/Debian
apt install jq

# Windows (WSL)
apt install jq
```

### Skills not loading

If Claude Code can't find the skills, make sure they're installed globally:

```bash
# Install skills globally
mkdir -p ~/.claude/skills
cp -r scripts/ralph/skills/prd ~/.claude/skills/
cp -r scripts/ralph/skills/ralph ~/.claude/skills/
cp -r scripts/ralph/skills/dev-browser ~/.claude/skills/

# Verify they're installed
ls -la ~/.claude/skills/
```

Then load them explicitly:
```
Load the prd skill
Load the ralph skill
Load the dev-browser skill
```

### Ralph exits early (stories still incomplete)

**Symptom**: Ralph shows "✅ RALPH COMPLETE!" after only 2/11 tasks, or exits when stories remain incomplete.

**Cause**: Claude mentioned the completion tag `<promise>COMPLETE</promise>` in its reasoning or explanations (e.g., saying "I should NOT output `<promise>COMPLETE</promise>`"), which triggered the grep pattern in older versions.

**Fixed in v1.1.0+**: Ralph now uses dual verification:
1. The prompt explicitly warns Claude not to quote the completion tag
2. Ralph verifies BOTH tag presence AND that all PRD stories are actually complete before exiting

**If you encounter this**:

1. **Update ralph.sh** to the latest version from the repo (includes the dual verification fix)

2. **Check the status**:
   ```bash
   ./scripts/ralph/ralph-status.sh
   ```

3. **Review the log**:
   ```bash
   tail -50 scripts/ralph/ralph.log
   ```
   Look for the warning: "Claude output COMPLETE signal but PRD still has incomplete stories"

4. **Other common causes**:
   - Quality checks failing (typecheck, tests)
   - Story is too large for one iteration
   - PRD file corruption

5. **Debug with a single iteration**:
   ```bash
   ./scripts/ralph/ralph-once.sh
   ```
   This runs one iteration and shows what happened.

6. **Check PRD manually**:
   ```bash
   cat scripts/ralph/prd.json | jq '.userStories[] | {id, title, passes}'
   ```

## Quick Reference

```bash
# Install ralph in a project
mkdir -p scripts && cd scripts
git clone https://github.com/RobinOppenstam/claude-ralph ralph
chmod +x ralph/*.sh && cd ..

# Install skills globally (one-time setup, recommended)
./scripts/ralph/install-skills.sh

# Interactive PRD creation
claude
# "Load the prd skill and create a PRD for [feature]"
# "Load the ralph skill and convert tasks/prd-[name].md to prd.json"

# Run ralph autonomously
./scripts/ralph/ralph.sh 10

# Check status
./scripts/ralph/ralph-status.sh
cat scripts/ralph/prd.json | jq '.userStories[] | {id, title, passes}'

# Debug single iteration
./scripts/ralph/ralph-once.sh

# See learnings
cat scripts/ralph/progress.txt
```

## Credits

- Original Ralph: [snarktank/ralph](https://github.com/snarktank/ralph) by [Ryan Carson](https://x.com/ryancarson)
- Ralph Pattern: [Geoffrey Huntley](https://ghuntley.com/ralph/)
- Claude Code: [Anthropic](https://anthropic.com)

## License

MIT License - See [LICENSE](LICENSE) for details.