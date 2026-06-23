#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
CONFIG_DIR="$REPO_DIR/.local"
CONFIG_FILE="$CONFIG_DIR/config.json"

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Agent Skills Installation${NC}           ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

# Create directories
echo -e "${YELLOW}[1/4]${NC} Setting up directories..."
mkdir -p "$SKILLS_DIR"
mkdir -p "$CONFIG_DIR"

# Backup existing symlinks
if [ -d "$SKILLS_DIR" ] && [ "$(ls -A "$SKILLS_DIR" 2>/dev/null | wc -l)" -gt 0 ]; then
  echo -e "${YELLOW}[2/4]${NC} Removing old symlinks..."
  cd "$SKILLS_DIR"
  find . -maxdepth 1 -type l -delete 2>/dev/null || true
  cd "$REPO_DIR"
else
  echo -e "${YELLOW}[2/4]${NC} Skills directory is empty"
fi

# Create symlinks for each skill
echo -e "${YELLOW}[3/4]${NC} Creating symlinks..."
SKILL_COUNT=0
for skill_dir in "$REPO_DIR"/skills/*/; do
  if [ -d "$skill_dir" ]; then
    skill_name=$(basename "$skill_dir")
    link_target="$SKILLS_DIR/$skill_name"

    ln -s "$skill_dir" "$link_target" 2>/dev/null && \
      echo "  ✓ $skill_name" || \
      echo "  ✗ Failed to link $skill_name"

    ((SKILL_COUNT++))
  fi
done

if [ $SKILL_COUNT -eq 0 ]; then
  echo -e "${YELLOW}  No skills found in $REPO_DIR/skills/${NC}"
fi

# Create config file if it doesn't exist
echo -e "${YELLOW}[4/4]${NC} Creating configuration..."
if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" << EOF
{
  "repo_path": "$REPO_DIR",
  "skills_path": "$SKILLS_DIR",
  "machine_name": "$(hostname -s)",
  "installation_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "installation_method": "symlink",
  "skills_enabled": []
}
EOF
  echo "  ✓ Config created: $CONFIG_FILE"
else
  echo "  ✓ Config exists: $CONFIG_FILE"
fi

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Check status: $REPO_DIR/status.sh"
echo "  2. Update anytime: cd $REPO_DIR && git pull && ./sync.sh"
echo "  3. Create skills: mkdir skills/my-skill && cp skills/example/* skills/my-skill"
echo ""
echo "Skill location: $SKILLS_DIR"
echo "Config file: $CONFIG_FILE"
