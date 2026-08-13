#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Ép locale UTF-8 khi máy chưa có LANG/LC_ALL: bash 3.2 (mặc định trên macOS)
# cắt chuỗi theo byte thay vì ký tự nếu thiếu locale UTF-8, làm vỡ tiếng Việt
# dấu khi truncate mô tả skill (vd "định" -> "đ<byte lỗi>"). Không ghi đè nếu
# người dùng đã tự cấu hình locale riêng.
if [ -z "$LC_ALL" ] && [ -z "$LANG" ]; then
  if locale -a 2>/dev/null | grep -qi '^en_US\.UTF-8$'; then
    export LC_ALL=en_US.UTF-8
  elif locale -a 2>/dev/null | grep -qi '^C\.UTF-8$'; then
    export LC_ALL=C.UTF-8
  fi
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DIR="$HOME/.claude/skills"
CONFIG_DIR="$REPO_DIR/.local"
CONFIG_FILE="$CONFIG_DIR/config.json"
TERM_WIDTH="$(tput cols 2>/dev/null || echo 80)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

usage() {
  # printf %b để diễn giải \033 trong biến màu — "cat <<EOF" không làm điều đó.
  printf '%b\n' "${BOLD}Cách dùng:${NC} ./install.sh [tùy chọn] [tên-skill ...]"
  printf '\n'
  printf '%s\n' "Không truyền gì cả sẽ mở menu chọn skill tương tác."
  printf '\n'
  printf '%b\n' "${BOLD}Tùy chọn:${NC}"
  printf '%s\n' "  -a, --all       Cài tất cả skill, không hỏi"
  printf '%s\n' "  -l, --list      Liệt kê skill kèm mô tả rồi thoát, không cài gì"
  printf '%s\n' "  -y, --yes       Bỏ qua bước xác nhận (dùng với tên skill hoặc --all)"
  printf '%s\n' "  -h, --help      Hiện hướng dẫn này"
  printf '\n'
  printf '%b\n' "${BOLD}Ví dụ:${NC}"
  printf '%s\n' "  ./install.sh                    # mở menu chọn tương tác"
  printf '%s\n' "  ./install.sh --all               # cài tất cả"
  printf '%s\n' "  ./install.sh spec plan build     # chỉ cài 3 skill này"
  printf '%s\n' "  ./install.sh --list               # xem danh sách + mô tả"
  printf '\n'
  printf '%s\n' "Lựa chọn được lưu vào $CONFIG_FILE — lần \`./sync.sh\` tiếp theo sẽ chỉ"
  printf '%s\n' "đồng bộ đúng các skill đã chọn, không tự thêm skill khác vào."
}

# In tất cả tên thư mục skill hợp lệ trong repo, đã sort.
list_all_skills() {
  for d in "$SKILLS_SRC"/*/; do
    [ -d "$d" ] && [ -f "${d}SKILL.md" ] && basename "$d"
  done | sort
}

# Lấy mô tả một dòng của skill từ frontmatter SKILL.md (hỗ trợ cả
# `description: text` một dòng lẫn `description: >` dạng block).
skill_description() {
  local file="$SKILLS_SRC/$1/SKILL.md"
  [ -f "$file" ] || return 0
  awk '
    BEGIN { indoc=0; indesc=0; out="" }
    /^---[ \t]*$/ { indoc++; if (indoc==2) exit; next }
    indoc==1 && /^description:/ {
      line=$0
      sub(/^description:[ \t]*/, "", line)
      if (line ~ /^[>|][-+0-9]*[ \t]*$/) { indesc=1; next }
      gsub(/^[ \t"]+|[ \t"]+$/, "", line)
      out=line
      exit
    }
    indesc==1 {
      if ($0 !~ /^[ \t]/ || $0 ~ /^[a-zA-Z_-]+:/) exit
      s=$0
      gsub(/^[ \t]+/, "", s)
      out=out " " s
    }
    END { gsub(/^ +| +$/, "", out); print out }
  ' "$file"
}

# Cắt chuỗi cho vừa độ rộng terminal, thêm "…" nếu bị cắt.
truncate_text() {
  local text="$1" max="$2"
  if [ "${#text}" -le "$max" ]; then
    printf '%s' "$text"
  else
    printf '%s…' "${text:0:$((max - 1))}"
  fi
}

# Kiểm tra một phần tử có nằm trong mảng không (dùng cho validate arg).
array_contains() {
  local needle="$1"; shift
  for item in "$@"; do [ "$item" = "$needle" ] && return 0; done
  return 1
}

# In danh sách skill kèm mô tả, có đánh số. Nhận tên skill qua "$@" thay vì
# nameref ("local -n") — nameref cần bash 4.3+, còn /bin/bash mặc định trên
# macOS là bash 3.2 (Apple ngừng update vì lý do license).
print_skill_menu() {
  local desc_max=$((TERM_WIDTH - 10))
  [ "$desc_max" -lt 20 ] && desc_max=20
  local i=1
  local name desc
  for name in "$@"; do
    desc="$(skill_description "$name")"
    printf "  ${CYAN}%2d)${NC} ${BOLD}%-38s${NC}\n" "$i" "$name"
    if [ -n "$desc" ]; then
      printf "      ${DIM}%s${NC}\n" "$(truncate_text "$desc" "$desc_max")"
    fi
    i=$((i + 1))
  done
}

