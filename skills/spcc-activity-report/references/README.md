# References — spcc-activity-report

| File | Nội dung |
|---|---|
| `collect.py` | `window`: khung `[since, until)` giờ VN (mặc định 05:00 → bây giờ) + tham số API. `members`: tập thành viên (mặc định `members.json`, hoặc danh sách truyền vào). `build`: lọc Mattermost + activity Backlog theo khung và thành viên, gom task con vào ticket cha, chỉ giữ loại ticket report, gắn thread vào ticket, in `todo` cần gọi bổ sung |
| `sources.json` | Cấu hình cố định: channel Mattermost, bot cần loại, project Backlog, `report_issue_types` (JP User Story, Bug, JP Bug, JP Request, JP Feedback), `default_since` |
| `members.json` | 12 thành viên mặc định (DEV/PO/BrSE/QC): `nickname`, tên Backlog, `backlog_id`, username Mattermost, email, vai trò. Team đổi thì sửa file này |
| `spcc-statuses.json` | Map status id → tên của SPCC (snapshot 2026-09-29). Status hiện dạng số → lấy lại bằng `get_status_list_of_project` |
| `output-format.md` | Format report theo ticket (dòng thông tin, Đã làm / Chốt / Đang chờ, mục Khác, dòng nguồn), checklist trước khi trả |

`report.json` được lưu ở `~/.cache/spcc-activity-report/` và là đầu vào cho chế độ report của `spcc-daily-sheet-sync` (xem `references/report-mode.md` của skill đó).
