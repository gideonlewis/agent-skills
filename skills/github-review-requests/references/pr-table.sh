#!/usr/bin/env bash
# In một bảng Markdown PR open (không draft) cho các filter truyền vào.
# Mỗi filter là một query GitHub search; kết quả gộp lại, bỏ trùng, sort theo
# trạng thái (Awaiting → Changes requested → Approved → tồn đọng) rồi mới nhất.
#
# Dùng: REPOS="azuki azuki-app cred-proto" pr-table.sh "<filter>" ["<filter>" ...]
# Ví dụ: pr-table.sh "user-review-requested:teq-quanhuynh" "author:vitranteq"
# Biến tuỳ chọn: STALE_DAYS (mặc định 14), INCLUDE_DRAFT=1 (lấy cả draft).
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
repos="${REPOS:-azuki azuki-app cred-proto}"
stale_days="${STALE_DAYS:-14}"
draft="draft:false"
[[ "${INCLUDE_DRAFT:-}" == "1" ]] && draft=""

repo_q=""
for r in $repos; do repo_q+=" repo:Finatext/$r"; done

rows="$(
  for f in "$@"; do
    json="$(gh api graphql -F query=@"$dir/pr-search.graphql" \
      -F q="is:pr is:open $draft archived:false$repo_q $f sort:updated-desc")"
    count="$(jq '.data.search.issueCount' <<<"$json")"
    (( count > 100 )) && echo "WARN: '$f' có $count PR, chỉ lấy 100" >&2
    jq -r --arg now "$(date -u +%s)" --argjson stale_days "$stale_days" \
      -f "$dir/pr-rows.jq" <<<"$json"
  done | sort -u | sort -t$'\t' -k1,1n -k2,2r | cut -f3-
)"

if [[ -z "$rows" ]]; then
  echo "Không có PR nào."
  exit 0
fi

echo "| Repo | PR | Người gửi | Trạng thái | Cập nhật |"
echo "|---|---|---|---|---|"
echo "$rows"
