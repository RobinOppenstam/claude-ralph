#!/bin/bash
# Ralph Single Run - Execute one iteration only
# Useful for testing or manual control
# Usage: ./ralph-once.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
PROMPT_FILE="$SCRIPT_DIR/prompt.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check dependencies
if ! command -v claude &> /dev/null; then
    echo -e "${RED}Error: Claude Code CLI not found${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq not found${NC}"
    exit 1
fi

if [ ! -f "$PRD_FILE" ]; then
    echo -e "${RED}Error: prd.json not found${NC}"
    exit 1
fi

# Get status
TOTAL=$(jq '.userStories | length' "$PRD_FILE")
COMPLETE=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
REMAINING=$((TOTAL - COMPLETE))

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}           RALPH SINGLE ITERATION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "Stories: ${GREEN}$COMPLETE${NC}/$TOTAL complete, ${YELLOW}$REMAINING${NC} remaining"
echo ""

if [ "$REMAINING" -eq 0 ]; then
    echo -e "${GREEN}All stories already complete!${NC}"
    exit 0
fi

# Run Claude Code
echo -e "${YELLOW}Running Claude Code...${NC}"
echo ""

# Change to project root so Claude works on project files, not ralph files
cd "$PROJECT_ROOT"
OUTPUT=$(claude -p "$(cat "$PROMPT_FILE")" \
    --dangerously-skip-permissions \
    --verbose \
    2>&1 | tee /dev/stderr) || true
cd "$SCRIPT_DIR"

# Check completion
if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo -e "${GREEN}✅ All stories complete!${NC}"
else
    # Show updated status
    COMPLETE_NEW=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "Completed: ${GREEN}$COMPLETE_NEW${NC}/$TOTAL stories"
    
    if [ "$COMPLETE_NEW" -gt "$COMPLETE" ]; then
        echo -e "${GREEN}Progress made! Run again to continue.${NC}"
    else
        echo -e "${YELLOW}No new stories completed. Check progress.txt for details.${NC}"
    fi
fi
