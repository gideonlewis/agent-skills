---
name: fushigidane-feature-flag-weekly-check
description: |
  Audit read-only cho team Fushigidane: rà soát ticket Backlog (sprint hiện tại +
  ticket chỉ định thêm) xem đã define Feature Flag chưa, đối chiếu tab FeatureFlag
  trong Google Sheet (scope Fushigidane), tạo report gửi Mattermost (cần xác nhận).
  Bắt buộc chạy khi 1 ticket chuyển status "Waiting for release". Dùng khi được yêu
  cầu "check FF", "audit feature flag", "chạy FF check tuần này".
argument-hint: "[milestone name] [ticket keys...] [mattermost channel_id]"
---

# Fushigidane — Kiểm tra Feature Flag hàng tuần

Audit **read-only** — không ghi gì vào Backlog/Sheet. Hành động ghi duy nhất là
**post Mattermost**, luôn cần **xác nhận tường minh mỗi lần chạy** (Bước 6), kể cả
khi channel_id đã hardcode.

## Khi nào dùng

- Rà soát định kỳ FF của ticket trong sprint hiện tại.
- **Bắt buộc** khi ticket chuyển status `Waiting for release` — chỉ cần check riêng
  ticket đó, không cần quét cả milestone.

## Cấu hình (hardcode — sửa trực tiếp khi đổi sprint/sheet)

```
PROJECT_ID         = 149054     # SPCC (SPC-Collab), BACKLOG_MCP = teq_backlog (KHÔNG dùng finatext_backlog)
PROJECT_KEY_PREFIX = SPCC       # ticket luôn là key Backlog SPCC-\d+, KHÔNG phải key JIRA (CRES-\d+)
ISSUE_TYPE_ID      = 825231     # JP User Story

DEFAULT_MILESTONE  = Sprint 42
  # Tên milestone THẬT trong Backlog. Quy đổi đã xác nhận: Sprint Backlog SPCC =
  # Sprint JP/Fushigidane - 10 → "Sprint 42" == "Fushigidane Sprint 52" bên Sheet.
  # KHÔNG có milestone tên "Sprint 52" trong Backlog SPCC.
DEFAULT_TICKETS    = [SPCC-3220, SPCC-3236, SPCC-3264]

FF_SHEET_FILE_ID   = 1MAt1RSkahev5UvWQISIzco0-5fDMWH03b5L0PTcl0n0
FF_SHEET_TAB       = FeatureFlag   # gid=1250148479

# Cột đã XÁC NHẬN từ ảnh thật (2026-07-20):
#   A=flag (key)  E=ステータス (実装済/削除済)  F=メモ
#   G=test(CIのテストで参照)  H=dev  I=stg  J=prod  K=削除可能
# Cột CHƯA XÁC NHẬN (B/C/D đang ẩn lúc chụp) — điền ngay khi biết, xoá dòng TODO ở Bước 4:
FF_SHEET_OWNER_COL           = ???   # cần để filter scope Fushigidane
FF_SHEET_JIRA_URL_COL_HEADER = ???   # cần để cross-match ticket → flag
FUSHIGIDANE_LABELS = ["Fushigidane", "fushigidane"]

# Custom field trên ticket SPCC (nguồn xác định chính, không suy đoán từ mô tả):
CF_JIRA_TICKET_ID      = 115767   # "JIRA Ticket" — URL .../browse/CRES-XXXX
CF_IS_APPLIED_FF_ID    = 120475   # "Is Applied Feature Flag" — YES / NO
CF_FEATURE_FLAG_KEY_ID = 120476   # "Feature Flag Key" — text tự do, có thể trống dù = YES
TITLE_JIRA_KEY_PATTERN = 【(CRES-\d+)】   # JIRA key thường lộ sẵn trong title
```

## Điều kiện tiên quyết

