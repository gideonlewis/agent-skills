---
name: spc-collab-daily-sheet-sync
description: >
  Tổng hợp thông tin trong ngày để cập nhật Google Sheet "SPC Collab Sprint
  daily reports": lấy trao đổi/quyết định trên Mattermost "SPC - dev" và
  activity Backlog SPCC của các thành viên (mặc định cả team trong
  members.json, truyền được danh sách khác), trong khung mặc định TỪ 05:00
  SÁNG NAY tới lúc gọi (truyền được `since`/`until`). Ticket Backlog được gom
  theo quan hệ cha-con: task con (Task, BE/FE/QC Task) tổng hợp vào ticket
  cha, chỉ report ticket loại JP User Story, Bug, JP Bug, JP Request, JP
  Feedback. Report
  theo đơn vị ticket, dựa vào đó khớp dòng trên tab sprint và hiện preview
  từng ticket: căn cứ + các ô sẽ đổi cũ → mới. User duyệt (ok tất cả, ok một
  phần, bỏ, sửa) xong mới gọi skill `spc-collab-daily-sheet` để ghi. Dùng khi
  user nói "update report hôm nay lên sheet", "tổng hợp rồi cập nhật daily
  sheet", "sync sheet daily", "cuối ngày cập nhật sheet", "từ sáng tới giờ có
  gì cần đưa lên sheet", "preview thay đổi sheet hôm nay", "tổng hợp từ 9h
  tới 12h của Vĩ, Định lên sheet". Không dùng cho một thread cụ thể (dùng
  thẳng `spc-collab-daily-sheet`), không dùng cho brief ngày làm việc trước
  (xem `spc-collab-daily-brief`), không dùng để sửa ticket Backlog (xem
  `nulab-backlog`).
version: 0.3.0
author: TEQ AI Platform
license: Internal
argument-hint: "[since=HH:MM|YYYY-MM-DD HH:MM] [until=...] [members=Vĩ,Định,...] [sprint=Sprint N]"
metadata:
  hermes:
    tags: [daily, sheet, spc-collab, mattermost, backlog, google-sheets, report]
---

# SPC-Collab Daily Sheet Sync

Bước **tổng hợp** đứng trước `spc-collab-daily-sheet`: gom những gì các
thành viên đã bàn và đã làm trong khung giờ, quy về **ticket report** (User
Story / Bug / JP Bug / JP Request / JP Feedback — task con được gộp vào cha), đề xuất cập
nhật sheet theo từng ticket, và chỉ ghi khi user đã duyệt. Việc ghi giao cho
`spc-collab-daily-sheet` để quy tắc ghi từng cột chỉ nằm ở một chỗ.

```
Mattermost SPC - dev ─┐                     ┌─ ticket report 1 (+ task con, + thread)
                      ├─ collect.py build ──┤─ ticket report 2 ...      ─▶ khớp dòng sheet ─▶ PREVIEW ─(ok)─▶ spc-collab-daily-sheet
Backlog SPCC activity ┘   (khung + member)  └─ skipped / unmapped                                              (apply-plan)
```

## Khi Nào Dùng

- Cần cập nhật sheet daily theo toàn bộ hoạt động trong một khoảng giờ, không
  chỉ một thread.
- Muốn xem trước có gì nên đưa lên sheet (chỉ preview, chưa ghi).

Chỉ có một thread cần ghi → dùng thẳng `spc-collab-daily-sheet`.

## Tham Số

| Tham số | Mặc định | Ghi chú |
|---|---|---|
| `since` | `05:00` hôm nay (giờ VN) | `HH:MM` = hôm nay, hoặc `YYYY-MM-DD HH:MM` |
| `until` | lúc gọi | Cùng format |
| `members` | cả `references/members.json` (12 người) | Danh sách phân tách dấu phẩy: nickname, username Mattermost, backlog_id hoặc email. Áp dụng cho **cả hai nguồn** |
| `sprint` | `sprint_tab` trong config của `spc-collab-daily-sheet` | Ghi đè cho lần chạy này |

