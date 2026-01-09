#!/bin/bash
# Ralph Status - Check current progress
# Usage: ./ralph-status.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ ! -f "$PRD_FILE" ]; then
    echo -e "${RED}No prd.json found in $SCRIPT_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}              RALPH STATUS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Feature info
FEATURE=$(jq -r '.featureName // "Unknown"' "$PRD_FILE")
BRANCH=$(jq -r '.branchName // "Unknown"' "$PRD_FILE")
echo -e "${YELLOW}Feature:${NC} $FEATURE"
echo -e "${YELLOW}Branch:${NC} $BRANCH"
echo ""

# Story counts
TOTAL=$(jq '.userStories | length' "$PRD_FILE")
COMPLETE=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
REMAINING=$((TOTAL - COMPLETE))

# Progress bar
PERCENT=$((COMPLETE * 100 / TOTAL))
BAR_WIDTH=40
FILLED=$((PERCENT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))

echo -ne "${YELLOW}Progress:${NC} ["
for ((i=0; i<FILLED; i++)); do echo -ne "${GREEN}█${NC}"; done
for ((i=0; i<EMPTY; i++)); do echo -ne "░"; done
echo -e "] ${PERCENT}%"
echo ""

echo -e "${GREEN}✓ Complete:${NC} $COMPLETE"
echo -e "${YELLOW}○ Remaining:${NC} $REMAINING"
echo -e "${BLUE}Total:${NC} $TOTAL"
echo ""

# List stories
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}              STORIES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

jq -r '.userStories[] | 
    if .passes then 
        "\u001b[32m✓\u001b[0m \(.id): \(.title)" 
    else 
        "\u001b[33m○\u001b[0m \(.id): \(.title)" 
    end' "$PRD_FILE"

echo ""

# Show next story if any remaining
if [ "$REMAINING" -gt 0 ]; then
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              NEXT UP${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    
    NEXT=$(jq -r '[.userStories[] | select(.passes == false)] | sort_by(.priority) | .[0] | "\(.id): \(.title)"' "$PRD_FILE")
    echo -e "${YELLOW}$NEXT${NC}"
    echo ""
    
    echo "Run: ./ralph.sh to continue"
else
    echo -e "${GREEN}🎉 All stories complete!${NC}"
fi
