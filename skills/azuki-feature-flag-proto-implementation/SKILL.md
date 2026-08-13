---
name: azuki-feature-flag-proto-implementation
description: |
  Triển khai feature flag phía cred-proto: thêm 1 field bool vào
  GetFeatureFlagsResponse trong repo cred-proto rồi mở PR bằng `gh`. Dùng khi flag
  cần expose ra frontend qua RPC GetFeatureFlags. Merge & publish xong thì chạy tiếp
  skill implement-feature-flag-azuki. Flag chỉ dùng ở backend thì bỏ qua skill này.
argument-hint: "<flag_name> CRES-XXXX"
---

# Feature Flag — cred-proto

Đây là **phần proto** của một feature flag hướng frontend, kết thúc ở bước "PR đã mở".
Phần định nghĩa flag + đấu nối handler nằm ở skill riêng `implement-feature-flag-azuki`,
chạy **sau khi** PR này được merge và publish (workflow `publish-go.yml` sinh ra tag
`vX.Y.Z-go` mà azuki phụ thuộc vào — tag này chỉ tồn tại sau Phase 1).

## Khi nào dùng / bỏ qua

- **Dùng** khi frontend cần đọc flag qua RPC `GetFeatureFlags`.
- **Bỏ qua** nếu flag chỉ dùng ở backend (chỉ code azuki đọc) → đi thẳng tới
  `implement-feature-flag-azuki`; thêm field proto không dùng là lãng phí.
- Không chắc frontend có cần không → hỏi người dùng trước khi sửa proto.

## Tham số

```
azuki-feature-flag-proto-implementation <flag_name> CRES-XXXX
```

- `<flag_name>` — tên flag dạng `snake_case`, ví dụ `enable_console_workflow_history_missing_subject_id_fix`.
- `[CRES-XXXX]` — link ticket Backlog. **Bắt buộc** (dùng cho tiêu đề PR và tên branch).
  Nếu thiếu → dừng và hỏi người dùng.

## Chọn file proto

Module `github.com/Finatext/cred-proto`. Sửa đúng file theo frontend tiêu thụ flag
(nếu không suy ra được, hỏi người dùng):

| Frontend            | File                                            |
| ------------------- | ----------------------------------------------- |
| SPC (app người vay) | `proto/spc/rpc/get_feature_flags.proto`         |
| Console (vận hành)  | `proto/console/rpc/get_feature_flags.proto`     |
| Anmitsu             | `proto/anmitsu/rpc/get_feature_flags.proto`     |
| Kintsuba            | `proto/kintsuba/rpc/v1/get_feature_flags.proto` |

---

## Bước 0 — Preflight: kiểm tra `gh`

Skill cần `gh` (GitHub CLI) để mở PR. Kiểm tra; nếu chưa có/chưa đăng nhập thì dừng và
báo người dùng tự hoàn tất (skill không nhập token thay bạn):

```bash
gh --version || echo "gh chưa cài (brew install gh)"
gh auth status   # nếu fail → chạy: gh auth login
```

## Bước 1 — Tạo branch từ master

Luôn tách branch từ `master` (không từ WIP branch đang dở). Nếu working tree bẩn hoặc
`master` không có ở local, dùng `origin/master` làm base.

```bash
git checkout master && git pull --ff-only
git checkout -b "feat/CRES-XXXX-<flag_name>"
```

## Bước 2 — Thêm field vào proto

Thêm 1 field `bool` vào `GetFeatureFlagsResponse`:

```proto
// EnablePreviousApplicationListSearchWithUrlParams enables searching previous
// application list with URL parameters.
bool enable_previous_application_list_search_with_url_params = 128;
```

Quy tắc:

- **Comment**: dòng đầu là tên PascalCase + mô tả ngắn (khớp style comment sẵn có); tùy chọn thêm URL ticket ở dòng 2.
- **Số field**: lấy số mới lớn hơn field cao nhất hiện có. Không tái dùng số đã `reserved`, không đánh số lại/di chuyển field cũ.
- **Tên field**: `snake_case` phản chiếu tên PascalCase, giống hệt key flag bên azuki để dễ ánh xạ.

> Không chạy `make gen` — việc sinh code (Go/TS/OpenAPI) do CI / release workflow lo.

## Bước 3 — Commit & push

```bash
git add <file>.proto
git commit -m "[CRES-XXXX] GetFeatureFlagsResponse: added <flag_name>"
git push -u origin "feat/CRES-XXXX-<flag_name>"
```

## Bước 4 — Mở PR bằng `gh`

Thêm field mới là thay đổi **tương thích ngược** → nhãn **`release:minor`** (chỉ dùng
`release:major` khi di chuyển/đổi tên/xóa; `release:patch` khi chỉ sửa comment).
Tiêu đề PR **phải chứa** `CRES-XXXX` (để sinh release-note STG).

Body PR theo `.github/pull_request_template.md` — giữ nguyên tiếng Nhật:

```markdown
## 概要

`GetFeatureFlagsResponse` に `enable_xxx` フィールドを追加しました。
（なぜ必要か + チケットリンク）

## 参考リンク

- https://finatexthd.atlassian.net/browse/CRES-XXXXX
```

Tạo PR bằng `gh`:

```bash
gh pr create --repo Finatext/cred-proto \
  --label release:minor \
  --title "[CRES-XXXX] GetFeatureFlagsResponse: added <flag_name>" \
  --body-file <body>
```

**Không tự merge** — PR được review và merge thủ công. Sau merge, `publish-go.yml` sinh
ra tag `vX.Y.Z-go`.

---

## Bàn giao

Sau khi PR merge và tag `-go` publish, ghi lại version cred-proto (vd `v1.51.0`) rồi chạy:

```
/implement-feature-flag-azuki <đúng tên flag> v1.51.0
```

## Checklist

- [ ] Đã parse `<flag_name>` + `CRES-XXXX` (dừng nếu thiếu CRES)
- [ ] `gh` sẵn sàng & đã đăng nhập
- [ ] Branch `feat/CRES-XXXX-<flag_name>` tạo **từ master**
- [ ] Đúng file `get_feature_flags.proto`; field `bool` + comment + số field mới
- [ ] Commit & push lên branch (không chạy `make gen`)
- [ ] PR mở bằng `gh`: nhãn `release:minor` + `CRES-XXXX` trong tiêu đề, body theo template
- [ ] Không tự merge; sau merge + publish → tiếp tục `implement-feature-flag-azuki`
