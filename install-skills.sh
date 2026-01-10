#!/bin/bash
# Install ralph skills globally for Claude Code
# Usage: ./install-skills.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.config/claude/skills"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}     Installing Ralph Skills for Claude Code${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Create skills directory
echo -e "Creating skills directory: ${SKILLS_DIR}"
mkdir -p "$SKILLS_DIR"

# Copy skills
echo -e "Copying skills..."
cp -r "$SCRIPT_DIR/skills/prd" "$SKILLS_DIR/"
echo -e "  ${GREEN}✓${NC} prd skill installed"

cp -r "$SCRIPT_DIR/skills/ralph" "$SKILLS_DIR/"
echo -e "  ${GREEN}✓${NC} ralph skill installed"

cp -r "$SCRIPT_DIR/skills/dev-browser" "$SKILLS_DIR/"
echo -e "  ${GREEN}✓${NC} dev-browser skill installed"

echo ""
echo -e "${GREEN}Success!${NC} Skills installed to: $SKILLS_DIR"
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo -e "  Start Claude Code: ${BLUE}claude${NC}"
echo -e "  Then in conversation:"
echo -e "    - Load the prd skill and create a PRD for [feature]"
echo -e "    - Load the ralph skill and convert tasks/prd-[name].md to prd.json"
echo -e "    - Load the dev-browser skill and verify [page]"
echo ""
echo -e "${YELLOW}Verify installation:${NC}"
echo -e "  ${BLUE}ls -la $SKILLS_DIR${NC}"
echo ""