Tool đến từ MCP gateway chung của công ty (hiện tên server là `ai-platform`, dạng
tool `mcp__ai-platform__teq_backlog-*` / `google_drive-*` / `mattermost-*` — tên
server từng đổi trong quá khứ (`my-server` → `ai-platform`) nên **luôn search theo
keyword** (`teq_backlog`, `google_drive`, `mattermost`) qua ToolSearch, không
hardcode tên server). Cần có tool khớp `teq_backlog` (bắt buộc), `google_drive`
(Bước 4, thiếu thì đánh dấu sheet `unknown`), `mattermost` (chỉ cần ở Bước 6). Nếu
server đang ở trạng thái "still connecting" (system reminder báo), gọi lại
ToolSearch chờ kết nối thay vì báo lỗi ngay. Thiếu hẳn `teq_backlog` → dừng, báo:
*"Backlog MCP chưa kết nối."*

## Quy trình

**Bước 1 — Danh sách ticket.** Mặc định `DEFAULT_MILESTONE` + `DEFAULT_TICKETS`,
user có thể ghi đè bằng argument. Trigger `Waiting for release` → chỉ ticket đó.
`teq_backlog-get_version_milestone_list` tìm milestone theo tên (không đoán id nếu
không thấy — ghi `WARNING`, vẫn chạy tiếp với ticket chỉ định) →
`teq_backlog-get_issues(milestone_ids, issue_type_ids=[ISSUE_TYPE_ID])`.

**Bước 2 — Resolve ticket.** Mỗi key phải khớp `SPCC-\d+`, lấy qua
`teq_backlog-get_issue`. Không khớp → `WARNING: "<key>" không đúng định dạng
Backlog`, bỏ qua. (Ticket có thể mang JIRA key riêng qua custom field/title — chỉ
dùng ở Bước 4, không dùng để resolve ở đây.) Gộp + loại trùng theo key Backlog.

**Bước 3 — FF có cần không + JIRA key.** Đọc `CF_IS_APPLIED_FF_ID`: `YES`/`NO` là
câu trả lời chính thức, không suy đoán từ mô tả. `NO` → xếp "Không cần FF", bỏ qua
Bước 4. Lấy JIRA key: ưu tiên `TITLE_JIRA_KEY_PATTERN`, fallback custom field
`JIRA Ticket`. Lấy `CF_FEATURE_FLAG_KEY_ID` nếu có (có thể trống dù = YES).

**Bước 4 — Đối chiếu Google Sheet (read-only).**

- `google_drive-read_file_content(fileId=FF_SHEET_FILE_ID)` **không tôn trọng
  `gid`** — thực tế từng trả về nhầm tab (tab sync Jira khác hẳn cấu trúc). Trước khi
  tin dữ liệu, **check header row khớp cấu trúc đã xác nhận** (flag/ステータス/
  test/dev/stg/prod) — không khớp = đọc nhầm tab, không phải "sheet thiếu cột".
  Không dùng CSV export (chỉ export sheet đầu, dễ nhầm tab).
- **Cách ưu tiên**: nhờ user paste trực tiếp dữ liệu tab `FeatureFlag` vào chat. Chỉ
  fallback sang tool đọc Drive khi user không tiện, và luôn validate header trước.
  Không khớp → `WARNING: không verify được tab FeatureFlag — nhờ user paste dữ
  liệu`, không bịa.
- Không sửa/tạo/copy/xóa gì trong Drive/Sheet.
- Nếu `FF_SHEET_OWNER_COL` / `FF_SHEET_JIRA_URL_COL_HEADER` còn `???` → **dừng lại,
  hỏi user** cấu trúc 2 cột đó trước khi lọc scope/match ticket, không tự đoán.
- Lọc dòng Fushigidane theo `FF_SHEET_OWNER_COL` (khớp `FUSHIGIDANE_LABELS`, không
  phân biệt hoa/thường; nhãn khác lạ thì ghi rõ, không tự quy đổi ngầm).
