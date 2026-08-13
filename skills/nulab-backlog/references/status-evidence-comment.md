# Status/Evidence Comment

Reference này dùng khi update Backlog ticket dựa trên Mattermost thread, MR,
chat, log, hoặc deploy note. Mục tiêu của comment là audit trail ngắn, không
phải bản tóm tắt hội thoại.

## Quy Ước Status TRT

- `Resolved` là developer done phần implementation và handoff artifact để
  reviewer review; không đồng nghĩa ticket đã hoàn tất end-to-end.
- `Closed` là ticket creator chuyển status sau khi đối chiếu mọi Done Conditions
  đã đạt và kết quả review hiện có. Thao tác close là quyết định của ticket
  creator, không cần evidence approval riêng.
- Nếu reviewer cần sửa, chuyển `Resolved -> In Progress`; không để ticket
  `Resolved` khi implementer vẫn có action bắt buộc.

## Rule

- Chỉ đổi status khi user hoặc source nói rõ trạng thái mới.
- Comment cần ghi status change, evidence trực tiếp, owner của next action và
  Done Conditions còn mở trước `Closed` khi ticket đang `Resolved`.
- Evidence trực tiếp thường là Mattermost thread, MR/PR, deploy log, release
  note, hoặc comment xác nhận từ owner.
- Không liệt kê diễn biến chat như ai tag ai, ai nhờ ai, hoặc các câu trao đổi
  trung gian nếu chúng không phải evidence.
- Không ghi thiếu deploy dev/pipeline như missing evidence cho chuyển
  `In Progress -> Resolved`, trừ khi ticket hoặc policy merge yêu cầu nó trước
  review.
- Done Condition chỉ kiểm được sau merge, như deploy dev/verification trên dev,
  được phép còn chưa tick ở `Resolved`; tất cả Done Conditions mới là điều kiện
  để ticket creator chuyển `Closed`.
- Với feature, bug, hoặc thay đổi có runtime impact, comment `Resolved -> Closed`
  cần evidence verification trên dev khi ticket hoặc release flow yêu cầu rõ.
  Nếu không có yêu cầu đó, thiếu evidence này không tự chặn ticket creator close.
  Production không là điều kiện close ticket gốc; lỗi production là ticket mới.
- Reviewer chỉ cung cấp review result hoặc yêu cầu sửa. Nếu reviewer khác ticket
  creator, không ghi reviewer là người close ticket.
- Nếu evidence thiếu, hỏi lại hoặc ghi rõ phần chưa xác nhận; không tự suy diễn.

## Format: Handoff For Review

```md
Status: In Progress -> Resolved.

Handoff for review:
- MR/output: <url>
- Completed: <scope ngắn>
- Review/self-check: <test hoặc cách kiểm tra>

Remaining Done Conditions before Closed:
- <merge, deploy dev, hoặc verification nếu ticket yêu cầu>
```

## Format: Ticket Creator Close

```md
Status: Resolved -> Closed.

Verified Done Conditions:
- <output/MR đã merge hoặc artifact đã được kiểm tra>
- <deploy dev và verification, nếu ticket yêu cầu>
- <các Done Conditions còn lại của ticket>
```

## Format: Review Cần Sửa

```md
Status: Resolved -> In Progress.

Review feedback:
- <MR discussion hoặc review link>

Next action:
- @implementer <việc cần sửa>
```

## Ví Dụ Tốt

```md
Status: In Progress -> Resolved.

Handoff for review:
- MR/output: https://git.teqnological.asia/ai-platform/mcp/internal-hub-mcp/-/merge_requests/12
- Completed: triển khai API theo TRT-123.
- Review/self-check: unit tests liên quan đã chạy trong MR.

Remaining Done Conditions before Closed:
- Merge MR.
- Deploy dev + smoke test nếu release flow của TRT-123 yêu cầu.
```

## Ví Dụ Không Nên Viết

```md
Resolved và đã deploy lên dev.

Evidence từ Mattermost thread:
- @baonguyen yêu cầu @phongdang gửi PR để test trên dev gateway.
- @phongdang gửi PR.
- Nội dung thread xác nhận work đã được resolve/deploy lên dev.
```

Ví dụ này vừa tóm tắt diễn biến chat thay vì ghi direct evidence, vừa nâng một
yêu cầu/gửi PR để test thành `Dev deploy` đã được xác nhận. Nếu không có deploy
log, release evidence hoặc xác nhận trực tiếp từ owner, không claim đã deploy.
