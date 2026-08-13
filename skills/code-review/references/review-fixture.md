# Code Review Fixture

Fixture này dùng để kiểm tra skill `code-review` mà không cần dùng MR thật.

## Fixture 1: Có Blocker

### Mattermost Thread Input

Root post:

```text
@ai-platform-pm review MR này giúp em:
https://git.teqnological.asia/ai-platform/mcp/example-service/-/merge_requests/42
@reviewer-nguyen review giúp @dev-tran phần MCP tool schema với security nhé.
```

Replies:

```text
@dev-tran: MR này thêm tool update_issue_status, có thêm env BACKLOG_TOKEN.
@reviewer-nguyen: Nhờ check kỹ side effect description và token logging.
```

### GitLab Evidence Input

MR metadata:

- Repo: `ai-platform/mcp/example-service`
- MR: `!42 Add update_issue_status tool`
- MR description: `Refs TRT-201`
- Author: `dev-tran`
- Reviewer: `reviewer-nguyen`
- Pipeline: không có thông tin liên quan trong thread; không cần nhắc trong
  review output.

Backlog ticket input:

- Issue: `TRT-201`
- Status: `In Progress`
- Summary: `Add Backlog update_issue_status MCP tool`
- Done conditions:
  - Tool schema follows MCP naming and parameter guidelines.
  - Write tool side effect is documented.
  - Sensitive auth headers are not logged.
  - Design REF: `docs/design-docs/data-platform/mcp/mcp-tool-design-guidelines.md`.

Diff summary:

- Adds raw tool `backlog_update_issue_status`.
- Input parameter uses `id` instead of `issue_id_or_key`.
- Tool description does not mention state change or notification side effect.
- Error logging prints full request headers, including `Authorization`.
- Changed files gồm nhiều file implementation và test; expected output không
  thêm `Diff chính` hoặc danh sách path trong `Evidence`.
- Test coverage không phải concern của fixture này vì thread yêu cầu focus MCP
  tool schema và security; expected output không cần tự thêm review test.

### Expected Review Shape

```markdown
**Reviewer:** @reviewer-nguyen | **Implementer:** @dev-tran
**Kết luận:** cần sửa trước khi merge vì có 2 blockers về secret logging và MCP tool contract.
**Ticket action:** Hiện `In Progress`. Next action: @dev-tran xử lý B1/B2 và cập nhật MR với evidence đủ để reviewer review.

**Blockers**
- **[B1][Security]** Tool đang log full request headers nên có nguy cơ leak `Authorization`.
  **Location/Evidence:** diff logging block trong MR !42. **Impact:** lộ secret trong logs.
  **Next action:** @dev-tran mask/drop sensitive headers trước khi log.
- **[B2][Contract]** Tool name/parameter contract chưa khớp guideline: raw tool lặp domain
  `backlog_` và parameter `id` mơ hồ. **Location/Evidence:** input schema block của
  `backlog_update_issue_status` khai báo field `id` thay vì `issue_id_or_key`.
  **Impact:** AI dễ gọi sai tham số khi chọn tool.
  **Next action:** @dev-tran đổi raw tool thành `update_issue_status` và dùng
  `issue_id_or_key`.

**Recommendations**
- **[R1][Contract]** Description nên nói rõ đây là write tool, có thể đổi Backlog state và
  trigger notification. **Location/Evidence:** tool description trong MR !42.
  **Impact:** người review/agent khó biết tool có thể đổi trạng thái. **Next action:** @dev-tran
  cập nhật description để reviewer kiểm tra lại.

**REF:** MR https://git.teqnological.asia/ai-platform/mcp/example-service/-/merge_requests/42 | Backlog [TRT-201](https://teq-dev.backlog.com/view/TRT-201) | Design `docs/design-docs/data-platform/mcp/mcp-tool-design-guidelines.md`
```

## Fixture 2: Không Có Blocker

### Mattermost Thread Input

Root post:

```text
@ai-platform-pm review MR này giúp em:
https://git.teqnological.asia/ai-platform/agents/ai-platform-pm-agent/-/merge_requests/43
@reviewer-nguyen review giúp @dev-tran phần prompt wording và output format nhé.
```

Replies:

```text
@dev-tran: MR này chỉ sửa SKILL.md để bỏ dòng Diff chính trong Evidence.
@reviewer-nguyen: Nhờ check xem có đúng format Mattermost review không.
```

### GitLab Evidence Input

MR metadata:

- Repo: `ai-platform/agents/ai-platform-pm-agent`
- MR: `!43 Tighten code-review Evidence output`
- MR description: `Refs TRT-202`
- Author: `dev-tran`
- Reviewer: `reviewer-nguyen`
- Pipeline: không liên quan tới requested focus; không cần nhắc trong output và
  không đưa vào `Missing evidence`.

