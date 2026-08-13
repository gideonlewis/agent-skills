---
name: spec
description: Xác định rõ những gì cần xây dựng bằng một specification rõ ràng trước khi viết code. Dùng khi bắt đầu một tính năng/dự án mới, khi yêu cầu còn mơ hồ, hoặc khi cần thống nhất phạm vi (scope) với người dùng trước khi implement.
---

# Spec

Bắt đầu specification-driven development bằng cách ghi nhận yêu cầu một cách rõ ràng.

**Phase: DEFINE**

## Khi nào dùng

- Bắt đầu một tính năng hoặc dự án mới mà yêu cầu chưa rõ ràng.
- Cần thống nhất phạm vi (in-scope / out-of-scope) trước khi lập plan hoặc code.
- Người dùng mô tả ý tưởng ở mức cao, cần cụ thể hóa thành spec có thể hành động được.

## Quy trình

Khi được kích hoạt, giúp người dùng viết một specification có cấu trúc, bao gồm:

1. **Objective** — Đang giải quyết vấn đề gì? Cho ai?
2. **Scope** — Phạm vi trong dự án là gì? Cái gì rõ ràng nằm ngoài phạm vi?
3. **Requirements** — Các tính năng cốt lõi và acceptance criteria
4. **Design** — API, UI, các quyết định kiến trúc
5. **Constraints** — Thời gian, tech stack, quy mô team
6. **Success Criteria** — Làm sao biết đã thành công?

Xuất ra file `SPEC.md` ở project root với đầy đủ 6 phần trên. Chỉ lưu sau khi người dùng xác nhận.

## Anti-patterns

- Viết spec quá chi tiết ở mức implementation (đó là việc của `build`), thay vì tập trung vào *cái gì* và *tại sao*.
- Tự ý quyết định scope thay người dùng — luôn xác nhận trước khi chốt.
- Bỏ qua success criteria — không có tiêu chí thành công thì không biết khi nào xong.

## Red Flags

🚩 Yêu cầu người dùng còn mơ hồ nhưng vẫn tiến thẳng vào code mà không viết spec trước.
🚩 SPEC.md được lưu mà chưa có sự xác nhận rõ ràng từ người dùng.
