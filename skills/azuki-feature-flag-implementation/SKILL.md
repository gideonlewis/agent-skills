---
name: azuki-feature-flag-implementation
description: |
  Triển khai feature flag phía azuki repo — định nghĩa flag dưới internal/lib/feature/flag
  rồi đấu nối vào handler get_feature_flags (hướng frontend) hoặc một nhánh usecase
  (chỉ backend). Với flag hướng frontend, chạy SAU KHI PR của
  implement-feature-flag-cred-proto đã merge và tag vX.Y.Z-go đã publish, truyền kèm
  version đó. Với flag chỉ dùng ở backend, chạy độc lập (không proto, không version).
argument-hint: "<flag_name / mục đích> [cred-proto version, vd v1.51.0]"
---

# Feature Flag — azuki

Đây là **phần azuki** của feature flag. Best practices chung (đặt tên, thứ tự override,
code dễ xóa, test) tham chiếu skill `use-feature-flag` — skill này tập trung vào **đấu nối**.

## Trước tiên: hướng frontend hay chỉ backend?

Quyết định dựa trên arguments. Nếu có version cred-proto → hướng frontend, cần expose flag ra RPC GetFeatureFlags. Nếu không có version → chỉ backend, không expose ra RPC.

| Loại               | Dấu hiệu                                                                                     | Các bước                                     |
| ------------------ | -------------------------------------------------------------------------------------------- | -------------------------------------------- |
| **Hướng frontend** | Frontend đọc flag qua `GetFeatureFlags`; Phase 1 (cred-proto) đã chạy; có version cred-proto | 1 → 2 → 3 → **4a** → 5                       |
| **Chỉ backend**    | Yêu cầu nói rõ flag chỉ dùng ở backend                                                       | 1 → 3 → **4b** → 5 (bỏ bump proto & handler) |

## Đường dẫn azuki

- Định nghĩa flag: `internal/lib/feature/flag/*.go`
- Handler: `internal/presentation/{spc_public,console_api,anmitsu_public,kintsuba_public}_api_presentation/internal/get_feature_flags/handler.go`

---

## Bước 0 — Preflight: kiểm tra `gh`

Cần `gh` để mở PR. Kiểm tra; nếu chưa có/chưa đăng nhập thì dừng và báo người dùng tự
hoàn tất (skill không nhập token thay bạn):

```bash
gh --version || echo "gh chưa cài (brew install gh)"
gh auth status   # nếu fail → chạy: gh auth login
```

## Bước 1 — Parse tham số & tạo branch từ master

- `flag_name` (bắt buộc) và `cred-proto version` (bắt buộc nếu hướng frontend, vd `v1.62.0-go`).
- `CRES-XXXX` (ticket Backlog) dùng cho tên branch & PR. Nếu thiếu → **hỏi** trước khi tạo branch/PR.
- Luôn tách branch từ `master` (không từ WIP branch). Nếu `master` không có ở local, dùng `origin/master`.

```bash
git fetch origin
git checkout master && git pull --ff-only origin master
git checkout -b "feature/CRES-XXXX-<flag_name>"
```

## Bước 2 — Bump dependency proto (chỉ frontend-facing)

Chỉ cập nhật khi version được cung cấp **mới hơn** version cred-proto hiện tại trong
`go.mod` (tránh downgrade / no-op). Skill **không** query remote để kiểm tra tag tồn tại
— giả định caller đã truyền đúng tag.

```bash
# xem version hiện tại
grep "github.com/Finatext/cred-proto" go.mod
# nếu version truyền vào mới hơn thì cập nhật:
go get github.com/Finatext/cred-proto@v1.62.0-go
go mod tidy
```

> Nếu CI sau đó fail vì tag `-go` chưa thực sự publish → chạy lại bước này khi tag đã có.

## Bước 3 — Định nghĩa flag (LUÔN LUÔN)

Thêm flag vào file domain tương ứng dưới `internal/lib/feature/flag/*.go` (các file có sẵn, dựa vào pattern hiện tại). Dùng `feature.RegisterFlagSchema[bool]` .
Ex:

- `enable_console_workflow_history_missing_subject_id_fix` -> `internal/lib/feature/flag/console.go`
- `enable_borrower_search_by_concatenated_name` -> `internal/lib/feature/flag/borrower.go`
- `enable_employment_verification_on_hold_navigation` -> `internal/lib/feature/flag/employment_verification.go`

