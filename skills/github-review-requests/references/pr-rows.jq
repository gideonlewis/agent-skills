# Chuyển kết quả references/pr-search.graphql thành dòng bảng Markdown.
# Mỗi PR một dòng: <rank>\t<updatedAt ISO>\t| Repo | PR | Người gửi | Trạng thái | Cập nhật |
# Hai cột đầu chỉ để sort, pr-table.sh cắt bỏ trước khi in.
# Truyền --arg now "$(date -u +%s)" và --argjson stale_days 14.

def is_bot: test("\\[bot\\]$|^copilot-pull-request-reviewer$|^github-actions$");
def names: if length == 0 then "" else ": " + join(", ") end;

.data.search.nodes[]
| select(.number != null)
| (.latestReviews.nodes | map(select(.author.login | is_bot | not))) as $reviews
| ([.reviewRequests.nodes[].requestedReviewer | .login // .slug]) as $pending
| ([$reviews[] | select(.state == "CHANGES_REQUESTED") | .author.login]) as $requesters
| (($now | tonumber) - (.updatedAt | fromdateiso8601) > $stale_days * 86400) as $stale
| (if .isDraft then [3, "📝 Draft"]
   elif .reviewDecision == "CHANGES_REQUESTED" then [1, "🔁 Changes requested" + ($requesters | names)]
   elif .reviewDecision == "APPROVED" then [2, "✅ Approved"]
   else [0, "⏳ Awaiting review" + ($pending | names)] end) as $st
| (.title | gsub("\\|"; "/") | if length > 60 then .[:60] + "…" else . end) as $title
| [
    ($st[0] + (if $stale then 10 else 0 end)),
    .updatedAt,
    ("| " + (.repository.nameWithOwner | sub("^Finatext/"; ""))
     + " | [#\(.number) \($title)](\(.url))"
     + " | " + .author.login
     + " | " + (if $stale then "💤 " else "" end) + $st[1]
     + " | " + (.updatedAt | fromdateiso8601 | strflocaltime("%m-%d %H:%M"))
     + " |")
  ]
| @tsv
