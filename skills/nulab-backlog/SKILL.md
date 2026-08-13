---
name: nulab-backlog
description: >
  Chỉ dùng skill này cho vòng đời ticket Backlog và theo dõi execution của
  team: tạo hoặc cập nhật ticket, quản lý status, assignee, priority,
  milestone, due date, blocker và evidence, fetch metadata project, hoặc tóm
  tắt tiến độ ticket cho TRT và các project AI Platform liên quan. Không dùng
  Backlog như knowledge base của AI Platform; dùng skill knowledge-search cho
  tri thức.
version: 0.2.12
author: TEQ AI Platform
license: Internal
metadata:
  hermes:
    tags:
      [backlog, project-management, ai-platform, tickets, research, evaluation]
---

# Backlog

Skill này hướng dẫn AI Platform PM agent làm việc với Backlog theo cách nhất
quán, đặc biệt cho project `TRT` của AI Platform.

## Khi Nào Dùng

Dùng skill này khi user cần:

- Tạo, cập nhật, hoặc chuẩn bị nội dung Backlog ticket.
- Chọn `Issue Type`, `Category`, priority, assignee, due date, hoặc milestone.
- Chuyển action từ Mattermost, Agora design doc, MR, hoặc ghi chú họp thành
  ticket để theo dõi execution.
- Tổng hợp tiến độ, blocker, owner, deadline, hoặc next action từ Backlog.
- Kiểm tra taxonomy ticket cho môi trường R&D của AI Platform.

Không dùng skill này như một knowledge base. Tri thức dài hạn của AI Platform
phải được xử lý qua skill `knowledge-search`.

Không dùng skill này cho câu hỏi coding thuần túy nếu không liên quan tới
Backlog, ticket coordination, tiến độ, hoặc issue management.

## Nguyên Tắc Chung

- Dùng Backlog làm execution tracker và Agora làm knowledge base.
- Giữ ticket đủ thông tin để điều phối và link sang output/source dài hạn.
- Khi user cần hiểu nội dung knowledge, follow link và đọc tài liệu gốc trong
  Agora thay vì suy luận từ metadata hoặc mô tả ticket.
- Không bịa issue key, trạng thái, owner, deadline, template, hoặc category.
- Luôn fetch `Category`, `milestone`, user list, priority ID, issue type ID, và
  issue template từ Backlog runtime trước khi dùng cho ticket thật.
- Khi tạo issue mới, luôn gắn ít nhất một `Category` hợp lệ của project. Nếu
  chưa xác định được category từ metadata runtime và context user, hỏi lại
  trước; không tạo issue với category trống.
- Khi tạo issue mới, mặc định gắn latest active `milestone` của project trừ khi
  user chỉ định milestone khác hoặc nói rõ không cần milestone. Latest active
  milestone phải lấy từ runtime, ưu tiên milestone chưa archived có chu kỳ mới
  nhất/current nhất; nếu nhiều candidate hoặc không có candidate rõ ràng, hỏi
  lại thay vì đoán ID.
- Khi cần tạo/cập nhật ticket thật, dùng tool Backlog runtime nếu đang expose.
- Khi lookup hoặc assign TRT member, đọc `references/trt-ticket-metadata.md` và
  match chính xác Mattermost username; chỉ dùng `teq_backlog_get_project_user_list`
  khi mapping không có hoặc mơ hồ, và không query workload nếu user không hỏi.
- Đọc `references/trt-ticket-metadata.md` khi cần xem snapshot category và
  issue template hiện tại của project `TRT`. Reference này không thay thế việc
  fetch metadata runtime trước khi ghi Backlog thật.
- Chỉ update Backlog khi user yêu cầu rõ. Nếu target, status, assignee, date,
  hoặc nội dung còn mơ hồ, hỏi lại hoặc đưa draft trước.
