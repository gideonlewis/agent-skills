# Xử Lý Sự Cố Khi Tạo/Sửa Skill

## Skill không xuất hiện

```bash
./validate-skills.sh && ./sync.sh && ./status.sh
```

Nếu `./install.sh` đã chọn một tập skill tùy chỉnh trên máy này (kiểm tra
`.local/config.json`, field `selection_mode: "custom"`), `sync.sh` sẽ **chỉ**
đồng bộ đúng tập đó — skill mới sẽ không tự xuất hiện. Chạy
`./install.sh <tên-skill-mới>` hoặc `./install.sh --all` để thêm vào.

## Symlink hỏng

Thường do đổi tên thư mục skill. `sync.sh` tự dọn symlink chết (trỏ tới đường
dẫn không còn tồn tại), chạy lại `./sync.sh` là được.

## `name` không khớp thư mục

Lỗi hay gặp nhất sau khi đổi tên thư mục mà quên sửa frontmatter. Ví dụ đổi
`skills/calendar-skill/` thành `skills/google-calendar/` nhưng quên sửa
`name: calendar-skill` thành `name: google-calendar` trong `SKILL.md`.
`./validate-skills.sh` bắt được lỗi này ngay.

## Lỗi YAML frontmatter

Thường do `description` nhiều dòng thiếu block scalar. Dùng `>` (gộp các dòng
thành một đoạn) hoặc `|` (giữ nguyên xuống dòng):

```yaml
description: >
  Dòng một
  dòng hai sẽ được gộp thành một đoạn.
```

```yaml
description: |
  Dòng một sẽ giữ nguyên xuống dòng.
  Dòng hai cũng vậy.
```

## Có thư mục thật che mất symlink

Nếu `~/.claude/skills/<tên>` là một thư mục thật (không phải symlink) thay vì
trỏ về repo, `install.sh`/`sync.sh` sẽ **không tự xóa** — chúng cảnh báo và bỏ
qua để tránh mất dữ liệu chỉ tồn tại trên máy đó. Kiểm tra nội dung thư mục đó
trước khi quyết định xóa thủ công hay đổi tên skill trong repo để tránh trùng.

## Description viết đúng nhưng skill vẫn không kích hoạt

- Kiểm tra `description` đã nêu **tình huống cụ thể** chưa, không chỉ nêu chức
  năng (xem phần "Viết description cho đúng" trong `SKILL.md`).
- Với yêu cầu đơn giản, một bước (ví dụ "đọc file X giúp tôi"), agent có thể
  tự xử lý bằng tool cơ bản mà không cần kích hoạt skill nào — đây là hành vi
  bình thường, không phải lỗi description.
- Nếu skill hay bị bỏ sót dù tình huống rõ ràng, thử viết description "chủ
  động thúc" hơn: liệt kê thêm cách người dùng có thể diễn đạt mà không gọi
  thẳng tên skill.
