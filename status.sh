#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
CONFIG_FILE="$REPO_DIR/.local/config.json"

echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}Agent Skills Status${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""

echo "📁 Repo location:"
echo "   $REPO_DIR"
echo ""

echo "🔗 Skills location (symlinks):"
echo "   $SKILLS_DIR"
echo ""

if [ ! -d "$SKILLS_DIR" ]; then
  echo "⚠️  Skills directory not found. Run: ./install.sh"
  exit 1
fi

echo "📦 Installed skills:"
if [ "$(ls -A "$SKILLS_DIR" 2>/dev/null | wc -l)" -eq 0 ]; then
  echo "   (none)"
else
  cd "$SKILLS_DIR"
  for link in */; do
    skill_name="${link%/}"
    target=$(readlink "$skill_name" 2>/dev/null || echo "broken")
    if [ "$target" = "broken" ]; then
      echo "   ✗ $skill_name (broken link)"
    else
      echo "   ✓ $skill_name"
    fi
  done
fi

echo ""

if [ -f "$CONFIG_FILE" ]; then
  echo "⚙️  Configuration:"
  echo "   Machine: $(grep -o '"machine_name": "[^"]*' "$CONFIG_FILE" | cut -d'"' -f4)"
  echo "   Installed: $(grep -o '"installation_date": "[^"]*' "$CONFIG_FILE" | cut -d'"' -f4)"
else
  echo "⚠️  Config not found. Run: ./install.sh"
fi

echo ""
echo -e "${YELLOW}Commands:${NC}"
echo "  ./sync.sh              Update after git pull"
echo "  ./install.sh           Fresh installation"
