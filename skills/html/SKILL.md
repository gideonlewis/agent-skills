---
name: html
description: Tạo một file HTML độc lập (self-contained) cho bất cứ điều gì người dùng mô tả, theo phong cách HTML hiệu quả. Dùng khi người dùng muốn một HTML artifact không cụ thể là sơ đồ hay plan — chẳng hạn như báo cáo, bài giải thích, so sánh, deck, prototype, hoặc bất kỳ thứ gì phù hợp nhất khi truyền tải dưới dạng một file HTML.
---

# HTML

Xem qua các file trong `references/html-effectiveness/`.

Tạo một file HTML cho bất cứ điều gì người dùng mô tả. Sử dụng các references này càng sát càng tốt để khớp về mặt căn chỉnh — style, độ dày đặc (density), và tông giọng.

Luôn bao gồm dark mode: tự viết CSS variables trên `:root` / `html.dark`, một nút toggle theme nhỏ, lưu trạng thái bằng `localStorage`, và một script áp dụng trước khi paint (apply-before-paint) trong `<head>` (mặc định theo `prefers-color-scheme`).
