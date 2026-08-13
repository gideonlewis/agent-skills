---
name: html-plan
description: Tạo một file HTML plan độc lập (self-contained), thực dụng, đơn giản và được tổ chức trực quan rõ ràng. Dùng khi người dùng muốn một trang plan theo phong cách HTML hiệu quả, muốn nội dung bám sát những gì họ đã cung cấp, hoặc muốn chỉnh sửa ngữ pháp mà không biến nó thành một thứ gì đó to tát hơn.
---

# HTML Plan

Xem qua các file trong `references/html-effectiveness/`.

Sau khi xem xong, tạo một file HTML cho plan theo phong cách tương tự.

Giữ mọi thứ thực dụng và đơn giản.

Luôn bao gồm dark mode: tự viết CSS variables trên `:root` / `html.dark`, một nút toggle theme nhỏ, lưu trạng thái bằng `localStorage`, và một script áp dụng trước khi paint (apply-before-paint) trong `<head>` (mặc định theo `prefers-color-scheme`).
