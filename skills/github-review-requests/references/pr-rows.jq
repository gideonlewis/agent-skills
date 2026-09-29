# Chuyển kết quả references/pr-search.graphql thành TSV, mỗi PR một dòng.
# Cột: repo, number, url, title, author, status, ci, pending_reviewers,
#      approvers, changes_requested_by, updated (YYYY-MM-DD), stale (true/false)
# Truyền --arg now "$(date -u +%s)" và --argjson stale_days 14.

def is_bot: test("\\[bot\\]$|^copilot-pull-request-reviewer$|^github-actions$");

.data.search.nodes[]
| select(.number != null)
| (.latestReviews.nodes | map(select(.author.login | is_bot | not))) as $reviews
| [
    (.repository.nameWithOwner | sub("^Finatext/"; "")),
    .number,
    .url,
    (.title | gsub("\\|"; "/")),
    .author.login,
    (if .isDraft then "DRAFT"
     elif .reviewDecision == "CHANGES_REQUESTED" then "CHANGES_REQUESTED"
     elif .reviewDecision == "APPROVED" then "APPROVED"
     else "REVIEW_REQUIRED" end),
    (.commits.nodes[0].commit.statusCheckRollup.state // "NONE"),
    ([.reviewRequests.nodes[].requestedReviewer | .login // ("@" + .slug)] | join(", ")),
    ([$reviews[] | select(.state == "APPROVED") | .author.login] | join(", ")),
    ([$reviews[] | select(.state == "CHANGES_REQUESTED") | .author.login] | join(", ")),
    .updatedAt[:10],
    (($now | tonumber) - (.updatedAt | fromdateiso8601) > $stale_days * 86400)
  ]
| @tsv
