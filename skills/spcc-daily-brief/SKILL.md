---
name: spcc-daily-brief
description: >
  Soạn daily brief ngắn gọn cho dự án spc-collab bằng cách gộp 2 nguồn —
  Backlog TEQ (mặc định project SPCC) và một channel Mattermost (mặc định
  "SPC - dev") — rồi đúc kết thành các điểm quan trọng, việc cần xác nhận,
  việc đang stuck, cộng bảng chuyển status của các ticket JP User Story. Chỉ
  lấy hoạt động của 12 thành viên team cố định, và chỉ trong ngày làm việc
  trước (hôm qua; Thứ 2 thì gộp Thứ 6 tới Chủ nhật) — không lấy dữ liệu hôm
  nay hay các ngày cũ hơn. Xuất Markdown trong chat. Dùng khi user nói "brief
  daily", "daily brief", "tóm tắt hôm qua", "hôm qua team làm gì", "tổng hợp
  Backlog + Mattermost hôm qua", "chuẩn bị daily meeting", "catch up dự án",
  kể cả khi user đổi project Backlog, đổi channel hoặc chỉ định ngày khác.
  Không dùng để tạo/sửa ticket (xem `nulab-backlog`), không dùng để liệt kê
  PR GitHub (xem `github-review-requests`), không dùng cho report một task hay
  investigation đã xong (xem `spcc-report`). Dữ liệu đã lọc được lưu
  theo ngày ở local để lần sau dùng lại; brief cuối tự đăng lên Backlog
  Document `Daily brief/<ngày>`.
version: 0.4.0
author: TEQ AI Platform
license: Internal
argument-hint: "[date=YYYY-MM-DD | day=YYYY-MM-DD] [refresh] [channel=<channel_id>]"
metadata:
  hermes:
    tags: [daily, brief, spc-collab, backlog, mattermost, summary]
---

# SPC-Collab Daily Brief

Gom những gì team đã làm và bàn trong **một khung thời gian cố định** (ngày
làm việc trước) trên Backlog và Mattermost, rồi đúc kết thành một bản brief
đọc trong 1–2 phút trước daily meeting: chuyện gì quan trọng, cái gì cần ai
xác nhận, cái gì đang kẹt.

## Khi Nào Dùng

- Đầu ngày cần nắm hôm qua team làm gì, chốt gì, kẹt ở đâu.
- Muốn brief cho một project Backlog khác hoặc channel khác: truyền tham số.
- Muốn xem lại đúng một ngày cụ thể trong quá khứ: dùng `day=YYYY-MM-DD`.

Không dùng cho việc thao tác ticket, review PR hay viết report kết quả task —
xem các skill ghi trong `description`.

## Tham Số và Mặc Định

| Tham số | Mặc định | Ghi chú |
|---|---|---|
| Backlog space | TEQ (`mcp__ai-platform__teq_backlog-*`) | Space Finatext dùng `finatext_backlog-*` nếu user chỉ định |
| `project` | `SPCC` (id `149054`) | Project khác: gọi `teq_backlog-get_project` để lấy id |
| `channel` | `it63ufxpxtbo7xgj4g44g3woqy` (SPC - dev) | Truyền channel id khác nếu cần |
| `date` | hôm nay (giờ VN) | Coi như "hôm nay" là ngày này rồi áp quy tắc ngày làm việc trước |
| `day` | — | Lấy đúng 1 ngày, không gộp cuối tuần |
| Thành viên | `references/members.json` (12 người) | DEV/PO/BrSE/QC, trùng với nhóm của `spcc-calendar` |
| User Story | issue type `JP User Story` (id `825231`) | Chỉ loại này vào bảng chuyển status |
| `refresh` | tắt | Bỏ qua kho, lấy lại dữ liệu từ API cho các ngày trong khung |
| Kho dữ liệu | `~/.cache/spc-collab-daily/` | Đổi bằng biến môi trường `SPC_DAILY_STORE` |
| Đăng brief | Backlog Document `Daily brief/<label>` | Tự đăng mỗi lần chạy |
| Múi giờ | `Asia/Ho_Chi_Minh` | Ranh giới ngày là 00:00 giờ VN |

## Thành Viên

`references/members.json` là danh sách cố định: tên thân thiện
(`nickname`, ví dụ Vĩ, Định), tên Backlog, `backlog_id`, username Mattermost,
email và vai trò. Chỉ gọi activity cho những người này —
vừa nhanh hơn (12 thay vì ~30 lượt gọi), vừa loại được người của project
khác chỉ có tên trong member list của SPCC.