# ---------------------------------------------------------------------------
# Parse tham số dòng lệnh
# ---------------------------------------------------------------------------

ALL_MODE=false
LIST_MODE=false
ASSUME_YES=false
declare -a REQUESTED_SKILLS=()

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -a|--all) ALL_MODE=true; shift ;;
    -l|--list) LIST_MODE=true; shift ;;
    -y|--yes) ASSUME_YES=true; shift ;;
    --) shift; while [ $# -gt 0 ]; do REQUESTED_SKILLS+=("$1"); shift; done ;;
    -*)
      echo -e "${RED}Tùy chọn không hợp lệ: $1${NC}"
      usage
      exit 1
      ;;
    *) REQUESTED_SKILLS+=("$1"); shift ;;
  esac
done

# Không dùng "mapfile" (cần bash 4+) — đọc từng dòng bằng while/read để
# tương thích với bash 3.2 mặc định trên macOS.
declare -a ALL_SKILLS=()
while IFS= read -r line; do
  [ -n "$line" ] && ALL_SKILLS+=("$line")
done < <(list_all_skills)

if [ "${#ALL_SKILLS[@]}" -eq 0 ]; then
  echo -e "${RED}Không tìm thấy skill nào trong $SKILLS_SRC${NC}"
  exit 1
fi

if [ "$LIST_MODE" = true ]; then
  echo -e "${BOLD}Skill có sẵn (${#ALL_SKILLS[@]}):${NC}"
  echo ""
  print_skill_menu "${ALL_SKILLS[@]}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Xác định danh sách skill sẽ cài
# ---------------------------------------------------------------------------

declare -a SELECTED=()

if [ "${#REQUESTED_SKILLS[@]}" -gt 0 ]; then
  # Tên skill được truyền thẳng qua CLI — validate từng cái.
  declare -a unknown=()
  for name in "${REQUESTED_SKILLS[@]}"; do
    if array_contains "$name" "${ALL_SKILLS[@]}"; then
      SELECTED+=("$name")
    else
      unknown+=("$name")
    fi
  done
  if [ "${#unknown[@]}" -gt 0 ]; then
    echo -e "${YELLOW}Bỏ qua (không tìm thấy trong $SKILLS_SRC):${NC} ${unknown[*]}"
  fi
  if [ "${#SELECTED[@]}" -eq 0 ]; then
    echo -e "${RED}Không có skill hợp lệ nào được chọn. Dùng --list để xem tên đúng.${NC}"
    exit 1
  fi

elif [ "$ALL_MODE" = true ]; then
  SELECTED=("${ALL_SKILLS[@]}")

elif [ ! -t 0 ]; then
  # Không phải phiên tương tác (ví dụ chạy qua pipe/CI) — cài tất cả để
  # giữ hành vi tương thích ngược, nhưng nói rõ đang làm gì.
  echo -e "${YELLOW}Không phát hiện phiên tương tác → cài tất cả skill.${NC}"
  echo -e "${DIM}Dùng: ./install.sh spec plan build   (chọn cụ thể qua CLI)${NC}"
  SELECTED=("${ALL_SKILLS[@]}")

else
  echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   Agent Skills — Chọn Skill Để Cài      ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
  echo ""
  print_skill_menu "${ALL_SKILLS[@]}"
  echo ""
  echo -e "${DIM}Nhập số, cách nhau bằng dấu phẩy (vd: 1,3,5), có thể dùng khoảng${NC}"
  echo -e "${DIM}(vd: 1-4), hoặc gõ 'all' để chọn hết, 'q' để hủy.${NC}"
  echo ""
  read -r -p "Chọn skill: " selection

  selection="$(echo "$selection" | tr -d ' ')"

  if [ -z "$selection" ] || [ "$selection" = "q" ] || [ "$selection" = "Q" ]; then
    echo -e "${YELLOW}Đã hủy. Không cài gì cả.${NC}"
    exit 0
  fi

  if [ "$selection" = "all" ] || [ "$selection" = "ALL" ]; then
    SELECTED=("${ALL_SKILLS[@]}")
  else
    declare -a picked_idx=()
    IFS=',' read -ra parts <<< "$selection"
    for part in "${parts[@]}"; do
      if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
        for ((n = ${BASH_REMATCH[1]}; n <= ${BASH_REMATCH[2]}; n++)); do
          picked_idx+=("$n")
        done
      elif [[ "$part" =~ ^[0-9]+$ ]]; then
        picked_idx+=("$part")
      else
        echo -e "${YELLOW}Bỏ qua lựa chọn không hiểu: '$part'${NC}"
      fi
    done

    for idx in "${picked_idx[@]}"; do
      if [ "$idx" -ge 1 ] && [ "$idx" -le "${#ALL_SKILLS[@]}" ]; then
        name="${ALL_SKILLS[$((idx - 1))]}"
        array_contains "$name" "${SELECTED[@]:-}" || SELECTED+=("$name")
      else
        echo -e "${YELLOW}Bỏ qua số ngoài phạm vi: $idx${NC}"
      fi
    done
  fi

  if [ "${#SELECTED[@]}" -eq 0 ]; then
    echo -e "${RED}Không có skill nào được chọn hợp lệ. Dừng lại.${NC}"
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Xác nhận trước khi cài (bỏ qua nếu -y hoặc chạy không tương tác)
# ---------------------------------------------------------------------------

