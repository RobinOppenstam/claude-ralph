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

### Prerequisites

- [Claude Code CLI](https://claude.ai/code) installed and authenticated
- `jq` installed (`brew install jq` on macOS, `apt install jq` on Linux)
- A git repository for your project

### Setup

Clone claude-ralph and make the scripts executable:

```bash
git clone https://github.com/RobinOppenstam/claude-ralph
cd claude-ralph
chmod +x *.sh
```

The scripts run from inside the claude-ralph folder but work on your project in the parent directory (or specify a path). Your project stays clean - no extra files added to it.

## Workflow

### 1. Create a PRD

Use the PRD skill to generate a detailed requirements document:

```
Load the prd skill and create a PRD for [your feature description]
```

Answer the clarifying questions. The skill saves output to `tasks/prd-[feature-name].md`.

### 2. Convert PRD to Ralph Format

Use the Ralph skill to convert the markdown PRD to JSON:

```
Load the ralph skill and convert tasks/prd-[feature-name].md to prd.json
```

This creates `prd.json` with user stories structured for autonomous execution.

### 3. Run Ralph

```bash
./scripts/ralph/ralph.sh [max_iterations]
```

Default is 10 iterations.

Ralph will:

1. Create a feature branch (from PRD `branchName`)
2. Pick the highest priority story where `passes: false`
3. Implement that single story
4. Run quality checks (typecheck, tests)
5. Commit if checks pass
6. Update `prd.json` to mark story as `passes: true`
7. Append learnings to `progress.txt`
8. Repeat until all stories pass or max iterations reached

## File Structure

| File | Purpose |
|------|---------|
| `ralph.sh` | The bash loop that spawns fresh Claude Code instances |
| `ralph-once.sh` | Run a single iteration (for testing/debugging) |
| `prompt.md` | Instructions given to each Claude Code instance |
| `prd.json` | User stories with `passes` status (the task list) |
| `prd.json.example` | Example PRD format for reference |
| `progress.txt` | Append-only learnings for future iterations |
| `skills/prd/` | Skill for generating PRDs |
| `skills/ralph/` | Skill for converting PRDs to JSON |
| `skills/dev-browser/` | Browser automation for UI verification |

## Key Differences from Original Ralph

| Feature | Original (Amp) | claude-ralph |
|---------|---------------|--------------|
| CLI | `amp` | `claude` |
| Non-interactive flag | `--dangerously-allow-all` | `-p --dangerously-skip-permissions` |
| Pricing | Amp credits | Claude Max subscription |
| Skills location | `~/.config/amp/skills/` | `~/.claude/commands/` |
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

```bash
# See which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat progress.txt

# Check git history
git log --oneline -10

# Run single iteration for debugging
./ralph-once.sh
```

## Customizing prompt.md

Edit `prompt.md` to customize Ralph's behavior for your project:

- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## Archiving

Ralph automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `archive/YYYY-MM-DD-feature-name/`.

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
chmod +x ralph.sh ralph-once.sh
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

## Credits

- Original Ralph: [snarktank/ralph](https://github.com/snarktank/ralph) by [Ryan Carson](https://x.com/ryancarson)
- Ralph Pattern: [Geoffrey Huntley](https://ghuntley.com/ralph/)
- Claude Code: [Anthropic](https://anthropic.com)

## License

MIT License - See [LICENSE](LICENSE) for details.