Cấu hình cố định (channel, project, loại ticket được report, bot cần loại)
nằm ở `references/sources.json`.

```bash
R=~/.claude/skills/spc-collab-daily-sheet-sync/references
S=~/.claude/skills/spc-collab-daily-sheet/references     # config.json, column-guide.md
ARGS="--since <S> --until <U> --members <M>"            # bỏ tham số nào user không truyền
```

Mọi lệnh `collect.py` trong một lần chạy dùng **cùng** `$ARGS`, để khung giờ
và tập thành viên khớp nhau giữa các bước.

## Quy Trình

### Bước 1 — Khung giờ và thành viên

```bash
python3 $R/collect.py window $ARGS      # → mattermost_since, backlog_updated_since, label
python3 $R/collect.py members $ARGS     # → backlog_id + username của từng người
```

- `unknown` khác rỗng: tên không có trong `members.json`, hoặc mơ hồ (ví dụ
  "Dũng" có thể là 2 người — xem `matches`). Mơ hồ → hỏi user. Người ngoài
  team → tìm `backlog_id` bằng `teq_backlog-get_project_user_list("SPCC")` và
  username bằng `mattermost-search_users`, rồi truyền dạng
  `backlog_id:username:nickname` trong `--members`.
- Khung rỗng (chưa tới `since`) → báo user, dừng.

### Bước 2 — Gọi API (song song trong một lượt)

- `teq_backlog-get_user_recent_updates(user_id=<backlog_id>, count=100)` cho
  từng thành viên ở Bước 1.
- `teq_backlog-get_issues(project_ids=[149054], updated_since=<backlog_updated_since>, count=100)`
  — đủ 100 thì gọi thêm `offset=100`. Activity không có issue type và cha,
  danh sách này bổ sung thông tin đó.
- `mattermost-read_channel(channel_id, since=<mattermost_since>, limit=100)`.

Kết quả lớn được lưu ra `tool-results/...txt` — gom đường dẫn. Kết quả nhỏ
hiển thị trực tiếp thì ghi ra scratchpad bằng Write. Với issue, chỉ cần ghi
các field `id`, `issueKey`, `issueType.name`, `summary`, `status.name`,
`assignee.id`, `parentIssueId`.

### Bước 3 — Gom theo ticket (lặp tới khi `todo` rỗng)

```bash
python3 $R/collect.py build $ARGS \
   --activities <file activity...> --issues <file issue...> --mattermost <file mattermost...> \
   [--children-fetched-for <id,id,...>] > "$SCRATCH/report.json"
```

Script lọc theo khung (`create_at` cho Mattermost, `created` cho Backlog — cả
hai API đều trả thêm dữ liệu ngoài khung), theo thành viên, bỏ post hệ thống
và bot, rồi gom:

| Ticket có activity / được nhắc | Quy về |
|---|---|
| Có cha, cha thuộc `report_issue_types` | **Cha** — activity nằm trong `children[]` của cha |
| Không có cha (hoặc cha không thuộc loại report), bản thân thuộc loại report | Chính nó |
| Còn lại (Task, BE/FE/QC Task không có cha report) | `skipped` — không report |
| Mã `CRES-…` / `chunk_N` trong Mattermost | Ticket report có mã đó trong `summary` |

Xử lý `todo` rồi chạy lại `build` với **tất cả** file (cũ + mới):

