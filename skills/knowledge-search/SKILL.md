---
name: knowledge-search
description: >
  Dùng skill này để tìm, tóm tắt, giải thích, hoặc kiểm chứng vision,
  architecture, thành viên team, source-of-truth record, decision, research,
  runbook, policy, và design rationale của AI Platform. Không dùng cho tiến độ
  ticket, delivery status, trạng thái MR, pipeline, hoặc deploy evidence.
version: 0.3.1
author: TEQ AI Platform
license: Internal
metadata:
  hermes:
    tags: [ai-platform, knowledge-search, vision, design-docs, decisions]
---

# Knowledge Search

## Khi Nào Dùng

- Tìm hoặc tóm tắt vision, architecture, decision, research, policy, runbook.
- Trả lời câu hỏi về team/member/core members hoặc source of truth nội bộ.
- Giải thích lý do thiết kế của system hoặc workflow.
- Kiểm chứng claim nội bộ bằng source.
- Đối chiếu tài liệu dài hạn với trao đổi gần đây.

Không dùng skill này cho:

- Ticket status, assignee, blocker, deadline, delivery progress → ticket skill.
- MR, diff, pipeline, deploy evidence → GitLab evidence skill.
- Write action trên source system.

## Workflow

1. Phân loại intent: tìm source, tóm tắt, giải thích, hoặc kiểm chứng.
2. Đọc `references/source-map.md`; chọn source nhỏ nhất đủ trả lời.
3. Có link/file → đọc trực tiếp.
4. Có canonical path → đọc trực tiếp; không search lại.
5. Chưa biết file → search trong đúng source scope, rồi đọc source gốc.
6. Chỉ thêm source thứ hai khi source đầu thiếu hoặc user yêu cầu đối chiếu.
7. Trả lời kết luận trước; ghi source thực sự đã đọc.

Canonical source lỗi → báo file/project cụ thể, dừng. Không fallback sang
keyword search.

## Nguyên Tắc

- Search/snippet → chỉ định vị; kết luận từ source gốc.
- Không quét nhiều repo, folder hoặc system.
- Không kể quá trình search.
- Mặc định: kết luận ngắn + vài luận điểm có giá trị.
- Không tự thêm roadmap, status report hoặc action plan.
- Gắn link/path source; đánh dấu inference.

## Verification

- Đã đọc source gốc, không chỉ snippet.
- Tuân thủ canonical source rule và không mở rộng thừa.
- Claim có source hoặc nhãn inference.

## Ví Dụ Trigger

- "Team AI Platform đang định hướng phát triển tổng quát như thế nào?"
- "Tìm design doc về gateway authentication và tóm tắt quyết định chính."
- "Vì sao internal-hub-mcp dùng flow này?"
