# References — spc-collab-daily-sheet-sync

| File | Nội dung |
|---|---|
| `collect.py` | `window`: khung `[since, until)` giờ VN (mặc định 05:00 → bây giờ) + tham số API. `members`: tập thành viên (mặc định `members.json`, hoặc danh sách truyền vào). `build`: lọc Mattermost + activity Backlog theo khung và thành viên, gom task con vào ticket cha, chỉ giữ loại ticket report, gắn thread vào ticket, in `todo` cần gọi bổ sung |
| `sources.json` | Cấu hình cố định: channel Mattermost, bot cần loại, project Backlog, `report_issue_types` (JP User Story, Bug, JP Bug, JP Request, JP Feedback), `default_since` |
| `members.json` | 12 thành viên mặc định (DEV/PO/BrSE/QC): `nickname`, tên Backlog, `backlog_id`, username Mattermost, email, vai trò. Team đổi thì sửa file này |
| `spcc-statuses.json` | Map status id → tên của SPCC (snapshot 2026-09-29). Status hiện dạng số → lấy lại bằng `get_status_list_of_project` |
| `preview-format.md` | Format preview theo từng ticket report (dòng task con, căn cứ, bảng Cũ → Mới, Cần xác nhận, Không đưa lên sheet) và bảng map status Backlog → cột `Status` |

Quy tắc ghi từng cột và `config.json` của sheet nằm ở skill `spc-collab-daily-sheet`.
