# References — azuki-feature-flag-cleanup-verify

TPD — chưa có reference nào cho skill `azuki-feature-flag-cleanup-verify`.

Thư mục này chứa checklist, fixture, snapshot metadata, hoặc tài liệu tham
chiếu mà `SKILL.md` trỏ tới. Thêm file `.md` vào đây rồi tham chiếu từ
`SKILL.md` bằng đường dẫn tương đối, ví dụ `references/checklist.md`.

Ứng viên cho reference trong tương lai:

- Bảng "baseline đã biết" của từng repo: danh sách test/tsc error pre-existing
  tại một thời điểm, để khỏi phải chạy `git stash` so sánh lại mỗi lần
  (ví dụ azuki-app: 8 test file fail do cred-proto local cũ, tính đến 2026-09).
- Danh sách flag cha-con đã biết, để Layer 6 tra nhanh thay vì grep.
