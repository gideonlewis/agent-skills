---
name: implement-feature-flag-azuki
description: |
  Triển khai feature flag phía azuki — định nghĩa flag dưới internal/lib/feature/flag
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

| Loại               | Dấu hiệu                                                                                     | Các bước                                         |
| ------------------ | -------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| **Hướng frontend** | Frontend đọc flag qua `GetFeatureFlags`; Phase 1 (cred-proto) đã chạy; có version cred-proto | 1 → 2 → 3 → **4a** → 5 → 6                       |
| **Chỉ backend**    | Yêu cầu nói rõ flag chỉ dùng ở backend                                                       | 1 → 3 → **4b** → 5 → 6 (bỏ bump proto & handler) |

## Đường dẫn azuki

- Định nghĩa flag: `internal/lib/feature/flag/*.go` (mỗi domain 1 file, vd `console.go`)
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
git checkout -b "feat/CRES-XXXX-<flag_name>"
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

Thêm flag vào file domain tương ứng dưới `internal/lib/feature/flag/`, trường hợp không có file nào phù hợp → tạo file mới. Dùng `feature.RegisterFlagSchema[bool]` . Xem skill `use-feature-flag` để biết cách đặt tên, override, sunset date, code dễ xóa.
Ex:

```go
// EnablePreviousApplicationListSearchWithUrlParams enables searching previous
// application list with URL parameters.
var EnablePreviousApplicationListSearchWithUrlParams = feature.RegisterFlagSchema[bool](
	"enable_previous_application_list_search_with_url_params",
	feature.WithDescription("Enables searching the previous application list with URL parameters."),
	feature.WithMaintainedBy("QuanHuynh in Fushigidane"),
	feature.WithTicketURL("https://teq-dev.backlog.com/view/CRES-XXXX"),
	feature.WithAddedOn(value.NewDate(2026, 7, 15)),  // ngày định nghĩa flag trong code
	feature.WithSunsetOn(value.NewDate(2026, 8, 5)),  // ~3 tuần sau khi định nghĩa
	feature.WithDefault(false),
	feature.WithDefault(true).ForEnv(value.EnvLocal, value.EnvTest, value.EnvDevelopment).ForLicensee(value.LicenseeIDSPC),
)
```

Quy ước (xem `use-feature-flag` để hiểu lý do):

- Tên biến `PascalCase`; schema key `snake_case`. Với flag frontend, schema key **phải trùng tên field proto**.
- Prefix `Enable*` / `Disable*`.
- **Bắt buộc có sunset date** — flag là tạm thời, sẽ bị xóa.
- Base `WithDefault(false)`, rollout bằng `WithDefault(true).ForEnv(...).ForLicensee(...)`.
  Chỉ dùng hằng `LicenseeID` từ `internal/lib/value/org_id.go`. **Không dùng `LicenseeIDManju`.**

## Bước 4 — Đấu nối

### 4a. Frontend-facing: trả về từ handler

Trong `get_feature_flags/handler.go` tương ứng, đọc flag bằng `query` sẵn có và thêm vào
response. Theo pattern xung quanh — khi lỗi thì **log và coi như tắt** (không return error):

```go
// ...các field sẵn có...
enablePreviousApplicationListSearchWithUrlParams, err := feature.Flag(ctx, flag.EnablePreviousApplicationListSearchWithUrlParams, query)
if err != nil {
	log.Error("get enable_previous_application_list_search_with_url_params feature flag failed", logger.ErrorAttr(err))
}
```

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

## Bước 5 — Lint, format, build

Chạy trên các package đã đụng tới, **trước khi** commit:

```bash
./custom-gcl run --fix --timeout 30m --config ./.golangci.yml \
  ./internal/lib/feature/flag/... \
  ./internal/presentation/spc_public_api_presentation/...
go build ./...
```

## Bước 6 — Commit, push & mở PR

```bash
git add -A
git commit -m "[CRES-XXXX] GetFeatureFlags: added <flag_name>"
git push -u origin "feat/CRES-XXXX-<flag_name>"
```

Tiêu đề PR **phải chứa** `CRES-XXXX`.

Body PR — 1 câu mô tả thay đổi rồi tới link (giữ mục `参考リンク` tiếng Nhật):

```markdown
Add `flag_name_xxxx` to GetFeatureFlagsResponse
so the console frontend can toggle the workflow-history subject-id fix.

## 参考リンク

- https://finatexthd.atlassian.net/browse/CRES-XXXXX
```

Xác nhận với người dùng rồi tạo:

```bash
gh pr create --repo Finatext/azuki \
  --label release:minor \
  --title "[CRES-XXXX] GetFeatureFlags: added <flag_name>" \
  --body-file <body>
```

**Không tự merge** — PR được review và merge thủ công.

---

## Checklist

**Frontend-facing** (Phase 2, sau khi cred-proto merged)

- [ ] `go.mod` bump lên tag `-go` đã release (Bước 2)
- [ ] Flag định nghĩa trong `internal/lib/feature/flag/*.go`, schema key == tên field proto, có sunset date (Bước 3)
- [ ] Handler trả về giá trị, pattern log-on-error, đúng tên field Go generated (Bước 4a)
- [ ] Lint/format/build pass (Bước 5)
- [ ] Commit, push, PR `release:minor` + `CRES-XXXX` trong tiêu đề (Bước 6)

**Backend-only** (độc lập)

- [ ] Flag định nghĩa trong `internal/lib/feature/flag/*.go` có sunset date (Bước 3)
- [ ] Nhánh `feature.Flag()` viết dễ xóa nơi có hành vi (Bước 4b)
- [ ] Không đụng proto / handler / go.mod-proto
- [ ] Lint/format/build pass (Bước 5)
- [ ] Commit, push, PR (Bước 6)