| `todo` | Gọi |
|---|---|
| `members_not_fetched` | `get_user_recent_updates` cho người đó (bị sót ở Bước 2) |
| `members_need_paging` | `get_user_recent_updates(user_id, count=100, max_id=<max_id>)` |
| `missing_issue_keys` | `teq_backlog-get_issue(issue_key=…)` |
| `missing_parent_issue_ids` | `teq_backlog-get_issue(issue_id=…)` |
| `fetch_children_for_issue_ids` | **Một** lượt `get_issues(project_ids=[149054], parent_issue_ids=[…], count=100)`, rồi thêm các id đó vào `--children-fetched-for` |
| `roots_to_read` | `mattermost-read_post(post_id, include_thread=false)` |
| `mattermost_possibly_truncated` | `mattermost-search_posts(query="on:<ngày>", channel_id, limit=50)` cho từng ngày trong `days`; vẫn thiếu → ghi "Mattermost có thể thiếu" ở dòng đầu preview |

Thường chỉ cần 1–2 vòng. Kết quả `report.json`:

- `tickets[]`: mỗi ticket report có `key`, `issue_type`, `summary`,
  `status_now`, `assignee`, `activities` (của chính nó), `children[]` (**mọi**
  task con đã biết, kèm `status_now` và `activities` trong khung),
  `children_status` (đếm theo status), `children_active`, `threads[]`
  (thread Mattermost nhắc ticket này hoặc task con của nó).
- `skipped[]`: task không quy được về ticket report.
- `unmapped_threads[]`: thread không gắn được ticket nào, kèm
  `unresolved_tickets` (mã nhắc tới nhưng không tìm thấy trên Backlog).

### Bước 4 — Đúc kết theo từng ticket report

Mỗi ticket report là **một đơn vị report**. Đọc toàn bộ căn cứ của nó (activity
chính nó + task con + thread) và rút ra trạng thái hôm nay:

