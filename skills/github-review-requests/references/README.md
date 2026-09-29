# References — github-review-requests

| File | Nội dung |
|---|---|
| `pr-search.graphql` | Query GraphQL tìm PR (dùng với `gh api graphql -F q=...`): reviewDecision, reviewer đang chờ, review mới nhất, trạng thái CI của commit cuối. |
| `pr-rows.jq` | Chuyển kết quả query thành TSV một dòng/PR, đã phân loại status, lọc bot và đánh dấu tồn đọng. Cần `--arg now` và `--argjson stale_days`. |

Cả hai file được `SKILL.md` gọi trực tiếp ở Bước 2 — sửa cột ở `pr-rows.jq`
thì cập nhật luôn mô tả cột trong `SKILL.md`.