- Khi trả lời về ngày, dùng ngày cụ thể thay vì "hôm nay", "mai", "tuần sau".
- Khi hiển thị mã ticket cho user, luôn render mã đó dưới dạng Markdown link.
  Ưu tiên URL do Backlog runtime trả về. Nếu chỉ có issue key của TEQ Backlog
  như `TRT-123`, dùng format `[TRT-123](https://teq-dev.backlog.com/view/TRT-123)`.
  Với project/space khác, fetch hoặc dùng URL runtime; không đoán domain.

## Fast Path Cho Tool Backlog

Các tool Backlog dưới đây là deferred tools phổ biến. Khi exact tool name phù
hợp với request, gọi `tool_describe` bằng tên đó để lấy schema runtime rồi gọi
tool; không gọi `tool_search` trước. Chỉ fallback về `tool_search` khi tool
không khả dụng, tên đã đổi, hoặc không có tool nào trong danh sách phù hợp.

Đọc và tìm ticket:

- `mcp_teq_ai_gateway_teq_backlog_get_issues`
- `mcp_teq_ai_gateway_teq_backlog_get_issue`
- `mcp_teq_ai_gateway_teq_backlog_count_issues`
- `mcp_teq_ai_gateway_teq_backlog_get_issue_comments`
- `mcp_teq_ai_gateway_teq_backlog_get_user_recent_updates`

Tạo và cập nhật ticket:

- `mcp_teq_ai_gateway_teq_backlog_add_issue`
- `mcp_teq_ai_gateway_teq_backlog_update_issue`
- `mcp_teq_ai_gateway_teq_backlog_add_issue_comment`

Lấy metadata runtime:

- `mcp_teq_ai_gateway_teq_backlog_get_myself`
- `mcp_teq_ai_gateway_teq_backlog_get_project`
- `mcp_teq_ai_gateway_teq_backlog_get_project_user_list`
- `mcp_teq_ai_gateway_teq_backlog_get_categories`
- `mcp_teq_ai_gateway_teq_backlog_get_issue_types`
- `mcp_teq_ai_gateway_teq_backlog_get_priorities`
- `mcp_teq_ai_gateway_teq_backlog_get_version_milestone_list`

Không copy hoặc suy đoán schema/arguments từ skill này. `tool_describe` là
source of truth cho parameters hiện tại.

## Quy Tắc Closed Issues

- Current/open workload: bắt buộc query non-Closed ngay từ Backlog khi tool hỗ
  trợ, ví dụ `status_ids`/`statusId: [1, 2, 3]`; chỉ filter phía agent nếu tool
  không hỗ trợ status filter.
- Explicit closed/done/history/all hoặc lookup issue key/permalink/title cụ thể:
  include `Closed` và ghi rõ status.
- Date-range updates: include issue có activity trong khoảng được hỏi, kể cả đã
  hoặc vừa chuyển `Closed`; không được nói "không có update" vì đã lọc mất
  `Closed`.
- Nếu mơ hồ giữa current workload và history/activity, hỏi lại hoặc nêu rõ
  assumption trước khi lọc.

## Project Mặc Định

Với AI Platform R&D, mặc định dùng TEQ Backlog project `TRT` nếu user không đưa
project khác và ngữ cảnh đang nói về AI Platform, MCP, Gateway, agent, skill,
evaluation, infrastructure, hoặc data.

Metadata cố định của `TRT`:

- `projectKey`: `TRT`
- `projectId`: `73380`
- `name`: `TEQ - R&D`

Khi query issue của `TRT`, dùng `project_ids: [73380]` trực tiếp; không gọi
project list chỉ để resolve project. Chỉ fetch project list khi user đưa
project khác, runtime báo project lỗi, hoặc cần kiểm tra metadata động.

Các issue type chuẩn của `TRT`:

- `Research`
- `Task`
- `Evaluation`
- `Bug`

Không hardcode category hoặc template của `TRT` trong skill body. Snapshot
tham khảo nằm ở `references/trt-ticket-metadata.md`; khi cần tạo/cập nhật
ticket thật, vẫn lấy danh sách hiện tại từ Backlog project metadata.

