---
name: spcc-activity-report
description: >
  Report hoạt động của team spc-collab theo từng ticket trong một khung giờ —
  mặc định TỪ 05:00 SÁNG NAY tới lúc gọi, truyền được `since`/`until` — gộp 2
  nguồn: trao đổi/quyết định/action trên Mattermost "SPC - dev" và activity
  Backlog SPCC (đổi status, comment, tạo ticket) của các thành viên (mặc định
  cả team trong members.json, truyền được danh sách khác). Ticket Backlog được
  gom theo quan hệ cha-con: task con (Task, BE/FE/QC Task) tổng hợp vào
  ticket cha; chỉ report ticket loại JP User Story, Bug, JP Bug, JP Request,
  JP Feedback. Mỗi ticket: trạng thái, tiến độ task con, việc đã làm (ai, lúc
  nào), quyết định đã chốt, việc đang chờ/vướng. Xuất Markdown trong chat và
  lưu `report.json` để skill `spcc-daily-sheet-sync` dùng cập nhật sheet.
  Dùng khi user nói "report hôm nay", "summary action từ sáng tới giờ", "hôm
  nay team làm gì", "tổng hợp Mattermost + Backlog hôm nay", "từ 9h tới 12h
  Vĩ, Định làm gì", "chuẩn bị số liệu cuối ngày", hoặc trước khi cập nhật
  sheet daily theo hoạt động cả ngày. Skill chỉ đọc, không ghi sheet (xem
  `spcc-daily-sheet-sync`), không phải brief ngày làm việc trước (xem
  `spcc-daily-brief`), không sửa ticket (xem `nulab-backlog`), không
  phải report kết quả một task/investigation (xem `spcc-report`).
version: 0.4.0
author: TEQ AI Platform
license: Internal
argument-hint: "[since=HH:MM|YYYY-MM-DD HH:MM] [until=...] [members=Vĩ,Định,...]"
metadata:
  hermes:
    tags: [report, activity, spc-collab, mattermost, backlog, daily]
---

# SPC-Collab Activity Report

Gom những gì các thành viên đã bàn và đã làm trong một khung giờ trên
Mattermost và Backlog, quy về **ticket report** (task con gộp vào cha) và
trình bày theo từng ticket. Skill chỉ đọc. Kết quả dùng được ngay để đọc,
hoặc làm đầu vào cho `spcc-daily-sheet-sync` khi cần cập nhật sheet.

```
Mattermost SPC - dev ─┐                     ┌─ ticket report (+ task con, + thread) ─▶ Markdown theo ticket
                      ├─ collect.py build ──┤                                       └▶ report.json ─▶ spcc-daily-sheet-sync
Backlog SPCC activity ┘  (khung + member)   └─ skipped / unmapped                         (khi user muốn cập nhật sheet)
```

## Khi Nào Dùng

- Cần biết trong khoảng giờ đó team (hoặc vài người) đã làm gì, chốt gì,
  vướng gì — theo từng ticket.
- Trước khi cập nhật sheet daily theo hoạt động cả ngày: chạy skill này, rồi
  `spcc-daily-sheet-sync` với report vừa tạo.

Brief hôm qua cho daily meeting → `spcc-daily-brief`. Chỉ một thread →
`spcc-daily-sheet-sync` đọc thẳng thread.

## Tham Số

| Tham số | Mặc định | Ghi chú |
|---|---|---|
| `since` | `05:00` hôm nay (giờ VN) | `HH:MM` = hôm nay, hoặc `YYYY-MM-DD HH:MM` |
| `until` | lúc gọi | Cùng format |
| `members` | cả `references/members.json` (12 người) | Phân tách dấu phẩy: nickname, username Mattermost, backlog_id hoặc email. Áp dụng cho **cả hai nguồn** |

Cấu hình cố định (channel, project, loại ticket được report, bot cần loại)
nằm ở `references/sources.json`.

```bash
R=~/.claude/skills/spcc-activity-report/references
ARGS="--since <S> --until <U> --members <M>"     # bỏ tham số nào user không truyền
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
| `mattermost_possibly_truncated` | `mattermost-search_posts(query="on:<ngày>", channel_id, limit=50)` cho từng ngày trong `days`; vẫn thiếu → ghi "Mattermost có thể thiếu" ở dòng nguồn của report |

Thường chỉ cần 1–2 vòng. Kết quả `report.json`:

- `tickets[]`: mỗi ticket report có `key`, `issue_type`, `summary`,
  `status_now`, `assignee`, `activities` (của chính nó), `children[]` (**mọi**
  task con đã biết, kèm `status_now` và `activities` trong khung),
  `children_status` (đếm theo status), `children_active`, `threads[]`
  (thread Mattermost nhắc ticket này hoặc task con của nó).
- `skipped[]`: task không quy được về ticket report.
- `unmapped_threads[]`: thread không gắn được ticket nào, kèm
  `unresolved_tickets` (mã nhắc tới nhưng không tìm thấy trên Backlog).

### Bước 4 — Lưu report

```bash
mkdir -p ~/.cache/spcc-activity-report
cp "$SCRATCH/report.json" ~/.cache/spcc-activity-report/<YYYY-MM-DD>_<HHMM>-<HHMM>.json
cp "$SCRATCH/report.json" ~/.cache/spcc-activity-report/latest.json
```

Lưu ngoài repo (dữ liệu nội bộ) để `spcc-daily-sheet-sync` đọc lại được, kể
cả ở phiên khác.

### Bước 5 — Viết report theo ticket

Đọc `references/output-format.md` (khung, quy tắc từng mục, ví dụ) rồi viết.
Mỗi ticket report là **một đơn vị**: đọc toàn bộ căn cứ của nó (activity chính
nó + task con + thread) rồi đúc kết, không chép lại từng activity.

- **Task con**: nêu tiến độ chung (`children_status`) + việc mới trong khung
  (`children_active`), không liệt kê từng task con không có gì mới.
- **Mattermost**: lời chốt sau cùng thắng; "tạm thời", "có thể", "mai chốt",
  câu hỏi chưa ai trả lời → mục đang chờ, không phải quyết định.
- Bỏ việc vặt: đổi assignee/due date lẻ, comment xã giao, chào hỏi.

Cuối report thêm đúng 1 dòng gợi ý:
`Cập nhật sheet theo report này: gọi spcc-daily-sheet-sync (report=<đường dẫn latest.json>).`
Không tự gọi `spcc-daily-sheet-sync` khi user chưa yêu cầu.

## Anti-patterns

- Report một BE/FE/QC Task hay Task thành mục riêng — task con chỉ là căn cứ
  cho ticket cha.
- Chỉ nhìn task con có activity mà bỏ qua `children_status` — tiến độ chung
  bị phản ánh sai.
- Dùng thẳng kết quả `read_channel` / `get_user_recent_updates` mà không qua
  `collect.py build` — sẽ lọt dữ liệu ngoài khung và ngoài tập thành viên.
- Đổi `--since`/`--until`/`--members` giữa các lần chạy `collect.py`.
- Ghi sheet, sửa ticket, hay post Mattermost — skill này chỉ đọc.
- Lưu `report.json` vào repo `agent-skills`.

## Red Flags

🚩 Report có hoạt động với giờ ngoài khung, hoặc của người ngoài `members`.
🚩 `todo` còn mục chưa xử lý mà đã viết report.
🚩 Mã BE Task / FE Task xuất hiện như tiêu đề một mục.
🚩 Cùng một ticket xuất hiện ở hai mục.
🚩 Có `@` trước tên người.
