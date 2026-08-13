# References — azuki-kinako-ui-adapter

Skill này tự chứa; các file dưới đây là phần chi tiết được tách ra để `SKILL.md` gọn, đọc khi tới
bước tương ứng.

| File | Nội dung | Khi nào đọc |
|---|---|---|
| `prop-mapping.md` | Mẫu bảng prop mapping, 7 nhóm prop, danh sách prop hay bị bỏ sót, và một bảng đã lập thật cho `MaterialIcon` | Bước 2, trước khi viết code |
| `hard-cases.md` | Hướng dẫn chi tiết nhóm D (enum đóng) và nhóm E (Kinako không có tương đương) — gồm cách quyết định prop bắt buộc/tuỳ chọn và khi nào nên giữ Vibe | Bước 2/3, khi component rơi vào D hoặc E |
| `example-prs.md` | Code thật từ 4 PR adapter: feature flag hook, `base.ts`, ví dụ đầy đủ cho nhóm A/B/C/D, test mẫu | Bước 3–6, để copy cấu trúc |
| `test-matrix.md` | Bảng khu vực cần test, khung 4 case tối thiểu, và ba cái bẫy khi assert | Bước 6 |
| `kinako-icon-enum.md` | Enum `IconType` của Kinako, prop `size`/`color` của `Icon`, phương pháp dựng bảng ánh xạ tập mở → enum đóng | Khi làm component liên quan tới icon |

Thêm reference mới khi có PR bổ sung pattern chưa từng gặp (form field, table, component có state
nội bộ) — cập nhật cả bảng trên lẫn file tương ứng.
