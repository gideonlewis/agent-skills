---
name: build
description: Xây dựng code theo từng lát cắt task nhỏ (incremental), TDD-first. Dùng khi đã có PLAN.md và cần implement từng task theo thứ tự, hoặc khi cần thực thi tự động (hands-off) toàn bộ plan.
---

# Build

Xây dựng task tiếp theo trong plan.

**Phase: BUILD**

## Khi nào dùng

- Đã có `PLAN.md` với các task cụ thể, cần implement từng task một.
- Cần chế độ thực thi tự động (`build auto`) để chạy hết các task mà không cần can thiệp thủ công từng bước.

## Quy trình

Khi được kích hoạt với tên task:

1. Tìm task trong `PLAN.md`
2. Hiểu yêu cầu, ngữ cảnh và dependencies
3. Lên kế hoạch implementation (TDD: viết test trước)
4. Implement theo từng bước nhỏ (incremental)
5. Commit với message rõ ràng
6. Verify bằng test pass

### Chế độ tự động — `build auto`

- Generate plan từ spec
- Thực thi từng task một cách tự động
- Dừng lại khi gặp lỗi hoặc quyết định rủi ro
- Mọi bước đều test-driven

## Anti-patterns

- Viết toàn bộ implementation trước rồi mới viết test (ngược với TDD).
- Gộp nhiều task không liên quan vào một commit, gây khó review/revert.
- Chạy `build auto` mà không dừng lại khi gặp quyết định rủi ro hoặc lỗi không rõ nguyên nhân.

## Red Flags

🚩 Task được đánh dấu hoàn thành nhưng test chưa pass.
🚩 Commit message không mô tả rõ thay đổi, chỉ ghi kiểu "wip" hoặc "fix".