## Chọn Issue Type

Chọn theo bản chất công việc:

| Issue Type   | Dùng khi                                                                                 | Không dùng khi                               |
| ------------ | ---------------------------------------------------------------------------------------- | -------------------------------------------- |
| `Research`   | Cần giảm unknown, so sánh hướng, đọc source/docs, PoC nhỏ, hoặc ra recommendation.       | Đã rõ việc cần execute.                      |
| `Task`       | Việc đã tương đối rõ: implement, setup, config, docs, rollout, cleanup.                  | Chưa biết hướng đúng hoặc cần đo chất lượng. |
| `Evaluation` | Đo một artifact/workflow đã có: agent, skill, MCP tool, prompt, model, output quality.   | Chưa có target cụ thể để đo.                 |
| `Bug`        | Có expected behavior nhưng actual behavior sai, regression, incident, hoặc lỗi vận hành. | Đây là việc mới hoặc research/evaluation.    |

Heuristic ngắn:

- `Research`: nên làm gì?
- `Task`: làm việc đã rõ.
- `Evaluation`: cái đã có đủ tốt chưa?
- `Bug`: cái đang có chạy sai chỗ nào?

## Workflow Tạo Ticket

1. Xác định project. Nếu là AI Platform R&D và không có project khác, dùng `TRT`.
2. Đọc `references/trt-ticket-metadata.md` nếu cần snapshot category/template
   để draft nhanh hoặc hiểu convention hiện tại.
3. Fetch issue types và categories hiện tại của project nếu sẽ tạo ticket thật.
   Lấy `id`, `name`, `templateSummary`, và `templateDescription` của issue type
   nếu tool có trả về.
4. Fetch milestone hiện tại của project nếu sẽ tạo ticket thật, rồi áp dụng
   rule milestone mặc định trong `Nguyên Tắc Chung`.
5. Xác định issue type bằng bảng trên, rồi map sang ID runtime. Không đoán ID.
   Nếu template runtime khác với convention trong hội thoại, dùng template
   runtime. Nếu không fetch được template, ghi rõ template chưa được xác nhận
   và hỏi user muốn draft plain description hay chờ kiểm tra metadata.
6. Chọn ít nhất một category từ danh sách runtime theo area/component. Nếu
   không có category phù hợp hoặc không đủ context để chọn, hỏi user trước khi
   tạo; không để trống category cho issue mới.
7. Xác định assignee/owner từ user, requester, hoặc context được nêu rõ. Với
   TRT member, map theo `references/trt-ticket-metadata.md`; nếu không chắc,
   fetch user runtime hoặc hỏi lại.
8. Viết summary ngắn, bắt đầu bằng area khi hữu ích:
   - `Evaluate PM agent quality for Backlog ticket creation`
   - `Research gateway options for controlled MCP access`
   - `Add Backlog ticket templates to PM agent skill`
9. Dùng `templateDescription` hiện tại của issue type nếu Backlog metadata trả
   về. Giữ Backlog description đủ điều phối; link sang Agora cho knowledge
   artifact hoặc nội dung dài.
10. Nếu tạo/cập nhật thật, payload issue mới phải có category ID hợp lệ và
    milestone ID đã chọn khi milestone áp dụng. Với child ticket, áp dụng
    thêm `Workflow Parent/Child Ticket`.
11. Sau khi tạo/cập nhật, trả issue key dạng Markdown link và tóm tắt
    owner/date/next action.

## Workflow Parent/Child Ticket

Khi tạo hoặc cập nhật nhóm ticket parent/child:

