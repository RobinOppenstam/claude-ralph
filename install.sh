#!/bin/bash
# Ralph for Claude Code - Installation Script
# Usage: ./install.sh [target_directory]

set -e

TARGET_DIR="${1:-scripts/ralph}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║     RALPH FOR CLAUDE CODE - INSTALLER                 ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check for Claude Code CLI
echo -e "${YELLOW}Checking dependencies...${NC}"

if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude Code CLI found${NC}"
else
    echo -e "${RED}✗ Claude Code CLI not found${NC}"
    echo "  Install with: npm install -g @anthropic-ai/claude-code"
    echo "  Then run: claude (to authenticate)"
    MISSING_DEPS=1
fi

if command -v jq &> /dev/null; then
    echo -e "${GREEN}✓ jq found${NC}"
else
    echo -e "${RED}✗ jq not found${NC}"
    echo "  Install with: brew install jq (macOS) or apt install jq (Linux)"
    MISSING_DEPS=1
fi

if command -v git &> /dev/null; then
    echo -e "${GREEN}✓ git found${NC}"
else
    echo -e "${RED}✗ git not found${NC}"
    MISSING_DEPS=1
fi

if [ -n "$MISSING_DEPS" ]; then
    echo ""
    echo -e "${RED}Please install missing dependencies and try again.${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Installing to: $TARGET_DIR${NC}"

# Create target directory
mkdir -p "$TARGET_DIR"
mkdir -p "$TARGET_DIR/skills/prd"
mkdir -p "$TARGET_DIR/skills/ralph"

# Copy files
cp "$SCRIPT_DIR/ralph.sh" "$TARGET_DIR/"
cp "$SCRIPT_DIR/ralph-once.sh" "$TARGET_DIR/"
cp "$SCRIPT_DIR/prompt.md" "$TARGET_DIR/"
cp "$SCRIPT_DIR/prd.json.example" "$TARGET_DIR/"
cp "$SCRIPT_DIR/progress.txt.template" "$TARGET_DIR/"
cp "$SCRIPT_DIR/skills/prd/SKILL.md" "$TARGET_DIR/skills/prd/"
cp "$SCRIPT_DIR/skills/ralph/SKILL.md" "$TARGET_DIR/skills/ralph/"

# Make scripts executable
chmod +x "$TARGET_DIR/ralph.sh"
chmod +x "$TARGET_DIR/ralph-once.sh"

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Create your prd.json:"
echo "     cp $TARGET_DIR/prd.json.example $TARGET_DIR/prd.json"
echo "     # Then edit prd.json with your user stories"
echo ""
echo "  2. Run Ralph:"
echo "     $TARGET_DIR/ralph.sh 10"
echo ""
echo "  Or use the skills to generate a PRD:"
echo "     claude"
echo "     > Load the prd skill and create a PRD for [your feature]"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
