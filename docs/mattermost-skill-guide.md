#### Hướng dẫn dùng skill daily SPCC (@eddiebot)

| Skill | Cách gọi | Usage |
|---|---|---|
| `spcc-daily-brief` | `@eddiebot spcc-daily-brief` · `day=2026-09-25` · `refresh` | Brief ngày làm việc trước (Thứ 2 gộp T6–CN) từ Backlog SPCC + SPC - dev: highlights, cần xác nhận, blockers, đổi status User Story. Tự đăng Backlog Document `Daily brief/<ngày>` |
| `spcc-activity-report` | `@eddiebot spcc-activity-report` · `since=09:00 until=12:00` · `members=Vĩ,Định` | Report hôm nay (mặc định 05:00 → lúc gọi) theo từng ticket (User Story / Bug / JP Bug / JP Request / JP Feedback, task con gộp vào cha): đã làm, đã chốt, đang chờ. Chỉ đọc |
| `spcc-daily-sheet-sync` | Trong thread: `@eddiebot spcc-daily-sheet-sync` · `preview` · Sau report: `@eddiebot cập nhật sheet theo report` | Cập nhật sheet "SPC Collab Sprint daily reports" (FE, BE, Status, Memo, Release…). Từ thread → ghi + reply cũ → mới. Từ report → preview theo ticket, trả lời `ok` / `ok 1,3` / `bỏ 2` / `2: BE = …` rồi mới ghi |