Backlog ticket input:

- Issue: `TRT-202`
- Status: `Resolved`
- Summary: `Tighten code-review Mattermost output`
- Done conditions:
  - Review output does not list changed files in `Evidence`.
  - Findings use precise evidence and remain concise.

Diff summary:

- Updates `skills/code-review/SKILL.md`.
- Removes `Diff chính` from default `Evidence` output.
- Adds explicit rule that file paths belong inside findings only when they are
  direct evidence.
- No auth, secret, runtime config, data model, or MCP tool schema changes.

### Expected Review Shape

```markdown
**Reviewer:** @reviewer-nguyen | **Implementer:** @dev-tran
**Kết luận:** Không thấy blocker. MR đúng hướng để làm review output ngắn hơn và tránh list file trong Evidence.
**Ticket action:** Giữ `Resolved`; ticket creator đối chiếu Done Conditions và review result để quyết định close.

**Blockers**
Không thấy blocker.

**Recommendations**
- **[R1][Test/Eval]** Nếu team muốn giữ hành vi này ổn định, nên thêm fixture/eval cho case "không list changed files".
  **Location/Evidence:** rule mới trong `skills/code-review/SKILL.md`. **Impact:** giảm nguy cơ output format bị đổi lại.
  **Next action:** @dev-tran cân nhắc thêm fixture/eval cho case này.

**REF:** MR https://git.teqnological.asia/ai-platform/agents/ai-platform-pm-agent/-/merge_requests/43 | Backlog [TRT-202](https://teq-dev.backlog.com/view/TRT-202)
```

## Fixture 3: Thiếu TRT Trong MR Description

### Mattermost Thread Input

Root post:

```text
@ai-platform-pm review MR này giúp em:
https://git.teqnological.asia/ai-platform/mcp/example-service/-/merge_requests/44
@reviewer-nguyen review giúp @dev-tran phần schema nhé.
```

### GitLab Evidence Input

MR metadata:

- Repo: `ai-platform/mcp/example-service`
- MR: `!44 Update tool schema wording`
- MR description: `Improve wording for update_issue_status.`
- Author: `dev-tran`
- Reviewer: `reviewer-nguyen`

Diff summary:

- Updates description text only.
- No runtime code, auth, secret, data model, or MCP parameter schema changes.

### Expected Review Shape

```markdown
**Reviewer:** @reviewer-nguyen | **Implementer:** @dev-tran
**Kết luận:** Không thấy blocker về code, nhưng MR cần bổ sung mã TRT trong description để đảm bảo traceability.

**Blockers**
Không thấy blocker.

**Recommendations**
- **[R1][Traceability]** MR description chưa có mã `TRT-<number>`.
  **Location/Evidence:** MR !44 description. **Impact:** reviewer không có Backlog context để đối chiếu scope/done conditions.
  **Next action:** @dev-tran thêm mã TRT liên quan vào MR description.

**REF:** MR https://git.teqnological.asia/ai-platform/mcp/example-service/-/merge_requests/44 | Backlog missing
```

## Fixture 4: Thiếu Design REF Khi Đổi Contract

### Mattermost Thread Input

Root post:

```text
@ai-platform-pm review MR này giúp em:
https://git.teqnological.asia/ai-platform/mcp/example-service/-/merge_requests/45
@reviewer-nguyen review giúp @dev-tran phần contract change nhé.
```

### GitLab Evidence Input

MR metadata:

- Repo: `ai-platform/mcp/example-service`
- MR: `!45 Change MCP auth envelope`
- MR description: `Refs TRT-203`
- Author: `dev-tran`
- Reviewer: `reviewer-nguyen`

Backlog ticket input:

- Issue: `TRT-203`
- Status: `In Progress`
- Summary: `Change MCP auth envelope`
- Done conditions:
  - Update auth envelope used by gateway to call MCP tools.
  - Preserve compatibility or document migration path.
  - No design REF is linked in the ticket.

Diff summary:

- Changes the auth envelope fields used between gateway and MCP server.
- Updates request parsing and error handling.
- No Agora design doc or ADR link is present in MR description, ticket, or thread.

### Expected Review Shape

```markdown
**Reviewer:** @reviewer-nguyen | **Implementer:** @dev-tran
**Kết luận:** Không thấy blocker về code. Cần bổ sung design REF để reviewer xác nhận thay đổi contract.
**Ticket action:** Hiện `In Progress`. Next action: @dev-tran bổ sung design REF để reviewer có context xác nhận thay đổi contract.

**Blockers**
Không thấy blocker.

**Recommendations**
- **[R1][Design]** MR thay đổi auth envelope giữa gateway và MCP server nhưng chưa có REF tới Agora design doc/ADR.
  **Location/Evidence:** MR !45 description và TRT-203 không có design REF. **Impact:** reviewer khó xác nhận ranh giới, cách tương thích và hướng chuyển đổi.
  **Next action:** @dev-tran bổ sung link design doc/ADR hoặc cập nhật Agora docs trước khi review tiếp phần contract.

**REF:** MR https://git.teqnological.asia/ai-platform/mcp/example-service/-/merge_requests/45 | Backlog [TRT-203](https://teq-dev.backlog.com/view/TRT-203) | Design missing
```

