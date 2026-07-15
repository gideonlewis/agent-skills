---
name: backlog-ticket-daily-summary-and-report
description: Read a Backlog ticket's description + comments and produce a concise daily-standup report per ticket — current state (QA? waiting on whom?), blockers to start, expected done date and delay risk, plus a short action checklist. Use for daily updates on one ticket or a milestone/assignee set of tickets.
---

# Backlog Ticket Daily Summary & Report — SPC-Collab

Đọc **description + comments** của ticket, tóm tắt thành báo cáo daily **vừa đủ**: hiện trạng, đang chờ ai/việc gì, còn vướng gì để bắt đầu, dự kiến xong khi nào và nguy cơ trễ — kèm checklist việc cần làm.

## When to Use

- "Daily report cho ticket SPCC-3184"
- "Tóm tắt tình trạng các ticket của [người] hôm nay"
- "Ticket này đang chờ gì, còn vướng gì?"
- "Update daily milestone Sprint 41"

Khác với skill bảng tổng hợp: skill này **đọc comments** và viết tóm tắt tình huống, không chỉ liệt kê status.

## Prerequisites

- Backlog MCP đã kết nối (có tool chứa `backlog` trong tên). Skill này lấy dữ liệu qua MCP; việc tóm tắt do model làm — **không cần script/Python**.

## Configuration

```
DOMAIN            = teq-dev.backlog.com
PROJECT_ID        = 149054
DEFAULT_MILESTONE = Sprint 41  (id 403686)
ISSUE_TYPE_ID     = 825231     # JP User Story
TEAM_MEMBERS = [
  "Huynh Ngoc Quan", "Nguyễn Ngọc Quỳnh Giao", "Nguyen Thi Bao Ngoc",
  "Bui Duc Tien", "Tran Chi Vi", "Lý Hoa Nam",
  "Huynh Thi Thu Thao", "Bui Nhu Oanh", "Tran Hoang Oanh"
]
```

## Process

### Phase 1: Parse Arguments

Trích từ message của user:
- **Ticket key(s)** — vd `SPCC-3184` (nếu có → chỉ báo cáo các ticket này)
- **Assignee** — tên/ID (optional)
- **Milestone** — mặc định `Sprint 41`

Ưu tiên: nếu có ticket key → dùng trực tiếp. Nếu không → lấy danh sách theo milestone (+ assignee nếu có), lọc `issueType.id == 825231` và `assignee ∈ TEAM_MEMBERS`.

### Phase 2: Discover Backlog Tools

`ToolSearch` query `backlog`. Cần các tool:

| Purpose | Tool name |
|---|---|
| Get issue detail | `backlog_get_issue` / `mcp__backlog__get_issue` |
| **Get issue comments** | `backlog_get_issue_comments` / `mcp__backlog__get_issue_comments` |
| List issues | `backlog_get_issues` |
| List milestones / users | `backlog_get_versions` / `backlog_get_users` |

Nếu không tìm thấy tool nào chứa `backlog` → dừng, báo user kết nối Backlog MCP (xem cuối file).

### Phase 3: Fetch Content — Description + Comments

Cho **mỗi** ticket:
1. Lấy issue detail → `summary`, `description`, `status`, `assignee`, `dueDate`, `updated`, JP Priority.
2. **Lấy toàn bộ comments** (đây là điểm cốt lõi, đừng bỏ qua). Đọc theo thứ tự thời gian, ưu tiên các comment gần nhất.

### Phase 4: Analyze — Trả lời các câu hỏi report

Từ description + comments, suy ra:
- **Hiện trạng:** đang code / đã lên QA / chờ review / chờ release / done?
- **Đang chờ ai / việc gì:** chờ QA test, chờ PO confirm spec, chờ merge, chờ deploy, chờ khách phản hồi…
- **Blocker để bắt đầu:** còn thiếu spec? thiếu design? phụ thuộc ticket khác? môi trường chưa sẵn?
- **Dự kiến xong:** từ dueDate + tiến độ trong comments. Có **nguy cơ trễ** không (deadline gần mà còn nhiều việc / stuck / không update lâu)?
- **Việc cần làm tiếp:** các action cụ thể để đẩy ticket đi tiếp.

Heuristics:
- `updated` cách ≥ 5 ngày và chưa done → cảnh báo **stuck / cần theo dõi**.
- `dueDate` còn ≤ 2 ngày mà status chưa ở Testing/Release → **nguy cơ trễ**.
- Comment gần nhất là câu hỏi chưa được trả lời → **đang chờ phản hồi**.

### Phase 5: Render — Báo cáo daily per-ticket

Mỗi ticket một block **ngắn gọn, vừa đủ** (không copy nguyên comments):

```markdown
### [SPCC-3184](https://teq-dev.backlog.com/browse/SPCC-3184) Tiêu đề ticket
🔄 In Progress · Huynh Ngoc Quan · Deadline 2026-07-18

**📌 Cần chú ý**
- Đã lên QA, đang chờ Thao test — chưa có kết quả sau 2 ngày.
- Còn vướng: spec màn hình filter chưa được PO confirm.

**✅ Việc cần làm**
- [ ] Ping QA (Thao) xin kết quả test
- [ ] Chốt spec filter với PO trước khi code phần còn lại

**⏱ Tiến độ:** Dự kiến xong 2026-07-18 · ⚠️ Nguy cơ trễ (deadline 3 ngày, còn chờ QA + spec)
```

**Nguyên tắc bố cục:**
- Dòng đầu: status icon · assignee · deadline.
- **📌 Cần chú ý** — 1–3 gạch đầu dòng thông tin quan trọng nhất (đang chờ gì, vướng gì).
- **✅ Việc cần làm** — checklist action cụ thể, ghi rõ ai làm nếu biết.
- **⏱ Tiến độ** — dự kiến xong + cảnh báo trễ (bỏ qua nếu đã done).

Nhiều ticket → xếp theo: nguy cơ trễ / stuck lên trước, rồi JP Priority (Must → Should), rồi status.

## Anti-patterns to Avoid

- ❌ **KHÔNG bỏ qua comments** — đây là nguồn chính để biết hiện trạng thực tế (ngược với skill bảng cũ).
- ❌ Không copy nguyên văn comments/description — phải **tóm tắt**.
- ❌ Không viết dài dòng — daily cần đọc lướt trong vài giây. Mỗi mục 1–3 dòng.
- ❌ Không đoán ID — resolve milestone/user name → ID qua MCP trước.
- ❌ Không bịa "nguy cơ trễ" nếu comments không đủ căn cứ — nói rõ khi thiếu thông tin.

## Red Flags

🚩 Report dài hơn ~8 dòng/ticket → đang quá chi tiết cho daily.
🚩 Không có mục "Việc cần làm" → report chưa actionable.
🚩 Bỏ qua comment gần nhất → dễ sai hiện trạng.

## Notes When Backlog MCP Is Not Connected

Nếu không có tool nào chứa `backlog`:
> "Backlog MCP chưa kết nối. Hãy cấu hình MCP server trong settings.json rồi restart Claude Code."

Không tự gọi REST API, không fetch URL tùy tiện, không bịa token.
