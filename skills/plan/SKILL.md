---
name: plan
description: Chia nhỏ một specification thành danh sách task nhỏ, nguyên tử (atomic) và có thứ tự ưu tiên. Dùng sau khi đã có SPEC.md, hoặc khi cần chia một yêu cầu lớn thành các bước có thể thực hiện và review độc lập.
---

# Plan

Tạo một plan có thể hành động được từ một specification.

**Phase: PLAN**

## Khi nào dùng

- Đã có `SPEC.md` (hoặc yêu cầu tương đương) và cần chia thành các task cụ thể.
- Yêu cầu quá lớn để implement trong một lần, cần chia nhỏ để dễ review và ship.

## Quy trình

Khi được kích hoạt:

1. Đọc `SPEC.md` nếu có
2. Chia thành các task nguyên tử (1-4 giờ mỗi task)
3. Xác định dependencies và thứ tự thực hiện
4. Ưu tiên hóa triệt để (MVP tối thiểu là gì?)
5. Xuất ra `PLAN.md` với chuỗi task theo thứ tự

Mỗi task cần đảm bảo:

- Hoàn thành được bởi một người
- Review được độc lập
- Có thể ship được
- Được verify bằng test

## Anti-patterns

- Task quá lớn (>4 giờ) hoặc quá nhỏ tới mức vụn vặt, không mang lại giá trị review độc lập.
- Bỏ qua việc xác định dependency giữa các task, dẫn tới thứ tự thực hiện sai.
- Nhồi nhét toàn bộ scope vào MVP thay vì ưu tiên ruthlessly.

## Red Flags

🚩 PLAN.md không có thứ tự ưu tiên rõ ràng — mọi task đều "quan trọng như nhau".
🚩 Một task không thể review độc lập vì phụ thuộc chặt vào nhiều task khác chưa xong.
