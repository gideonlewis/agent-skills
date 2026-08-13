#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
CONFIG_FILE="$REPO_DIR/.local/config.json"

echo -e "${GREEN}Syncing skills...${NC}"

# Nếu install.sh đã lưu một lựa chọn skill cụ thể (selection_mode: custom),
# chỉ đồng bộ đúng tập đó — không tự thêm skill khác vào máy.
declare -a ENABLED_SKILLS=()
if [ -f "$CONFIG_FILE" ] && grep -q '"selection_mode": *"custom"' "$CONFIG_FILE"; then
  # Không dùng "mapfile" (cần bash 4+) — /bin/bash mặc định trên macOS là
  # bash 3.2, đọc từng dòng bằng while/read để tương thích.
  if command -v jq >/dev/null 2>&1; then
    while IFS= read -r line; do
      [ -n "$line" ] && ENABLED_SKILLS+=("$line")
    done < <(jq -r '.skills_enabled[]?' "$CONFIG_FILE" 2>/dev/null)
  else
    while IFS= read -r line; do
      [ -n "$line" ] && ENABLED_SKILLS+=("$line")
    done < <(
      grep -o '"skills_enabled": *\[[^]]*\]' "$CONFIG_FILE" \
        | grep -o '"[^"]*"' | tail -n +2 | tr -d '"'
    )
  fi
  if [ "${#ENABLED_SKILLS[@]}" -gt 0 ]; then
    echo -e "${YELLOW}Dùng lựa chọn đã lưu (${#ENABLED_SKILLS[@]} skill): ${ENABLED_SKILLS[*]}${NC}"
    echo -e "  ${GREEN}→${NC} Cài lại tất cả: ./install.sh --all"
  fi
fi

in_enabled_set() {
  [ "${#ENABLED_SKILLS[@]}" -eq 0 ] && return 0 # không giới hạn -> mọi skill đều hợp lệ
  for s in "${ENABLED_SKILLS[@]}"; do [ "$s" = "$1" ] && return 0; done
  return 1
}

# Remove dead symlinks
echo -e "${YELLOW}Cleaning up removed skills...${NC}"
cd "$SKILLS_DIR" 2>/dev/null || exit 1
find . -maxdepth 1 -type l ! -exec test -d {} \; -delete 2>/dev/null || true

# Nếu có lựa chọn tùy chỉnh, gỡ symlink của những skill KHÔNG còn trong danh
# sách (repo-managed only — không đụng thư mục thật hoặc symlink từ nơi khác).
if [ "${#ENABLED_SKILLS[@]}" -gt 0 ]; then
  for link in */; do
    link="${link%/}"
    [ -L "$link" ] || continue
    target="$(readlink "$link")"
    case "$target" in
      "$REPO_DIR"/skills/*)
        in_enabled_set "$link" || { rm -f "$link"; echo "  − $link (ngoài lựa chọn đã lưu)"; }
        ;;
    esac
  done
fi
cd "$REPO_DIR"

# Recreate symlinks
echo -e "${YELLOW}Updating symlinks...${NC}"
UPDATED=0
for skill_dir in "$REPO_DIR"/skills/*/; do
  if [ -d "$skill_dir" ]; then
    skill_name=$(basename "$skill_dir")
    link_target="$SKILLS_DIR/$skill_name"

    in_enabled_set "$skill_name" || continue

    # A real directory here shadows the repo skill. Never delete it silently —
    # it may hold content that only exists on this machine.
    if [ -d "$link_target" ] && [ ! -L "$link_target" ]; then
      echo -e "  ${RED}✗ $skill_name${NC} — có thư mục thật đang che repo, bỏ qua."
      echo "     Kiểm tra rồi xoá thủ công: $link_target"
      continue
    fi

    # Remove old symlink if exists
    rm -f "$link_target" 2>/dev/null || true

    # Create new symlink.
    # Note: use UPDATED=$((...)) not ((UPDATED++)) — the latter returns exit 1
    # when UPDATED is 0, which kills the script under `set -e`.
    if ln -s "$skill_dir" "$link_target" 2>/dev/null; then
      echo "  ✓ $skill_name"
      UPDATED=$((UPDATED + 1))
    else
      echo -e "  ${RED}✗ $skill_name${NC} — không tạo được symlink."
    fi
  fi
done

echo ""
echo -e "${GREEN}✓ Sync complete! ($UPDATED skills updated)${NC}"