- Parent ticket là tracker điều phối; child ticket là execution item cụ thể.
- Khi tạo child từ parent hoặc cùng một source note/MR, payload phải có
  `parentIssueId` đã fetch/verify từ parent; không chỉ ghi parent key trong
  description. Ghi parent key trong `Context` của child và dùng milestone nhất
  quán với parent. Nếu parent đã có milestone hợp lệ, child dùng cùng milestone
  của parent dù milestone đó lệch latest active hiện tại, trừ khi user yêu cầu
  align/update milestone. Nếu parent chưa có milestone hoặc đang tạo
  parent/child cùng lúc, dùng latest active milestone đã fetch từ runtime.
- Nếu parent được tạo từ requester/owner rõ ràng, assign parent cho requester
  hoặc owner đó; không để parent unassigned nếu child đã có requester rõ ràng.
- Khi tạo child đầu tiên hoặc chuyển child sang `In Progress`, kiểm tra parent.
  Parent tracker không nên còn `Open` nếu workflow đã bắt đầu; update parent
  sang `In Progress` khi user yêu cầu hoặc policy workflow trong request hàm ý
  parent follow child status.
- Không auto `Resolved`/`Closed` parent chỉ vì một child xong nếu còn child hoặc
  Done Conditions chưa được xác nhận. Nếu có nhiều child và trạng thái không
  đồng nhất, nêu rõ assumption hoặc hỏi lại trước khi update parent.

## Vòng Đời Status TRT

Với ticket TRT, dùng đúng bốn status và không tạo status kỹ thuật trung gian:

```text
Open → In Progress → Resolved → Closed
                    ↘ In Progress (khi review cần sửa)
```

| Status        | Ý nghĩa                                                                                                                                              | Người chịu next action                                            | Người chuyển vào status                                |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------ |
| `Open`        | Ticket đã xác định nhưng chưa bắt đầu.                                                                                                               | Ticket creator/owner phân công hoặc khởi động công việc.          | Ticket creator khi tạo ticket.                         |
| `In Progress` | Implementer đang phân tích, thực hiện, hoặc xử lý feedback review.                                                                                   | Implementer.                                                      | Implementer khi bắt đầu hoặc tiếp tục xử lý công việc. |
| `Resolved`    | Developer đã **done phần implementation** và bàn giao artifact để reviewer review. Đây là điểm dừng review, chưa phải ticket hoàn tất end-to-end.    | Reviewer review; ticket creator theo dõi điều kiện close còn lại. | Developer khi handoff artifact.                        |
| `Closed`      | Ticket creator đối chiếu mọi Done Conditions và kết quả review, rồi chuyển trực tiếp sang `Closed`. Thao tác close là quyết định của ticket creator. | Không còn action trong scope ticket.                              | Ticket creator.                                        |

Khi chuyển `In Progress → Resolved`, ticket phải có artifact bàn giao phù hợp
(`MR` cho code, hoặc doc/output cho loại việc khác), tóm tắt scope đã hoàn
thành, cách reviewer kiểm tra/self-check, và điều kiện còn lại trước khi
`Closed`. Không cần toàn bộ Done Conditions đã tick: điều kiện chỉ xác minh
được sau merge, như deploy dev hoặc verification trên dev, được phép còn mở ở
`Resolved`. Chỉ yêu cầu các điều kiện phải có **trước review** theo policy merge
hoặc ticket.

Khi reviewer yêu cầu sửa hoặc chưa accept implementation, chuyển
`Resolved → In Progress` và ghi implementer cùng next action. Reviewer cung cấp
review result; nếu reviewer khác ticket creator thì không tự quyết định close.
Chỉ ticket creator chuyển
`Resolved → Closed` khi mọi Done Conditions đã được xác minh. Với feature, bug,
hoặc thay đổi có runtime impact, verification trên dev chỉ là điều kiện close
khi ticket hoặc release flow yêu cầu rõ; nếu không, thiếu evidence này không tự
chặn ticket creator close. Không cần comment hoặc approval artifact riêng;
ticket creator ra quyết định close dựa trên checklist và review result hiện có. Production
không là điều kiện đóng ticket gốc: lỗi phát hiện sau production là ticket `Bug`
mới (link ticket gốc khi hữu ích), không tự reopen ticket đã `Closed`. Không
suy ra ticket status chỉ từ MR đang open/merged hay từ một deploy artifact.