Luôn thêm vào cuối file và đủ các thông tin (WithDescription, WithMaintainedBy, WithTicketURL, WithAddedOn, WithSunsetOn, WithDefault), ví dụ:
(Replace `EnablePreviousApplicationListSearchWithUrlParams` bằng `feature name`)

```go
// ..... các flag sẵn có .....
// EnablePreviousApplicationListSearchWithUrlParams enables searching previous
// application list with URL parameters.
var EnablePreviousApplicationListSearchWithUrlParams = feature.RegisterFlagSchema[bool](
	"enable_previous_application_list_search_with_url_params",
	feature.WithDescription("Enables searching the previous application list with URL parameters."),
	feature.WithMaintainedBy("QuanHuynh in Fushigidane"),
	feature.WithTicketURL("https://finatexthd.atlassian.net/browse/CRES-XXXX"),
	feature.WithAddedOn(value.NewDate(2026, 7, 15)),  // ngày định nghĩa flag trong code
	feature.WithSunsetOn(value.NewDate(2026, 8, 5)),  // ~3 tuần sau khi định nghĩa
	feature.WithDefault(false),
	feature.WithDefault(true).ForEnv(value.EnvLocal, value.EnvTest),
)
```

## Bước 4 — Đấu nối

### 4a. Frontend-facing: trả về từ handler

Trong `get_feature_flags/handler.go` tương ứng, đọc flag bằng `query` sẵn có và thêm vào
response. Theo pattern xung quanh — khi lỗi thì **log và coi như tắt** (không return error):

Luôn thêm vào cuối

```go
// ...các field sẵn có...
enablePreviousApplicationListSearchWithUrlParams, err := feature.Flag(ctx, flag.EnablePreviousApplicationListSearchWithUrlParams, query)
if err != nil {
	log.Error("get enable_previous_application_list_search_with_url_params feature flag failed", logger.ErrorAttr(err))
}
return connect.NewResponse(
	&rpc.GetFeatureFlagsResponse{
		/// ...các field sẵn có...
	},
), nil
```

Tương tự với `rpc.GetFeatureFlagsResponse` - thêm field mới (Go generated) vào cuối struct, ví dụ:

```go
return connect.NewResponse(
	&rpc.GetFeatureFlagsResponse{
		// ...các field sẵn có...
		EnablePreviousApplicationListSearchWithUrlParams: enablePreviousApplicationListSearchWithUrlParams,
	},
), nil
```

> Dùng đúng tên field Go **được generate** từ Phase 1 (vd `EnableMvpCreditCard` cho `enable_mvp_credit_card`).

### 4b. Backend-only: rẽ nhánh nơi hành vi diễn ra

Sẽ không thực hiện step 4a

## Bước 5 — Commit, push & mở PR

```bash
git add -A
git commit -m "[CRES-XXXX] GetFeatureFlags: added <flag_name>"
git push -u origin "feat/CRES-XXXX-<flag_name>"
```

Tiêu đề PR **phải chứa** `CRES-XXXX`.

Body PR — mô tả thay đổi rồi tới link (giữ mục `参考リンク` tiếng Nhật):

```markdown
## 概要

- Add `flag_name_xxxx` to GetFeatureFlags
- Define `flag_name_xxxx` in internal/lib/feature/flag/xxxx.go

## 参考リンク

- https://finatexthd.atlassian.net/browse/CRES-XXXXX
```

Tạo PR bằng `gh`:

```bash
gh pr create --repo Finatext/azuki \
  --label release:minor \
  --title "[CRES-XXXX] GetFeatureFlags: added <flag_name>" \
  --body-file <body>
```

**Không tự merge** — PR được review và merge thủ công.

---~

## Checklist

**Frontend-facing**

- [ ] `go.mod` bump lên tag `-go` đã release (Bước 2)
- [ ] Flag định nghĩa trong `internal/lib/feature/flag/*.go`, schema key == tên field proto, có sunset date (Bước 3)
- [ ] Handler trả về giá trị, pattern log-on-error, đúng tên field Go generated (Bước 4a)
- [ ] Lint/format/build pass (Bước 5)
- [ ] Commit, push, PR `CRES-XXXX` trong tiêu đề (Bước 5)

**Backend-only**

- [ ] Flag định nghĩa trong `internal/lib/feature/flag/*.go` có sunset date (Bước 3)
- [ ] Nhánh `feature.Flag()` viết dễ xóa nơi có hành vi (Bước 4b)
- [ ] Không đụng proto / handler / go.mod-proto
- [ ] Commit, push, PR (Bước 5)
