# Output format — spcc-activity-report

Đọc file này ở Bước 5, trước khi viết report. Format cố định để report giữa
các lần chạy so được với nhau và dán thẳng vào Mattermost được.

## Khung

````markdown
### Activity report SPCC — <label>
_<N> ticket · thành viên: <cả team | Vĩ, Định>_

#### [SPCC-3549](https://teq-dev.backlog.com/view/SPCC-3549) <title rút gọn ≤ 60 ký tự>
`JP User Story` · In Progress · Quân · Task con: 18 (15 Waiting For Release, 1 Ready For Test, 2 On Hold)
- **Đã làm:** 3555, 3562 BE Task verify DEV → Waiting For Release; 3560 → Ready For Test, chuyển Quân check (Tiên, 09:09–15:10)
- **Chốt:** release kịp 06/10 (Ngọc, 09:40)
- **Đang chờ:** 3560 chờ Quân check; 2 task On Hold chưa rõ hướng xử lý

#### [SPCC-3617](https://teq-dev.backlog.com/view/SPCC-3617) …
…

#### Khác
- Thread không gắn ticket: Ohagi tool tự fill dữ liệu test (Nam, 13:39)
- Bỏ qua 2 task không có ticket cha: [3720](https://teq-dev.backlog.com/view/SPCC-3720), [3721](https://teq-dev.backlog.com/view/SPCC-3721)

_Nguồn: Backlog SPCC, Mattermost SPC - dev (từ 02/10 05:00 đến 02/10 16:00)_

Cập nhật sheet theo report này: gọi spcc-daily-sheet-sync (report=~/.cache/spcc-activity-report/latest.json).
````

## Quy tắc

- **Một mục `####` = một ticket report** (JP User Story, Bug, JP Bug, JP
  Request, JP Feedback). Task / BE / FE / QC Task không bao giờ là một mục.
- **Thứ tự**: ticket có quyết định chốt hoặc ảnh hưởng release lên trước, rồi
  ticket có nhiều việc mới, rồi phần còn lại. Cùng mức → theo loại
  (`report_issue_types`) rồi theo mã.
- **Dòng thông tin** ngay dưới tiêu đề: loại · status hiện tại · assignee ·
  `Task con: <tổng> (<đếm theo status>)`. Không có task con → bỏ phần đó.
- **Bullet** — chỉ in bullet có nội dung, theo thứ tự:
  - `**Đã làm:**` việc đã xảy ra trong khung (Backlog + Mattermost), gộp theo
    ý; task con ghi mã rút gọn (`3555`) kèm loại khi lần đầu nhắc.
  - `**Chốt:**` quyết định đã chốt (ngày release, scope, cách test...).
  - `**Đang chờ:**` câu hỏi chưa trả lời, việc chờ ai đó, blocker.
  - Người + giờ để trong ngoặc cuối bullet: `(Tiên, 09:09–15:10)`.
- **Khác**: thread không gắn được ticket (một dòng chủ đề mỗi thread, bỏ
  thread chỉ có chào hỏi), task bị bỏ qua (gộp một dòng), ticket nhắc trong
  thread mà không tìm thấy trên Backlog. Không có gì → bỏ mục.
- Tên người dùng `nickname` trong `members.json`, **không có `@`**.
- Ngày viết `dd/mm`, giờ `HH:MM` giờ VN. Không dùng emoji.
- Heading `###` / `####` (Mattermost hiển thị `#`/`##` quá to).
- Không có ticket nào → dòng tiêu đề, `Không có hoạt động nào trên ticket
  report trong khung này.`, mục Khác nếu có, dòng nguồn.
- **Dòng nguồn**: in nghiêng; Mattermost có thể bị cắt → thêm
  `, Mattermost có thể thiếu` trước dấu `)`.

## Checklist trước khi trả

- [ ] Không mục nào là Task / BE / FE / QC Task.
- [ ] Mỗi ticket xuất hiện đúng một lần.
- [ ] Không có hoạt động ngoài khung, không có `@`.
- [ ] Mọi bullet có người + giờ trong ngoặc.
- [ ] Có dòng nguồn và dòng gợi ý cập nhật sheet ở cuối.
