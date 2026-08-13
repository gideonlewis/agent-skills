---
name: ai-platform-gitlab
description: >
  Chỉ dùng skill chuyển tiếp này cho implementation evidence trên AI Platform
  GitLab tại git.teqnological.asia: repository, merge request, diff, commit,
  pipeline, job, release, hoặc link GitLab cụ thể. Dùng skill knowledge-search
  cho vision, architecture, design doc, decision, research, runbook và các câu
  hỏi tri thức khác.
version: 0.5.5
author: TEQ AI Platform
license: Internal
metadata:
  hermes:
    tags:
      [ai-platform, gitlab, merge-requests, pipelines, implementation-evidence]
---

# AI Platform GitLab Evidence

Skill chuyển tiếp này chỉ xử lý implementation evidence trên GitLab. Knowledge
đã được chuyển sang use-case skill `knowledge-search`.

## Khi Nào Dùng

Dùng khi user cần:

- Kiểm tra repository, branch, commit, MR, diff, pipeline, job hoặc release.
- Xác định implementation status hoặc technical evidence.
- Review một GitLab link cụ thể trong group `ai-platform`.
- Lấy evidence GitLab để cập nhật ticket hoặc status report.

Không dùng cho vision, strategy, architecture, design docs, ADR, research,
runbook hoặc câu hỏi "vì sao". Các request đó dùng `knowledge-search`.

## Scope

- GitLab host: `git.teqnological.asia`
- Group chính: `ai-platform`
- Nếu user đưa link hoặc repo cụ thể, dùng đúng scope đó.
- Không quét nhiều repo để dò implementation. Nếu chưa rõ repo, dùng context
  user cung cấp hoặc knowledge source đã xác định repo liên quan.

## Workflow

1. Xác định evidence cần kiểm tra: MR, diff, commit, pipeline, job hay release.
2. Nếu có GitLab link, đọc đúng link trước.
3. Query repo/resource đúng scope và lấy trạng thái live.
4. Tóm tắt thay đổi, trạng thái và rủi ro PM cần biết.
5. Gắn direct link cho evidence và đánh dấu inference nếu có.

## MR, Diff, Pipeline

- Nêu repo, MR link, source/target branch, trạng thái MR, draft/mergeability và
  pipeline status nếu có.
- Tóm tắt diff theo khu vực thay đổi và rủi ro, không kể lại từng file.
- Phân biệt `merged`, `open`, `closed`, `draft`, `pipeline failed` và
  `chưa kiểm tra được pipeline`.
- Không nói "đã deploy" chỉ vì MR đã merge; cần deploy evidence riêng.

## Evidence Cho Ticket/Status

- Ưu tiên direct links: MR, commit, pipeline, job, release hoặc deploy evidence.
- Comment/status update chỉ cần status change và evidence links.
- Không suy ra status Backlog chỉ từ trạng thái MR, merge, pipeline hoặc deploy.
  Với TRT, `Resolved` là developer done phần implementation và handoff để
  reviewer review; Done Conditions chỉ kiểm được sau merge có thể còn mở. Khi
  mọi Done Conditions đã đạt, ticket creator quyết định close sang `Closed`.
  Reviewer chỉ cung cấp review result và có thể khác ticket creator. Dùng skill
  `backlog` để diễn giải lifecycle trước khi đề xuất status ticket.
- Deploy evidence không phải evidence mặc định để ticket được chuyển `Resolved`.
  Nó là closure evidence khi ticket hoặc release flow yêu cầu deployment.
- Với feature, bug, hoặc thay đổi runtime, verification trên dev là closure
  evidence khi ticket hoặc release flow yêu cầu rõ. Nếu không có yêu cầu đó,
  thiếu evidence này không tự chặn ticket creator close. Production không là
  điều kiện close ticket gốc; vấn đề production được theo dõi bằng ticket mới.
- Nếu evidence thiếu, nói rõ thiếu phần nào thay vì suy diễn.

## Tooling

- Ưu tiên GitLab MCP tool nếu runtime expose.
- Nếu dùng CLI fallback:
  `glab api --hostname git.teqnological.asia ...`
- Không dựa vào default host của `glab`.

## Verification

- Resource và repo có đúng scope user hỏi không?
- Trạng thái realtime đã được query live chưa?
- Có phân biệt merge với deploy chưa?
- Claim quan trọng có direct link hoặc được ghi rõ là inference chưa?
- Nếu request thực chất là knowledge, đã chuyển sang `knowledge-search` chưa?
