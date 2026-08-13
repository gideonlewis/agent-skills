# TRT Ticket Metadata

Snapshot này lưu category và issue template hiện tại của TEQ Backlog project
`TRT`.

- Snapshot date: 2026-06-12
- Source: TEQ Backlog project `TRT`
- Fetched via: `teq_backlog_get_issue_types`, `teq_backlog_get_categories`

File này là reference để agent hiểu convention hiện tại. Trước khi tạo hoặc
cập nhật ticket thật, vẫn phải fetch metadata runtime vì category/template/ID có
thể thay đổi.

## Issue Types

| Name | ID | Color | Template Summary |
|---|---|---|---|
| `Research` | `933683` | `#2779ca` | `Research Template` |
| `Evaluation` | `933686` | `#ff9200` | `Evaluation Template` |
| `Task` | `361416` | `#7ea800` | `Task Template` |
| `Bug` | `361415` | `#e30000` | `Bug Template` |

## Categories

| Name | ID |
|---|---|
| `internal-hub-mcp` | `508390` |
| `backlog-mcp` | `508391` |
| `ai-gateway` | `508392` |
| `mattermost-mcp` | `508393` |
| `research` | `508395` |
| `harness-agent` | `508396` |
| `agent-skill` | `508397` |
| `evaluation` | `508398` |
| `infrastructure` | `508399` |
| `data` | `508400` |

## Assignees

- Snapshot date: 2026-06-22
- Source: user-provided TRT member mapping

Match chính xác cột Mattermost username; không fuzzy-match username với Backlog
name hoặc `uniqueId`. Dùng `assignee_id` trong bảng mà không fetch user list
runtime. Nếu không có hoặc có nhiều match, resolve từ Backlog runtime. Không
hiển thị email nếu không cần thiết.

| Mattermost username | Backlog assignee_id | Backlog name | Email |
|---|---|---|---|
| `tantai` | `88723` | La Tấn Tài | `taila@teqnological.asia` |
| `baonguyen` | `147290` | Nguyen Quoc Bao | `baonguyen@teqnological.asia` |
| `nguyennn` | `352533` | Nguyen Ngoc Nguyen | `nguyennguyen@teqnological.asia` |
| `dinhnguyen` | `594778` | Nguyen Quang Dinh | `dinhnguyen@teqnological.asia` |
| `hieunguyen` | `491039` | Nguyễn Minh Hiếu | `hieunguyen@teqnological.asia` |
| `lyhoanam` | `197201` | Lý Hoa Nam | `namly@teqnological.asia` |
| `chiduong` | `599124` | chiduong | `chiduong@teqnological.asia` |
| `baogia` | `598237` | Nguyen Le Gia Bao | `baogia@teqnological.asia` |
| `baotran` | `88722` | Tran The Bao | `baotran@teqnological.asia` |
| `quangphan` | `429144` | Phan Ngoc Quang | `quangphan@teqnological.asia` |
| `thainguyen` | `589678` | Nguyen Hong Thai | `thainguyen@teqnological.asia` |
| `khanhtran` | `549892` | Trần Quốc Khánh | `khanhtran@teqnological.asia` |
| `thanhngo` | `598238` | Ngo Dinh Thanh | `thanhngo@teqnological.asia` |
| `quancao` | `555287` | quan cao | `quancao@teqnological.asia` |
| `trunghieu` | `492923` | Nguyen Nhat Hieu Trung | `trunghieu@teqnological.asia` |
| `tuannguyen` | `357740` | Nguyen Anh Tuan | `tuannguyen@teqnological.asia` |
| `maunguyen` | `602819` | Nguyen Van Mau | `maunguyen@teqnological.asia` |
| `nhatphat` | `201342` | Lê Đỗ Nhật Phát | `phatle@teqnological.asia` |

## Ticket Status TRT

Tất cả issue type dùng lifecycle `Open → In Progress → Resolved → Closed`.
`Resolved` nghĩa là developer đã done phần implementation và bàn giao output
cho reviewer; `Closed` là ticket creator close trực tiếp sau khi mọi Done
Conditions đã đạt và xem xét review result. Review cần sửa thì chuyển
`Resolved → In Progress`.

Trong các template bên dưới, mọi `Done Conditions` là tiêu chí trước khi
`Closed`; không phải checklist mặc định bắt buộc trước khi developer chuyển sang
`Resolved`. Với `Task`/`Bug` có code, bổ sung handoff update khi chuyển
`Resolved`: MR link, scope hoàn thành, self-check/cách review và Done Conditions
còn lại. Deploy hoặc verification trên dev có thể còn chưa tick ở `Resolved` và
phải hoàn tất trước `Closed` khi ticket hoặc release flow yêu cầu rõ. Lỗi phát
hiện sau production tạo ticket `Bug` mới thay vì reopen ticket gốc.

## Research Template

```md
## Question
What do we need to find out?

## Context
Why does this matter? Link source if any.

## Scope
What should / should not be covered?

## Output
Link to ai-platform-agora MR / design doc / ADR:

## Done Conditions
- [ ] Research question is answered in Agora doc/MR
- [ ] Key trade-offs are documented
- [ ] Recommendation is stated
- [ ] Reviewer/owner is assigned or mentioned
```

## Evaluation Template

```md
## Target
What are we evaluating? Agent / skill / MCP tool / prompt / workflow:

## Context
Why does this evaluation matter? Link source if any.

## Criteria
What does “good enough” mean?

## Cases
What sample cases / scenarios will be used?

## Output
Agora MR / doc:

## Done Conditions
- [ ] Evaluation target is clear
- [ ] Criteria and cases are documented
- [ ] Result is documented in Agora doc/MR
- [ ] Recommendation is stated
- [ ] Reviewer/owner is identified
```

## Task Template

```md
## Objective
What needs to be done?

## Context
Why does this matter? Link source if any.

## Scope
What is included / excluded?

## Output
MR / doc / config / deployed change:

## Done Conditions
- [ ] Output is delivered and linked
- [ ] Verification is completed
- [ ] Relevant ai-platform-agora documentation is updated and linked when the change affects documented design, configuration, interface, or operating procedure
- [ ] Reviewer/owner is identified
```

## Bug Template

```md
## Problem
What is wrong?

## Expected
What should happen?

## Actual
What happens instead?

## Impact
Who/what is affected?

## Evidence
Logs, screenshots, links, error message, source thread:

## Output
MR / fix / workaround / doc:

## Done Conditions
- [ ] Root cause or likely cause is identified
- [ ] Fix or workaround is delivered
- [ ] Verification is completed
- [ ] Output is linked
- [ ] Impacted owner/user is updated if needed
```