## Workflow Update Status/Evidence

Khi user yêu cầu update ticket dựa trên Mattermost thread, MR, chat, hoặc log:

- Chỉ đổi status khi user/source nói rõ trạng thái mới.
- Nếu ticket được update là child có `parentIssueId`, fetch parent trước khi
  đổi status và quyết định parent có cần follow status không theo workflow
  parent/child ở trên.
- Backlog comment phải là audit trail ngắn: status change + direct evidence
  links; không tóm tắt thread.
- Đọc `references/status-evidence-comment.md` trước khi viết Backlog comment
  hoặc update status/evidence từ Mattermost/MR/log.
- Diễn giải status theo `Vòng Đời Status TRT` trước khi đánh giá evidence. Với
  ticket `Resolved`, chỉ xác nhận handoff đã đủ để review và nêu rõ Done
  Conditions còn mở; không coi deploy/verification sau merge chưa tick là thiếu
  evidence mặc định.
- Nếu evidence chưa đủ, hỏi lại hoặc ghi rõ phần còn thiếu; không tự suy diễn.

## Workflow Tổng Hợp Tiến Độ

Khi user hỏi trạng thái hoặc cập nhật:

- Áp dụng `Quy Tắc Closed Issues` trước khi query/filter.
- Với current/open workload, chỉ liệt kê issue chưa `Closed`.
- Với search theo issue key/permalink/title, explicit closed/history request,
  hoặc update theo ngày/khoảng thời gian, không được tự động loại `Closed`.
- Nhóm theo issue type, category, status, hoặc milestone tùy câu hỏi.
- Với mỗi issue quan trọng, nêu: issue key dạng Markdown link, status, summary,
  assignee, due date, blocker, output link nếu có.
- Phân biệt rõ `không tìm thấy update` với `không có update`.
- Nếu thiếu evidence để kết luận, nói rõ đã kiểm tra phạm vi nào.

Nếu request vừa cần ticket status vừa cần nội dung knowledge:

- Dùng Backlog để trả lời phần ticket status/progress.
- Dùng `knowledge-search` để follow output/doc link và trả lời phần knowledge.
- Không suy diễn knowledge từ ticket summary, category hoặc cluster ticket.

## Verification

Trước khi trả lời cuối hoặc gọi tool write:

- Done Conditions trong template hiện tại có thể kiểm chứng được không?
- Với ticket `Resolved`, các Done Conditions chỉ kiểm được sau merge/dev có
  được giữ là điều kiện còn lại thay vì bị coi là blocker review không? Với
  ticket `Closed`, mọi Done Conditions đã được kiểm chứng chưa?
- Status hiện tại, vai trò implementer/reviewer, và điều kiện còn lại trước
  `Closed` có được diễn giải đúng theo `Vòng Đời Status TRT` không?
- Claim quan trọng có source, issue key, MR/doc link, hoặc được đánh dấu là inference chưa?
- Với workflow parent/child: child payload có `parentIssueId`, category,
  assignee, milestone đã verify chưa; parent status sync hoặc không sync có lý
  do rõ chưa?

## Gotchas

- Chỉ dùng `Evaluation` khi có target, criteria, cases, và recommendation; ticket
  có test chưa đủ để chọn issue type này.
- Đừng đóng `Research` hoặc `Evaluation` chỉ vì đã thảo luận xong. Cần output
  trong Agora doc/MR hoặc link tương đương.
- Khi trả lời Backlog/status trong Mattermost, tránh Markdown table alignment
  syntax như `---:` vì Mattermost có thể hiểu `:|` là emoji mặt. Dùng table
  không alignment như `|---|---|---|`, hoặc dùng bullet list nếu bảng ngắn.