- Match ticket → hàng flag bằng **2 tín hiệu**: theo `Feature Flag Key` (cột A) và
  theo JIRA URL cross-reference (`FF_SHEET_JIRA_URL_COL_HEADER`, có thể nhiều URL
  cách dòng trong 1 cell). Cả 2 khớp cùng hàng → chắc chắn. Khác hàng → `WARNING:
  match mâu thuẫn`. Chỉ 1 tín hiệu khớp → vẫn báo found, ghi chú tín hiệu còn lại
  chưa xác nhận. Nhiều hàng cùng khớp 1 JIRA key → `WARNING: nhiều hàng FeatureFlag
  trùng — resolve thủ công`. Không hàng nào khớp → `WARNING: thiếu trong sheet
  FeatureFlag cho scope Fushigidane`.
- Hàng match có `ステータス` = `削除済` → không tính "found" bình thường, ghi
  `⚠️ flag đã đánh dấu xoá khỏi code — kiểm tra lại`.
- Hàng match hợp lệ (`実装済`) → báo đủ **4 môi trường** test/dev/stg/prod theo tên
  header thật. Không tìm thấy cột/giá trị → `unknown`, nêu rõ thiếu header nào.

**Bước 5 — Report** (ngắn gọn, trạng thái tại 1 thời điểm, không phải cố định):

```markdown
# Fushigidane — Kiểm tra Feature Flag — <milestone/ticket> (<ngày giờ>)

## ⚠️ Cảnh báo
- 🔴 [SPCC-XXXX](.../SPCC-XXXX) — Waiting for release, thiếu FF trong sheet
  Fushigidane. **Chặn release.**
- [SPCC-YYYY](.../SPCC-YYYY): flag `enable_yyy` khớp nhưng đang `削除済`.

## ✅ Feature flag đã tìm thấy
| Ticket | Tiêu đề | FF Key | test | dev | stg | prod |
|---|---|---|---|---|---|---|
| [SPCC-XXXX](...) | ... | `enable_xxx` | ON | ON | OFF | unknown (thiếu cột "prod") |

## ⬜ Ticket không cần Feature Flag
- [SPCC-XXXX](...) — Is Applied Feature Flag = NO
```

Cảnh báo đứng đầu; `Waiting for release` thiếu FF luôn đánh dấu 🔴 riêng.

**Bước 6 — Gửi Mattermost, CHỈ khi đã xác nhận.** Hiện report trong chat trước →
hỏi user xác nhận gửi + confirm `channel_id` (channel cũ không phải phép mặc định,
hỏi lại mỗi lần) → chỉ sau đó mới `mattermost-create_post`. User chỉ hỏi "check"
không nhắc Mattermost → dừng ở Bước 5, hỏi có muốn gửi không, không tự ý gửi.

## Việc không được làm

❌ Suy đoán "cần FF" từ mô tả thay vì đọc custom field. ❌ Tin dữ liệu Drive cho tab
FeatureFlag mà không check header trước. ❌ Dùng CSV export. ❌ Đoán cột owner/JIRA
URL khi còn `???`. ❌ Bịa status môi trường khi thiếu cột — ghi `unknown`. ❌ Coi flag
`削除済` là "found" bình thường. ❌ Gửi Mattermost không xác nhận. ❌ Sửa/tạo/xóa gì
trong Backlog/Drive/Sheet.

## Dấu hiệu cảnh báo

🚩 Header không khớp cấu trúc đã biết → sai tab, dừng lại nhờ user paste dữ liệu
thật. 🚩 Mọi ticket cùng 1 status FF → khả năng đọc nhầm tab. 🚩 Không bao giờ báo
`unknown` dù header lạ → khả năng bịa dữ liệu. 🚩 Gửi Mattermost chưa hỏi trước →
vi phạm an toàn, không được xảy ra.

## Khi thiếu MCP

Không có `teq_backlog` → báo lỗi, dừng. Không có `google_drive`/đọc sai tab → nhờ
user paste dữ liệu (vốn là cách ưu tiên), vẫn báo phần ticket, đánh dấu sheet
`unknown`. Không có `mattermost` → report vẫn hiện trong chat, ghi chú không gửi
được. Không tự gọi REST API, không fetch URL tùy tiện, không bịa dữ liệu.
