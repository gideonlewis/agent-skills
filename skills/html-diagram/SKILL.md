---
name: html-diagram
description: Tạo một file HTML độc lập (self-contained) để trực quan hóa kiến trúc và giúp hiểu rõ stack thông qua một sơ đồ SVG chất lượng cao. Dùng khi người dùng muốn một sơ đồ full-screen, muốn output ít văn xuôi (prose), hoặc muốn một HTML artifact chủ yếu để giúp kiến trúc trở nên dễ hiểu ngay lập tức.
---

# HTML Diagram

Xem qua các sơ đồ SVG được dùng trong `references/html-effectiveness/`.

Trong đó có khá nhiều, và một số tập trung vào kiến trúc và các thứ liên quan.

Sau khi xem xong, tạo một file HTML chỉ dùng để trực quan hóa kiến trúc và giúp hiểu stack.

Nó không nên nặng về văn xuôi. Nên đơn giản hóa thành một sơ đồ full-screen và các thứ tương tự.

Xây dựng một sơ đồ chất lượng cao bằng SVG. Dành thời gian lặp lại (iterate) trên sơ đồ nhiều hơn bất cứ thứ gì khác.

Nếu hợp lý, hãy làm cho sơ đồ có tính tương tác và có thể trực quan hóa, animate các chuỗi hành vi khác nhau của hệ thống.

Cũng xem qua `references/architecture-example.html` — một ví dụ hoàn chỉnh cho skill này được làm tốt (full-screen SVG stage, các node có thể click, các flow chip sáng lên và animate đường đi của request).

Luôn bao gồm dark mode: tự viết CSS variables trên `:root` / `html.dark`, một nút toggle theme nhỏ, lưu trạng thái bằng `localStorage`, và một script áp dụng trước khi paint (apply-before-paint) trong `<head>` (mặc định theo `prefers-color-scheme`). Style SVG thông qua các CSS class sử dụng những variables đó — không bao giờ hard-code mã hex bên trong SVG — để sơ đồ luôn theo đúng theme.
