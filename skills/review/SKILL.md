---
name: review
description: Audit chất lượng code trước khi merge — kiểm tra correctness, clarity, testing, performance, security, style. Dùng khi cần review code trước khi merge/ship, hoặc khi người dùng yêu cầu đánh giá chất lượng một đoạn code/diff.
---

# Review

Audit chất lượng code trước khi merge.

**Phase: REVIEW**

## Khi nào dùng

- Cần review code trước khi merge hoặc ship.
- Người dùng yêu cầu đánh giá chất lượng một đoạn code, diff, hoặc pull request.

> Với review MR/PR trên AI Platform GitLab hoặc diff làm việc hiện tại, tham khảo thêm skill `code-review`.

## Quy trình

Khi được kích hoạt:

1. **Check correctness** — Code có làm đúng như nó tuyên bố?
2. **Check clarity** — Code có dễ hiểu không?
3. **Check testing** — Edge case đã được cover chưa?
4. **Check performance** — Có điểm kém hiệu năng rõ ràng nào không?
5. **Check security** — Có lỗ hổng bảo mật nào không?
6. **Check style** — Có khớp với convention của repo không?

Xuất ra review gồm:

- ✓ Điểm tốt
- 🐛 Bug tìm thấy
- ⚡ Vấn đề hiệu năng
- 🔒 Vấn đề bảo mật
- 💡 Gợi ý cải thiện clarity

## Anti-patterns

- Chỉ liệt kê vấn đề stylistic mà bỏ qua bug/security nghiêm trọng hơn.
- Đưa ra nhận xét mơ hồ ("nên refactor lại") mà không chỉ rõ vị trí và cách sửa.
- Review dựa trên giả định thay vì đọc kỹ code thực tế.

## Red Flags

🚩 Review không có finding nào dù diff lớn và phức tạp — có thể đã đọc lướt.
🚩 Bug nghiêm trọng bị xếp chung mức độ với góp ý style nhỏ nhặt.
