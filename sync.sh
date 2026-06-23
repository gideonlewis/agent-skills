#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

echo -e "${GREEN}Syncing skills...${NC}"

# Remove dead symlinks
echo -e "${YELLOW}Cleaning up removed skills...${NC}"
cd "$SKILLS_DIR" 2>/dev/null || exit 1
find . -maxdepth 1 -type l ! -exec test -d {} \; -delete 2>/dev/null || true

# Recreate symlinks
echo -e "${YELLOW}Updating symlinks...${NC}"
UPDATED=0
for skill_dir in "$REPO_DIR"/skills/*/; do
  if [ -d "$skill_dir" ]; then
    skill_name=$(basename "$skill_dir")
    link_target="$SKILLS_DIR/$skill_name"

    # Remove old symlink if exists
    rm -f "$link_target" 2>/dev/null || true

    # Create new symlink
    ln -s "$skill_dir" "$link_target" 2>/dev/null && \
      echo "  ✓ $skill_name" && \
      ((UPDATED++))
  fi
done

echo ""
echo -e "${GREEN}✓ Sync complete! ($UPDATED skills updated)${NC}"