Lưu ý có 2 người tên Dũng: `dungnguyenhuu` (Nguyen Huu Dung, DEV) và
`dungnguyen` (Nguyen Tien Dung, BrSE). Khi viết brief ghi người bằng
`nickname` trong file này; `nickname` là `null` thì dùng username Mattermost.
Không tự suy tên gọi từ họ tên — user tự bổ sung `nickname` còn thiếu.

Người ngoài danh sách vẫn có thể xuất hiện trong Mattermost (ví dụ JP, QC
khác) — giữ nội dung nếu liên quan, nhưng không đi tìm activity Backlog của
họ. Team thay đổi thì sửa `members.json` (lấy `backlog_id` từ
`get_project_user_list`, username từ `mattermost-search_users`).

## Vì Sao Phải Lọc Kỹ Theo Khung Thời Gian

Yêu cầu cốt lõi là **chỉ có dữ liệu trong khung**. Cả hai API đều không lọc
được chính xác, nên phải tự lọc lại:

- Backlog `get_issues` chỉ lọc theo *lần cập nhật cuối* của ticket và theo
  ngày chứ không theo giờ. Ticket sửa hôm qua rồi hôm nay sửa tiếp sẽ không
  còn "updated hôm qua". Vì vậy skill dựa vào **activity** của từng thành viên
  (`get_user_recent_updates`), mỗi activity có timestamp riêng (UTC) và có
  sẵn giá trị cũ → mới.
- Mattermost `read_channel` chỉ có `since` và lọc theo `update_at`, nên kéo
  theo cả post hôm nay và post cũ vừa được sửa. Phải lọc lại theo
  `create_at < end`.

Thread bắt đầu trước khung nhưng có reply trong khung: chỉ dùng các reply
trong khung; được đọc root post để biết chủ đề.

## Quy Trình

### Bước 1 — Tính khung thời gian

```bash
R=~/.claude/skills/spcc-daily-brief/references
python3 $R/window.py                 # mặc định
python3 $R/window.py 2026-09-29      # date=
python3 $R/window.py --day 2026-09-25
```

Giữ lại `label`, `days`, `start_utc`, `end_utc`, `start_ms`, `end_ms`. Ngày lễ
không được xử lý tự động; nếu user nói hôm qua là ngày lễ thì dùng `date=`
hoặc `day=`.

### Bước 2 — Kiểm tra kho dữ liệu local

Dữ liệu đã lọc được lưu theo **từng ngày lịch** ở `~/.cache/spc-collab-daily/`
(ngoài repo — đây là dữ liệu nội bộ). Ngày đã kết thúc thì gần như không đổi,
nên chỉ lấy từ API những ngày còn thiếu:

```bash
python3 $R/store.py check <các ngày trong days>          # thêm --refresh nếu user nói "fetch lại"/"refresh"
```

- `missing` rỗng → bỏ qua Bước 3–5, sang thẳng Bước 6.
- Chỉ lấy lại khi user nói rõ "fetch lại", "refresh", "lấy mới" (dùng
  `--refresh`), hoặc khi `check` báo ngày đó thiếu: chưa từng lấy, lấy trước
  khi ngày kết thúc, lần trước bị cắt, hoặc `members.json` đã đổi.
- Brief Thứ 2 gộp 3 ngày: ngày nào đã có (ví dụ Thứ 6) thì dùng lại, chỉ lấy
  các ngày còn thiếu.

Bước 3–5 chỉ áp dụng cho các ngày trong `missing`; gọi API một lần cho cả
khoảng thiếu, từ ngày thiếu sớm nhất (`<first_missing>`) tới hết ngày thiếu
muộn nhất.

### Bước 3 — Activity Backlog của team

1. Đọc `backlog_id` trong `$R/members.json`. Gọi song song
   `teq_backlog-get_user_recent_updates(user_id, count=100)` cho cả 12 người
   trong một lượt.
   - Kết quả thường vượt giới hạn hiển thị và được lưu ra file
     `tool-results/...txt` — gom các đường dẫn đó.
   - Kết quả nhỏ hiển thị trực tiếp: chỉ cần xem activity SPCC có `created`
     trong khoảng thiếu, thường là không có — khi đó không cần file.
   - **Phân trang**: người nào có activity cũ nhất trong 100 cái vẫn
     `created >= 00:00 của <first_missing>` thì gọi tiếp với
     `max_id = <id nhỏ nhất> - 1`. Kiểm tra nhanh:

     ```bash
     for f in <các file>; do jq -s -r '[.[0].createdUser.id, (map(.id)|min), (map(.created)|min)]|@tsv' "$f"; done
     ```

### Bước 4 — Danh sách ticket JP User Story

Activity không có issue type, nên lấy danh sách key User Story riêng:

```
teq_backlog-get_issues(project_ids=[149054], issue_type_ids=[825231],
                       updated_since=<first_missing lùi 1 ngày>, count=100)
```

