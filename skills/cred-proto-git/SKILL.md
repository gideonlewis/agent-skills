---
name: cred-proto-git
description: >
  Thao tác git trong repo cred-proto cho công việc proto — kiểm tra worktree,
  tạo branch mới từ master theo quy ước `feature/CRES-#####-<mô tả>`, tạo
  branch follow-up stacked trên nhánh của một PR đang mở (để user thấy riêng
  phần sửa mà không đụng PR gốc), commit đúng file proto với message
  `feat|fix: [CRES-#####] ...`, và push an toàn (không force, không push nhầm
  vào nhánh PR gốc). Dùng khi cần "tạo branch", "tạo nhánh mới", "làm trên
  nhánh của PR #...", "commit và push" trong cred-proto, hoặc khi một workflow
  migrate Console → Core API cần bước chuẩn bị branch hay commit/push. Không lo
  việc viết proto (skill `spcc-migrate-console-rpc-to-core-proto`) hay tạo PR
  và description (skill `spcc-core-api-migration-pr`).
---

# Git cho cred-proto

## Khi Nào Dùng

- Trước khi sửa proto: cần một branch sạch để làm việc.
- Sửa một PR đã mở nhưng muốn thấy riêng phần thay đổi: tạo branch follow-up stacked trên nhánh PR đó.
- Sau khi sửa proto xong: commit và push.

Skill chỉ làm git. Không viết proto, không tạo PR.

## Đầu Vào / Đầu Ra

| Chế độ | Đầu vào | Đầu ra |
|---|---|---|
| `new` | Số ticket `CRES-#####`, mô tả ngắn (kebab-case) | Tên branch, base = `master` |
| `followup` | Số PR gốc | Tên branch, base = nhánh head của PR gốc |
| `commit-push` | Danh sách file đã sửa, message, branch | Commit SHA, branch đã push |

Trả đầu ra cho bước sau (workflow hoặc user) dưới dạng:

```text
branch: feature/CRES-20669-core-api-borrower-note
base: master
mode: new
```

## Quy Trình

### Bước 0 — Kiểm tra trước (mọi chế độ)

```bash
git -C <cred-proto> status --porcelain
git -C <cred-proto> branch --show-current
```

- Có thay đổi chưa commit mà **không phải của lượt làm việc này** → dừng, hỏi user. Không `stash`, không `checkout --`, không `reset`.
- Đang ở `master` ở chế độ `commit-push` → dừng (không commit thẳng lên `master`).

### Chế độ `new` — branch mới từ master

```bash
git fetch origin master
git switch -c feature/CRES-#####-<kebab-mo-ta> origin/master
```

Quy ước tên: `feature/CRES-#####-<kebab-description>`, mô tả theo nhóm việc (ví dụ `feature/CRES-20700-core-api-get-borrower-notes`). Repo còn các biến thể `feat/CRES-#####_...`, `fix/CRES-#####_...`; branch mới dùng dạng trên. Branch trùng tên đã tồn tại → hỏi user dùng lại hay đặt tên khác.

### Chế độ `followup` — branch stacked trên PR đang mở

```bash
gh pr view <n> --json headRefName,baseRefName,state -q '.headRefName+" "+.baseRefName+" "+.state'
git fetch origin <headRefName>
git switch -c <headRefName>-align-console origin/<headRefName>
git branch --unset-upstream
```

- PR không ở trạng thái `OPEN` → hỏi user.
- `--unset-upstream` là bắt buộc: `git switch -c ... origin/<head>` tự đặt upstream về nhánh PR gốc, `git push` trơn sẽ đẩy thẳng vào PR gốc.
- Hậu tố mặc định `-align-console`; user muốn tên khác thì dùng tên đó.
- Đầu ra `base` = `<headRefName>` (PR follow-up sẽ nhắm vào nhánh này, không phải `master`).

### Chế độ `commit-push`

1. Xem lại đúng những gì sẽ commit:

   ```bash
   git status --porcelain
   git diff --stat
   ```

   Chỉ stage file thuộc phạm vi việc đang làm (thường là `proto/**`). **Không** commit `dist/` (đã nằm trong `.gitignore`; CI tự sinh khi release). Thấy file lạ, file có thể chứa secret → dừng hỏi.

2. Stage và commit:

   ```bash
   git add <file ...>          # hoặc git add -A proto nếu chắc chắn chỉ có proto
   git status --porcelain      # kiểm tra lại sau khi add
   git commit -F <message-file>
   ```

   Message:

   ```text
   feat: [CRES-#####] <tóm tắt tiếng Anh hoặc tiếng Nhật>

   <vài dòng giải thích vì sao>

   <dòng attribution theo cấu hình của agent/môi trường, nếu có>
   ```

   Prefix: `feat:` khi thêm RPC/field, `fix:` khi sửa PR cũ cho đúng quy tắc, `docs:` khi chỉ sửa comment, `refactor:` khi đổi cấu trúc không đổi hành vi. File xoá thì dùng `git rm`.

3. Push:

   ```bash
   git push -u origin <branch>
   ```

   Branch follow-up: chạy lại `git branch --unset-upstream` sau khi push nếu muốn chắc không có `git push` trơn nào đẩy nhầm, hoặc giữ upstream mới trỏ về chính branch follow-up (push `-u` đã đặt lại). Kiểm tra bằng `git rev-parse --abbrev-ref @{u}`.

## Anti-patterns

- `git push --force` / `--force-with-lease` lên nhánh của người khác hoặc nhánh PR gốc.
- Sửa thẳng nhánh PR gốc khi user yêu cầu "tạo nhánh mới để thấy thay đổi".
- `git add -A` ở root repo rồi commit mà không đọc lại `git status`.
- Commit `dist/`.
- `git stash` / `git checkout -- .` để "dọn" worktree có thay đổi của user.

## Red Flags

🚩 `git rev-parse --abbrev-ref @{u}` của branch follow-up trả về nhánh PR gốc.
🚩 Commit có file ngoài `proto/**` mà không rõ lý do.
🚩 Đang ở `master` khi chuẩn bị commit.
