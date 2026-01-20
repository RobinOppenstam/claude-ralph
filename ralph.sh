#!/bin/bash
# claude-ralph - Autonomous AI agent loop for Claude Code
# Port of snarktank/ralph for Claude Code CLI (uses Claude Max subscription)
# Usage: ./ralph.sh [max_iterations]

set -e

MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
LOG_FILE="$SCRIPT_DIR/ralph.log"
PROMPT_FILE="$SCRIPT_DIR/prompt.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$msg"
    echo "$msg" >> "$LOG_FILE"
}

# Check dependencies
check_dependencies() {
    if ! command -v claude &> /dev/null; then
        echo -e "${RED}Error: Claude Code CLI not found${NC}"
        echo "Install with: npm install -g @anthropic-ai/claude-code"
        echo "Then authenticate with: claude"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq not found${NC}"
        echo "Install with: brew install jq (macOS) or apt install jq (Linux)"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: git not found${NC}"
        exit 1
    fi
}

# Archive previous run if branch changed
archive_previous_run() {
    if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
        CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
        LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
        
        if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
            DATE=$(date +%Y-%m-%d)
            FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
            ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
            
            mkdir -p "$ARCHIVE_FOLDER"
            
            # Archive the files
            [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
            [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
            [ -f "$LOG_FILE" ] && cp "$LOG_FILE" "$ARCHIVE_FOLDER/"
            
            log "${YELLOW}Archived previous run to $ARCHIVE_FOLDER${NC}"
            
            # Clear progress for new feature
            rm -f "$PROGRESS_FILE"
        fi
    fi
}

# Save current branch
save_current_branch() {
    if [ -f "$PRD_FILE" ]; then
        BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
        if [ -n "$BRANCH" ]; then
            echo "$BRANCH" > "$LAST_BRANCH_FILE"
        fi
    fi
}

# Check if all stories are complete
all_stories_complete() {
    if [ ! -f "$PRD_FILE" ]; then
        return 1
    fi
    
    INCOMPLETE=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null || echo "1")
    [ "$INCOMPLETE" -eq 0 ]
}

# Get current status
get_status() {
    if [ ! -f "$PRD_FILE" ]; then
        echo "No PRD file found"
        return
    fi
    
    TOTAL=$(jq '.userStories | length' "$PRD_FILE" 2>/dev/null || echo "0")
    COMPLETE=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE" 2>/dev/null || echo "0")
    REMAINING=$((TOTAL - COMPLETE))
    
    echo -e "${CYAN}Stories: ${GREEN}$COMPLETE${NC}/${TOTAL} complete, ${YELLOW}$REMAINING${NC} remaining"
}

# Main loop
main() {
    check_dependencies
    
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                  claude-ralph                         ║"
    echo "║  Autonomous AI Agent Loop (Claude Subscription)       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    if [ ! -f "$PRD_FILE" ]; then
        echo -e "${RED}Error: prd.json not found in $SCRIPT_DIR${NC}"
        echo "Create a prd.json file with your user stories first."
        echo "See prd.json.example for the expected format."
        exit 1
    fi
    
    archive_previous_run
    save_current_branch
    
    # Initialize progress file if it doesn't exist
    if [ ! -f "$PROGRESS_FILE" ]; then
        cat > "$PROGRESS_FILE" << 'EOF'
# Ralph Progress Log
Started: $(date '+%Y-%m-%d %H:%M:%S')

## Codebase Patterns
(Patterns discovered during implementation will be added here)

---
EOF
    fi
    
    log "Starting Ralph with max $MAX_ITERATIONS iterations"
    get_status
    echo ""
    
    for ((i=1; i<=MAX_ITERATIONS; i++)); do
        echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}                    ITERATION $i / $MAX_ITERATIONS${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

        get_status

        # Check if already complete BEFORE starting work
        if all_stories_complete; then
            echo -e "${GREEN}✅ All stories complete! Exiting successfully.${NC}"
            log "All stories complete at iteration $i"
            exit 0
        fi

        log "Starting iteration $i"

        # Run Claude Code with the prompt
        # Using -p for non-interactive (print) mode
        # Using --dangerously-skip-permissions for full autonomy (like amp --dangerously-allow-all)
        # Using --verbose for detailed output
        echo -e "${YELLOW}Running Claude Code...${NC}"

        # Change to project root so Claude works on project files, not ralph files
        cd "$PROJECT_ROOT"
        OUTPUT=$(cat "$PROMPT_FILE" | claude -p \
            --dangerously-skip-permissions \
            --verbose \
            2>&1 | tee /dev/stderr) || {
            EXIT_CODE=$?
            log "⚠️  Claude Code exited with code $EXIT_CODE"
            cd "$SCRIPT_DIR"
            if [ $EXIT_CODE -ne 0 ]; then
                echo -e "${RED}Claude Code failed with exit code $EXIT_CODE${NC}"
                echo -e "${YELLOW}Continuing to next iteration...${NC}"
            fi
        }
        cd "$SCRIPT_DIR"

        # Log iteration result
        echo ""
        echo -e "${BLUE}Iteration $i completed. Checking status...${NC}"

        # Check for completion signal from Claude
        # Use grep -o to only match the exact tag, not mentions in code blocks or explanations
        # Count occurrences - should be exactly 1 if genuinely complete
        COMPLETE_COUNT=$(echo "$OUTPUT" | grep -o "<promise>COMPLETE</promise>" | wc -l || echo "0")

        # Only exit if we find the tag AND all stories are actually complete
        # This prevents false positives from Claude mentioning the tag in explanations
        if [ "$COMPLETE_COUNT" -gt 0 ] && all_stories_complete; then
            echo -e "${GREEN}"
            echo "╔═══════════════════════════════════════════════════════╗"
            echo "║              ✅ RALPH COMPLETE!                       ║"
            echo "║         All user stories have been implemented        ║"
            echo "╚═══════════════════════════════════════════════════════╝"
            echo -e "${NC}"
            log "✅ Done! All stories complete at iteration $i (verified via COMPLETE signal + PRD check)"
            exit 0
        elif [ "$COMPLETE_COUNT" -gt 0 ]; then
            log "⚠️  Claude output COMPLETE signal but PRD still has incomplete stories - ignoring false positive"
            echo -e "${YELLOW}Warning: Completion signal detected but stories remain incomplete. Continuing...${NC}"
        fi

        # IMPORTANT: Check again AFTER Claude runs in case it updated the PRD
        # This prevents early exit when there's still work to do
        if all_stories_complete; then
            echo -e "${GREEN}"
            echo "╔═══════════════════════════════════════════════════════╗"
            echo "║              ✅ RALPH COMPLETE!                       ║"
            echo "║         All user stories have been implemented        ║"
            echo "╚═══════════════════════════════════════════════════════╝"
            echo -e "${NC}"
            log "✅ Done! All stories verified complete at iteration $i (via PRD check)"
            exit 0
        fi

        # Show what's remaining
        REMAINING_NEW=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null || echo "?")
        if [ "$REMAINING_NEW" != "?" ] && [ "$REMAINING_NEW" -gt 0 ]; then
            echo -e "${YELLOW}${REMAINING_NEW} stories still remaining. Continuing...${NC}"
        fi

        # Brief pause between iterations
        if [ $i -lt $MAX_ITERATIONS ]; then
            echo -e "${YELLOW}Waiting 2 seconds before next iteration...${NC}"
            sleep 2
        fi
    done
    
    echo -e "${YELLOW}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║     ⚠️  Max iterations ($MAX_ITERATIONS) reached                     ║"
    echo "║     Some stories may still be incomplete              ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    get_status
    log "Max iterations reached. Check prd.json for remaining stories."
}

main "$@"