if [ "$ASSUME_YES" = false ] && [ -t 0 ]; then
  echo ""
  echo -e "${BOLD}Sẽ cài ${#SELECTED[@]}/${#ALL_SKILLS[@]} skill:${NC} ${SELECTED[*]}"
  read -r -p "Tiếp tục? [Y/n] " confirm
  case "$confirm" in
    n|N|no|No|NO)
      echo -e "${YELLOW}Đã hủy.${NC}"
      exit 0
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# Cài đặt
# ---------------------------------------------------------------------------

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Agent Skills Installation             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

echo -e "${YELLOW}[1/4]${NC} Chuẩn bị thư mục..."
mkdir -p "$SKILLS_DIR"
mkdir -p "$CONFIG_DIR"

echo -e "${YELLOW}[2/4]${NC} Dọn symlink cũ do repo này quản lý..."
if [ -d "$SKILLS_DIR" ]; then
  cd "$SKILLS_DIR"
  for link in */; do
    link="${link%/}"
    [ -L "$link" ] || continue
    target="$(readlink "$link")"
    case "$target" in
      "$SKILLS_SRC"/*) rm -f "$link" ;;
    esac
  done
  cd "$REPO_DIR"
fi

echo -e "${YELLOW}[3/4]${NC} Tạo symlink cho ${#SELECTED[@]} skill đã chọn..."
LINKED_COUNT=0
for skill_name in "${SELECTED[@]}"; do
  skill_dir="$SKILLS_SRC/$skill_name"
  link_target="$SKILLS_DIR/$skill_name"

  # Một thư mục THẬT ở đây sẽ che mất bản trong repo — không bao giờ tự xóa.
  if [ -d "$link_target" ] && [ ! -L "$link_target" ]; then
    echo -e "  ${RED}✗ $skill_name${NC} — có thư mục thật đang che repo, bỏ qua."
    echo "     Kiểm tra rồi xóa thủ công: $link_target"
    continue
  fi

  if ln -s "$skill_dir" "$link_target" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $skill_name"
    LINKED_COUNT=$((LINKED_COUNT + 1))
  else
    echo -e "  ${RED}✗ Không tạo được symlink: $skill_name${NC}"
  fi
done

echo -e "${YELLOW}[4/4]${NC} Ghi cấu hình..."

# Giữ nguyên installation_date gốc nếu config đã tồn tại từ trước.
INSTALL_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
if [ -f "$CONFIG_FILE" ]; then
  existing_date="$(grep -o '"installation_date": *"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)"
  [ -n "$existing_date" ] && INSTALL_DATE="$existing_date"
fi

SELECTION_MODE="custom"
[ "${#SELECTED[@]}" -eq "${#ALL_SKILLS[@]}" ] && SELECTION_MODE="all"

if command -v jq >/dev/null 2>&1; then
  SKILLS_JSON="$(printf '%s\n' "${SELECTED[@]}" | jq -R . | jq -s -c .)"
else
  SKILLS_JSON="["
  for i in "${!SELECTED[@]}"; do
    [ "$i" -gt 0 ] && SKILLS_JSON+=", "
    SKILLS_JSON+="\"${SELECTED[$i]}\""
  done
  SKILLS_JSON+="]"
fi

cat > "$CONFIG_FILE" <<EOF
{
  "repo_path": "$REPO_DIR",
  "skills_path": "$SKILLS_DIR",
  "machine_name": "$(hostname -s)",
  "installation_date": "$INSTALL_DATE",
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "installation_method": "symlink",
  "selection_mode": "$SELECTION_MODE",
  "skills_enabled": $SKILLS_JSON
}
EOF
echo -e "  ${GREEN}✓${NC} Config: $CONFIG_FILE"

echo ""
echo -e "${GREEN}✓ Cài đặt hoàn tất! ($LINKED_COUNT/${#SELECTED[@]} skill đã liên kết)${NC}"
echo ""
echo -e "${BOLD}Bước tiếp theo:${NC}"
echo "  1. Kiểm tra: $REPO_DIR/status.sh"
echo "  2. Cập nhật sau khi git pull: cd $REPO_DIR && ./sync.sh"
if [ "$SELECTION_MODE" = "custom" ]; then
  echo -e "     ${DIM}(sync.sh sẽ chỉ đồng bộ đúng ${#SELECTED[@]} skill đã chọn)${NC}"
fi
echo "  3. Đổi lựa chọn: ./install.sh (chạy lại để chọn lại từ đầu)"
echo ""
echo "Vị trí skill: $SKILLS_DIR"
echo "File config: $CONFIG_FILE"
