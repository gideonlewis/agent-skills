# References — github-review-requests

| File | Nội dung |
|---|---|
| `pr-table.sh` | Entry point: nhận các filter GitHub search, chạy query, gộp + bỏ trùng + sort, in bảng Markdown cố định. Biến: `REPOS`, `STALE_DAYS`, `INCLUDE_DRAFT`. |
| `pr-search.graphql` | Query GraphQL tìm PR: reviewDecision, reviewer đang chờ, review mới nhất, thời điểm cập nhật. |
| `pr-rows.jq` | Chuyển kết quả query thành dòng bảng (kèm 2 cột sort nội bộ), tính cột Trạng thái, lọc bot, đánh dấu tồn đọng. |

`SKILL.md` chỉ gọi `pr-table.sh`. Đổi format bảng thì sửa `pr-rows.jq` (nội
dung dòng) và header trong `pr-table.sh`, rồi cập nhật ví dụ trong `SKILL.md`.