Ticket có activity trong khung chắc chắn có `updated >= start`, nên lọc theo
`updated_since` là đủ để không sót; lùi 1 ngày vì Backlog so ngày theo múi giờ
của space. Nếu trả đủ 100 thì gọi thêm với `offset=100`.

### Bước 5 — Mattermost, rồi ghi vào kho

1. `mattermost-read_channel(channel_id, since=<00:00 của first_missing, giờ VN>, limit=100)`.
   Nếu kết quả hiển thị trực tiếp (không lưu ra file), ghi nguyên JSON đó ra
   file trong scratchpad bằng Write để ingest được.
2. **Kiểm tra bị cắt**: nhận đủ 100 post mà post cũ nhất vẫn sau
   `start_ms` của ngày thiếu → bổ sung bằng
   `mattermost-search_posts(query="on:<YYYY-MM-DD>", channel_id, limit=50)`;
   nếu vẫn thiếu thì ingest kèm `--truncated` để lần sau lấy lại.
3. Ghi vào kho **từng ngày** trong `missing` (cùng bộ file thô cho mọi ngày —
   `store.py` tự lọc theo ngày, bỏ system message, gom thread, tính các lần
   đổi status của User Story):

   ```bash
   python3 $R/store.py ingest <DAY> --backlog <các file activity> \
      --mattermost <file mattermost> --user-stories <file get_issues> [--truncated]
   ```

   Project khác SPCC: `store.py` đang cố định SPCC; lọc tay bằng
   `backlog-activities.jq` / `mattermost-posts.jq` với status map lấy từ
   `get_status_list_of_project`, và không ghi vào kho.

### Bước 6 — Nạp dữ liệu từ kho

```bash
python3 $R/store.py load <các ngày trong days> > "$SCRATCH/day.json"
```

Gồm `backlog` (activity đã lọc), `mattermost_threads` (mỗi thread có `day`,
`root_in_window`), `user_story_status` (các lần đổi status của JP User Story;
một ticket đổi nhiều lần → gộp thành `A → B → C`). Thread có
`root_in_window=false`: `mattermost-read_post(root_id, include_thread=false)`
để biết chủ đề.

### Bước 7 — Đúc kết và viết brief

Đọc `references/output-format.md` trước (format cố định + ví dụ chuẩn).

Không trình bày theo nguồn. Gộp Backlog và Mattermost theo **chủ đề / ticket**
— một thread bàn về SPCC-3586 và việc SPCC-3586 đổi status là cùng một mục.
Sau đó xếp mỗi mục vào đúng một nhóm:

| Nhóm | Đưa vào khi |
|---|---|
| **Key Highlights** | Release/deploy, quyết định đã chốt (với JP hoặc trong team), thay đổi plan/deadline, ticket được nghiệm thu hàng loạt, phân công lớn |
| **Needs Confirmation** | Có câu hỏi chưa ai trả lời, đang chờ ai đó (JP, PO, QC, reviewer) quyết định hoặc check, cần team hành động trước một mốc |
| **Blockers & Risks** | Bị chặn bởi việc khác, bug mới phát sinh, không kịp release, Reopen/On Hold kéo dài, thiếu người |

Nguyên tắc viết:

- **Ngắn là mặc định.** Mỗi bullet một dòng: việc gì → trạng thái/kết luận →
  `(người phụ trách)` nếu có. Chỉ viết dài hơn khi mục đó thật sự quan trọng, ví dụ
  một quyết định ảnh hưởng release hay một blocker có nhiều bên liên quan.
- **Không liệt kê từng thay đổi.** Hàng chục lượt đổi assignee/due date cùng
  một đợt → một bullet ở Key Highlights (ai chia gì cho ai, bao nhiêu ticket).
  Việc thường ngày không có hệ quả (sửa description, đổi start date lẻ, chào
  hỏi, cảm ơn) → bỏ.
- Nhóm nào không có gì thì ghi "None" thay vì bỏ nhóm — người đọc cần
  biết là đã kiểm tra.
- Ticket key để dạng link `[SPCC-3599](https://teq-dev.backlog.com/view/SPCC-3599)`.
- Heading và tiêu đề bảng giữ **tiếng Anh** đúng như template để brief trông
  chuyên nghiệp và đồng nhất giữa các ngày; nội dung bullet vẫn viết tiếng Việt.
- Người phụ trách ghi **trong ngoặc, không có `@`** — ví dụ `(vitran)`,
  `(oanhtran, thaohuynh)` — để brief dán vào Mattermost không ping ai. Dùng
  username Mattermost trong `members.json`; người ngoài danh sách giữ tên như
  trong nguồn.

### Bước 8 — Lưu brief và đăng lên Backlog Document