- **Task con là căn cứ cho cột FE / BE** của ticket cha: tiến độ chung
  (`children_status`, ví dụ "BE: 15/18 task Waiting For Release, còn 3560
  Ready For Test, 2 On Hold") cộng việc mới trong khung (`children_active`).
  Loại task quyết định cột: `BE Task` → `BE`, `FE Task` → `FE`; `Task`/`QC Task`
  → theo nội dung, không rõ thì `Memo`.
- **Bug / JP Bug / JP Feedback là con của User Story** cũng được gộp vào User Story, ghi
  vào FE/BE hoặc Memo của dòng cha (ví dụ "2 bug UI mới, đang fix").
- **Status của task con không đổi `Status` của dòng.** Chỉ status của chính
  ticket report mới map sang cột `Status` (bảng map ở
  `references/preview-format.md`).
- Mattermost: **lời chốt sau cùng thắng**; "tạm thời", "có thể", "mai chốt",
  câu hỏi chưa ai trả lời → không phải quyết định.
- Bỏ việc vặt: đổi assignee/due date lẻ, comment xã giao, chào hỏi.

### Bước 5 — Khớp dòng sheet

1. Đọc sheet theo Bước 3 của `spc-collab-daily-sheet` với `$S/config.json`:
   `google_sheets-get_values(range="'<sprint_tab>'!A2:Z")`, map header → cột,
   đọc `statuses_range`. Tab không tồn tại hoặc thiếu header → dừng và báo.
2. Với mỗi ticket report, tìm dòng bằng `key` (SPCC-…) **và** mã `CRES-…`
   trong `summary`, theo quy tắc Bước 4 của `spc-collab-daily-sheet` (ranh
   giới số, `-` ≡ `_`; nhiều dòng → hỏi).
3. `unmapped_threads` có mã `CRES-…`/`chunk_N` → thử khớp thẳng trên sheet.
4. Ticket report không có dòng → mục "Không đưa lên sheet" (Bug thường không
   có dòng riêng — nếu là con của User Story thì đã được gộp ở Bước 3).

### Bước 6 — Change plan và preview

1. Đọc `$S/column-guide.md` (cột được ghi, format, ghi đè hay thêm dòng) và
   `references/preview-format.md` (format preview + map status).
2. Chỉ đề xuất thay đổi có căn cứ rõ. Không chắc → "Cần xác nhận".
3. Ghi plan ra `$SCRATCH/plan.json` (một item = một ticket report = một dòng
   sheet):

   ```json
   {"source": "spc-collab-daily-sheet-sync", "sprint_tab": "Sprint 57", "label": "02/10 05:00 → 16:00",
    "items": [{"no": 1, "ticket": "SPCC-3549", "row": 12,
               "evidence": ["09:09–13:46 Backlog (Tiên): 3555, 3562 BE Task → Waiting For Release; 3560 → Ready For Test",
                            "BE task con: 15/18 Waiting For Release, 2 On Hold"],
               "changes": [{"header": "BE", "old": "Đang clean phía BE", "new": "15/18 task verified DEV, còn 3560 chờ QC, 2 On Hold"}]}],
    "confirm": ["SPCC-3551: User Story → Waiting For Release — Status sheet đổi gì?"]}
   ```

   `old` là giá trị đọc ở Bước 5, nguyên văn — skill ghi sẽ so lại trước khi
   ghi.
4. Trả preview trong chat rồi **dừng, chờ user**. Không ghi gì ở bước này.

### Bước 7 — Phản hồi của user

| User trả lời | Hành động |
|---|---|
| `ok`, `apply`, `ghi đi` | Giữ tất cả item đánh số |
| `ok 1,3` / `chỉ 1 và 3` | Giữ đúng các item đó |
| `bỏ 2` | Giữ tất cả trừ item 2 |
| `2: BE = ...`, "sửa 2 thành ..." | Sửa plan, in lại preview item đó, chờ ok lần nữa |
| Trả lời một mục "Cần xác nhận" | Chuyển thành item đánh số mới, in lại, chờ ok |
| Câu hỏi, không rõ ý | Trả lời/hỏi lại, không ghi |

Mục "Cần xác nhận" không bao giờ được ghi khi chưa được chuyển thành item.

### Bước 8 — Giao cho `spc-collab-daily-sheet` ghi

Cập nhật `plan.json` chỉ còn các item đã duyệt, rồi:

```
Skill(skill="spc-collab-daily-sheet", args="apply-plan <đường dẫn plan.json>")
```

Skill đó đọc lại từng ô trước khi ghi (ô đã bị người khác sửa → bỏ), dựng
lại `Remark` từ FE/BE và báo kết quả bằng bảng `Cũ → Mới`. Trả kết quả đó cho
user. Không post Mattermost trừ khi user yêu cầu rõ và chỉ định nơi post.

## Anti-patterns

- Report một BE/FE/QC Task hay Task thành một mục riêng, hoặc tìm dòng sheet
  cho nó — task con chỉ là căn cứ cho ticket cha.
- Chỉ nhìn task con có activity mà bỏ qua `children_status` — FE/BE sẽ phản
  ánh sai tiến độ chung của ticket.
- Đổi `Status` của dòng theo status của task con; đề xuất `TEQ Done` từ
  `Resolved`/`Closed`/`Waiting For Release`.
- Dùng thẳng kết quả `read_channel` / `get_user_recent_updates` mà không qua
  `collect.py build` — sẽ lọt dữ liệu ngoài khung và ngoài tập thành viên.
- Đổi `--since`/`--until`/`--members` giữa các lần chạy `collect.py`.
- Ghi lên sheet trước khi user duyệt, hoặc tự gọi `google_sheets-update_values`
  thay vì giao cho `spc-collab-daily-sheet`.
- Một item preview chứa thay đổi của hai dòng sheet khác nhau.

## Red Flags

🚩 Preview có căn cứ với giờ ngoài khung, hoặc của người ngoài `members`.
🚩 `todo` còn mục chưa xử lý mà đã viết preview.
🚩 Mã BE Task / FE Task xuất hiện như tiêu đề một item preview.
🚩 Có thay đổi trong plan mà không có căn cứ đi kèm.
🚩 User nói `ok 1,3` mà plan gửi đi vẫn có item 2.
🚩 Có `@` trước tên người trong preview.