## Fixture 5: Chỉ Mention Bot, Chưa Rõ Human Reviewer

### Mattermost Thread Input

Root post author: `@requester-nguyen`

Root post:

```text
@ai-platform-pm review MR này giúp em:
https://git.teqnological.asia/ai-platform/agents/ai-platform-pm-agent/-/merge_requests/46
```

Replies:

```text
@dinhnguyen: MR này sửa validation cho heatmap payload.
```

### GitLab Evidence Input

MR metadata:

- Repo: `ai-platform/agents/ai-platform-pm-agent`
- MR: `!46 Fix heatmap payload validation`
- MR description: `Refs TRT-204`
- Author: `dinhnguyen`
- Reviewer: chưa có reviewer trong MR metadata.

Backlog ticket input:

- Issue: `TRT-204`
- Status: `In Progress`
- Summary: `Fix offwork heatmap payload validation`
- Done conditions:
  - Payload validation accepts batch heatmap records.
  - Regression test covers list payload.

Diff summary:

- Changes heatmap input schema from single record to list payload.
- Adds regression coverage for batch payload.
- No design-impacting contract change outside the existing tool behavior.

### Expected Review Shape

```markdown
**Reviewer:** @requester-nguyen (inferred từ root post author; MR chưa có reviewer) | **Implementer:** @dinhnguyen
**Kết luận:** Không thấy blocker. MR khớp TRT-204 và sửa đúng hướng cho payload nhiều heatmap record.
**Ticket action:** Hiện `In Progress`. Next action: ticket creator/owner xác định human reviewer trước khi developer handoff ticket.

**Blockers**
Không thấy blocker.

**Recommendations**
- **[R1][Test/Eval]** Nếu còn follow-up sau merge, nên giữ fixture/eval cho payload dạng list để tránh bug quay lại.
  **Location/Evidence:** schema `items: list[HeatmapRecordInput]` và case test/eval trong MR !46.
  **Impact:** mất test/eval chặn bug quay lại nếu fixture/eval không được commit.
  **Next action:** @dinhnguyen xác nhận fixture/eval chống bug quay lại đã nằm trong MR.

**REF:** MR https://git.teqnological.asia/ai-platform/agents/ai-platform-pm-agent/-/merge_requests/46 | Backlog [TRT-204](https://teq-dev.backlog.com/view/TRT-204)
```

## Fixture 6: Ticket Resolved Chờ Code Review

### Input

- Backlog: `TRT-205`, status `Resolved`.
- MR `!47` đang open, có link TRT-205 và chưa merge/deploy.
- Done Conditions có deploy dev và smoke test sau merge.
- Diff và self-check đủ để reviewer review; không có required check failed.

### Expected Review Rules

- Không tạo `Missing evidence` hay recommendation chỉ vì chưa deploy dev/pipeline.
- Review chỉ đánh giá code và điều kiện merge readiness.
- Nếu không có blocker: kết luận MR có thể approve/merge; `**Ticket action:**`
  giữ `Resolved`, nêu deploy dev và smoke test là điều kiện còn lại trước
  `Closed`.
- Nếu reviewer phát hiện blocker phải sửa: `**Ticket action:**` đề xuất
  `Resolved -> In Progress`, owner là implementer.
- Khi deploy dev và smoke test của ticket đã đạt, reviewer bàn giao review result
  để ticket creator đóng trực tiếp `Resolved -> Closed`;
  không yêu cầu comment hoặc approval artifact riêng.

## Fixture 7: Short Format Với Ticket Resolved

### Input

- Backlog: `TRT-206`, status `Resolved`.
- MR `!48` đã merge; code review không có blocker.
- Done Conditions có deploy dev và smoke test sau merge, chưa có evidence.

### Expected Review Shape

```markdown
**Reviewer:** @reviewer-nguyen | **Implementer:** @dev-tran
**Kết luận:** Không thấy blocker code.
**Ticket action:** Giữ `Resolved`; deploy dev và smoke test là Done Conditions còn lại trước `Closed`.
**Findings:** Không thấy finding cần sửa trước merge.
**REF:** MR https://git.teqnological.asia/ai-platform/mcp/example-service/-/merge_requests/48 | Backlog [TRT-206](https://teq-dev.backlog.com/view/TRT-206)
```