Mỗi lần chạy đều **tự đăng** brief lên Backlog Document của SPCC, theo cây
`Daily brief/<label>` (ví dụ `Daily brief/2026-09-29`; brief Thứ 2 là
`Daily brief/2026-09-25 → 2026-09-27`). Nội dung giữ nguyên bản brief, kể cả
nickname. Không cần hỏi lại user trước khi đăng — user đã chốt tự đăng. Sau
đó vẫn trả brief trong chat như thường.

1. Ghi brief ra `$SCRATCH/brief.md`, rồi `python3 $R/store.py save-brief "<label>" "$SCRATCH/brief.md"`.
2. `python3 $R/store.py published "<label>"` — khác `null` nghĩa là đã đăng →
   dừng, chỉ báo link cũ.
3. `teq_backlog-get_document_tree(project_id_or_key="SPCC")`, tìm trong
   `activeTree.children` node tên đúng `Daily brief` (id hiện tại
   `01a0f148a033737d992f48fb0b176e88`, tạo ngày 2026-09-30 — vẫn kiểm tra lại trên cây):
   - Chưa có → `teq_backlog-add_document(project_id=149054, title="Daily brief", content="Daily brief SPCC — tạo tự động bởi skill spcc-daily-brief.")`, lấy `id`.
   - Trong node đó đã có con tên đúng `<label>` → đã đăng từ trước (có thể
     bằng máy khác) → ghi lại bằng `store.py published` rồi dừng.
4. `teq_backlog-add_document(project_id=149054, parent_id=<id Daily brief>, title="<label>", content=<nội dung brief.md>)`.
   Truyền Markdown nguyên bản — Backlog tự chuyển heading, list, link, bảng
   sang định dạng Document (đã kiểm chứng với brief 2026-09-29).
5. `python3 $R/store.py published "<label>" --doc-id <id> --url https://teq-dev.backlog.com/document/SPCC/<id>`.
6. Cuối câu trả lời thêm đúng 1 dòng: `Đã đăng: <url>` (hoặc `Đã có sẵn: <url>`).

Tool chỉ **tạo** được Document, không sửa/xoá được. Vì vậy không bao giờ tạo
trang thứ hai cùng `<label>`: nếu brief cần sửa sau khi đã đăng, báo user tự
sửa trên Backlog. Đăng thất bại thì vẫn trả brief trong chat và nói rõ lỗi.

## Format Output

Format là **cố định** cho mọi lần gọi: khung heading, thứ tự mục, số bullet,
cách ghi owner, link, và một ví dụ chuẩn nằm ở `references/output-format.md`.
Đọc file đó ở Bước 5, trước khi viết, và chạy checklist cuối file trước khi
trả brief. Không tự thêm hay đổi tên mục, kể cả khi ngày đó có nội dung lạ —
xếp nó vào một trong 3 nhóm.

## Anti-patterns

- Dùng `get_issues(updated_since=…, updated_until=…)` làm nguồn activity —
  sẽ sót ticket hôm qua có cập nhật mà hôm nay lại cập nhật tiếp. `get_issues`
  chỉ dùng để lấy danh sách key User Story.
- Đưa post hoặc activity của hôm nay vào brief "vì nó liên quan".
- Chia brief thành mục Backlog và mục Mattermost, hoặc chép nguyên thread.
- Đưa BE Task / FE Task / QC Task vào bảng chuyển status — những ticket đó,
  nếu quan trọng, được nhắc trong các nhóm phía trên.
- Gọi activity cho người ngoài `members.json`.
- Tự post brief lên Mattermost — chỉ post khi user yêu cầu rõ và xác nhận
  channel đích. (Backlog Document thì tự đăng, xem Bước 8.)
- Gọi lại API cho ngày đã có trong kho khi user không yêu cầu refresh.
- Tạo trang Document thứ hai cho cùng một `<label>`.
- Lưu dữ liệu kho vào repo `agent-skills` hoặc đăng dữ liệu thô lên Backlog —
  kho chỉ ở local, Backlog chỉ nhận brief cuối.

## Red Flags

🚩 Brief có sự kiện của hôm nay.
🚩 Có 2 trang Document cùng tên dưới `Daily brief`.
🚩 `store.py check` báo `cached` mà vẫn gọi API.
🚩 Thứ 2 mà khung chỉ có 1 ngày (quên gộp cuối tuần), trừ khi user dùng `day=`.
🚩 Nhận đủ 100 activity/post mà không kiểm tra phân trang hoặc bị cắt.
🚩 Status hiển thị dạng số (`49064`) — quên truyền map status.
🚩 Có `@` trước tên người trong brief — sẽ ping khi dán vào Mattermost.
🚩 Một bullet dài 3–4 dòng cho việc không ảnh hưởng release/tiến độ.
🚩 Cùng một ticket xuất hiện ở hai nhóm khác nhau.
