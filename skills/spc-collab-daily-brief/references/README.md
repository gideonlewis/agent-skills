# References — spc-collab-daily-brief

| File | Nội dung |
|---|---|
| `output-format.md` | Format cố định của brief: khung heading, quy tắc từng mục, cách ghi owner/link, ví dụ chuẩn ngày 2026-09-28 và checklist trước khi trả. |
| `members.json` | Danh sách cố định 12 thành viên team (DEV/PO/BrSE/QC): tên Backlog, `backlog_id`, username Mattermost, email. Nguồn: nhóm người của `spc-collab-calendar` + member list SPCC trên Backlog. |
| `window.py` | Tính khung `[start, end)` theo giờ VN: mặc định là ngày làm việc trước (Thứ 2 gộp Thứ 6–CN), hoặc `--day` cho đúng 1 ngày. In ra dạng giờ VN, UTC ISO và epoch ms. |
| `backlog-activities.jq` | Lọc kết quả `get_user_recent_updates` theo project + khung thời gian, rút gọn thành `{at, by, type, keys, summary, changes, comment}`, đổi status id sang tên. |
| `spcc-statuses.json` | Snapshot map status id → tên của project SPCC (lấy ngày 2026-09-29). Nếu thấy status hiện ra dạng số thì lấy lại bằng `get_status_list_of_project`. |
| `mattermost-posts.jq` | Lọc kết quả `mattermost-read_channel` theo `create_at` trong khung, bỏ system message, gom theo thread, đánh dấu thread bắt đầu trước khung. |

Output của 2 file jq là dữ liệu trung gian để agent đọc rồi viết brief, không
dán thẳng cho user.
