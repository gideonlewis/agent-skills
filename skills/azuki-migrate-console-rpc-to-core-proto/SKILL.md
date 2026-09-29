---
name: azuki-migrate-console-rpc-to-core-proto
description: Trong repo cred-proto, phân tích 1 Console RPC (mỗi PR chỉ 1 RPC — xem "Đầu Vào") — xác định loại 1対1レビュー / 業務操作 / 分割 / 個別設計, entity chính, RPC đã có bên Core chưa — rồi viết proto Core RPC theo đúng mẫu chunk_1 JP cung cấp (CreateRole, GetBorrowerExpatriations) — dùng lại entity/filter Console, giữ nguyên field (kể cả field deprecated), type, validate, chỉ bỏ entity phụ trong response và đánh số lại thay cho reserved — KHÔNG đăng ký vào core_service.proto (việc này dồn vào 1 PR batch riêng, xem "Đăng Ký core_service.proto") — chạy buf lint/format/gen, so field với Console và xuất migration report cho bước tạo PR. Dùng khi được yêu cầu migrate Console API sang Core API ở tầng proto, "viết proto Core cho RPC sau", sửa proto của một PR migrate cũ cho khớp quy tắc hiện tại, hoặc khi Console RPC trùng tên với Core RPC đã có cho minazuki. Không làm git (skill cred-proto-git), không tạo PR (skill azuki-core-api-migration-pr), không implement handler azuki, không switch azuki-app, không feature flag.
---

# Migrate Console RPC sang proto Core API

## Khi Nào Dùng

Có danh sách Console RPC cần migrate sang Core, hoặc một PR migrate cũ cần sửa proto cho đúng quy tắc hiện tại. Skill lo phần **phân tích + viết proto + verify**, rồi xuất **migration report** để bước tạo PR dùng.

Không làm: tạo branch/commit/push (skill `cred-proto-git`), tạo PR và description (skill `azuki-core-api-migration-pr`), cả chuỗi end-to-end (skill `azuki-core-api-proto-migration-workflow`), handler azuki, switch azuki-app, feature flag, rollout.

Core RPC migrate là **bản sao cấu trúc của Console**: cùng field, số field, type, validate. Chỉ khác ở những điểm trong bảng dưới.

## Quyết định đã chốt

Đây là nguồn sự thật. Reference và code có sẵn trong repo mà mâu thuẫn với bảng này thì bảng này thắng.

| # | Quyết định | Nguồn |
|---|---|---|
| 1 | **Mẫu duy nhất là chunk_1**: `core/rpc/get_borrower_expatriations.proto` (Query), `core/rpc/create_role.proto` (Write). Các Core RPC khác được dựng cho minazuki, Platform Console, macaron-message-dispatcher, không phải migrate từ Console → không làm mẫu | chunk_1 do JP (haruki.nazawa) làm, 2026-07-30 |
| 2 | **Dùng lại entity, enum, filter của Console** (import `console/entity/*`, `console/rpc/filter.proto`). Giữ cả tên field Console, kể cả khi không theo convention (ví dụ `borrower_related_party_filter`) | chunk_1; user chốt 2026-09-25 |
| 3 | **Cấu trúc, type, validate giữ như Console.** `field_mask`, `bitemporal_query`, `effective` luôn giữ khi Console có (kể cả dead field), không thêm khi Console không có. Update RPC giữ đúng shape Console (field_mask + cả entity + effective), không tách payload `UpdateXxx` | Misato Kano, thread review PR proto 2026-09 |
| 4 | **Validate bổ sung được phép duy nhất**: `string.uuid` cho field ID và `enum.defined_only` cho enum mà Console bị sót, có phân loại field và kiểm chứng FE. Không bớt rule nào của Console | Le, Yuya Sakano, Misato Kano, Kaz Togo, Mattermost 2026-09-25 |
| 5 | **Ngoài phạm vi**: idempotency key (field, option, comment); refactor BitemporalQuery; chuẩn hoá FieldMask | user 2026-09-24; Mattermost 2026-09-25 |
| 6 | **Core RPC trùng tên đã có sẵn (không phải chunk_1)**: RPC đang chạy cho minazuki (`GetDocuments`) → giữ entity Core, chỉ **thêm** field Console cần, field required bên Console thành `optional`. RPC có proto nhưng chưa ship (`GetContracts`, `GetContractApplications`, rpc comment-out) → dừng hỏi chọn hướng. Quy trình: `references/existing-core-rpcs.md` | hirose.hikaru, Mattermost 2026-09-25 |
| 7 | **Style**: comment tiếng Nhật; request Query có block JSON mẫu trong comment; không tự gắn `PUBLIC` | quy ước repo; PR docs của Misato 2026-08-25 |
| 8 | **RPC trả nhiều entity** (`分割`, `分割レビュー`, hoặc nhãn `1対1レビュー` mà response nhiều entity): vẫn migrate, response **chỉ giữ entity chính**; entity phụ (side-load) bỏ, không phụ thuộc deprecated hay không, đánh số lại theo quyết định #9. Tách entity phụ thành RPC nào là việc của RPC khác, không chặn RPC này. Request/filter giữ như Console | user chốt 2026-09-25 |
| 9 | **Đánh số lại, không dùng `reserved`**: field bị bỏ (entity phụ trong response) thì xoá hẳn và đánh số lại liên tục các field sau, giữ thứ tự Console. Field không bị bỏ giữ số Console. Không áp dụng cho Hướng A (Core RPC đang chạy, chỉ thêm field) | Misato Kano ("フィールド番号の振り直しはやってもいい"), chốt trong discuss 2026-09-25 |
| 10 | **Field `deprecated = true` (không phải entity) giữ nguyên như Console**, kể cả option `[deprecated = true]`. Dọn field deprecated không thuộc phạm vi đợt migrate. Chỉ bỏ entity (side-load) deprecated, theo #8 | user chốt 2026-09-25 |

Chi tiết từng quyết định: xem bảng Reference cuối file.

## Đầu Vào / Đầu Ra

**Đầu vào:**

- Đường dẫn repo `cred-proto`, đang đứng trên branch làm việc (không phải `master`). Chưa có branch → dùng skill `cred-proto-git` trước, hoặc báo user.
- **1 Console RPC**, có hoặc không kèm loại — mỗi PR proto giờ chỉ chứa 1 RPC (để review/merge không đụng nhau ở `core_service.proto`; xem "Đăng Ký `core_service.proto`" cuối file):

  ```text
  CreateAnnouncement | 業務操作
  ```

  User đưa nhiều RPC cùng lúc → xử lý tuần tự, **mỗi RPC một branch/report/PR riêng** (gọi lại skill này cho từng RPC), không gộp chung.
- (Chế độ follow-up) số PR gốc cần sửa. Đọc PR gốc và review comment của nó: `gh pr view <n> --json title,body,files`, `gh api repos/Finatext/cred-proto/pulls/<n>/comments`.
- (Tuỳ chọn) số ticket `CRES-#####` — không bắt buộc cho skill này, ghi vào report nếu có.

Không tự mở rộng phạm vi theo domain hay theo bảng mapping.

**Đầu ra:**

- File proto đã sửa trong worktree (chưa commit).
- **Migration report** (tiếng Anh, markdown) ghi ra file ngoài repo, đường dẫn trả về cho bước sau. Format bắt buộc: [references/migration-report.md](references/migration-report.md). Skill tạo PR dựng description từ report này.

## Xác Định Loại RPC

Bước sau ghi đè bước trước.

1. **User ghi loại** thì dùng loại đó.
2. **Suy từ tên** khi user không ghi:

   | Tiền tố | Loại |
   |---|---|
   | `Get*` | `1対1レビュー` |
   | `Create*`, `Update*`, `Delete*`, `Submit*`, `Upsert*`, `Withdraw*`, `Transition*`, `Assign*`, `Register*`, `Send*`, `Make*`, `Unlink*`, `Manual*` | `業務操作` |
   | `Export*`, `Generate*`, `Count*`, `Parse*`, `IssueURL*`, `IssueUploadURL*`, `ValidateAndProcess*` | `個別設計` → từ chối |

   `分割` (`GetBorrowers`, `GetContracts`, `GetContractApplications`) và `分割レビュー` (`GetBorrowerDeduplications`, `GetBorrowerIdentityVerifications`, `GetBorrowerProvidedDocuments`, `GetEmploymentVerificationRequests`, `GetLendingSummary`, `GetTransactions`) **vẫn làm** theo quyết định #8.

3. **Đếm entity trong response Console (bắt buộc).** Nhãn sheet không đủ tin (`design-decisions.md §1`). Mở `proto/console/rpc/<name>.proto`, đếm entity type trong response (bỏ qua `pagination`):
   - Đúng 1 → làm bình thường.
   - Từ 2 trở lên, hoặc có `map<string, SomeEntity>` → vẫn làm, giữ entity chính (`design-decisions.md §2`), xoá các field side-load (không `reserved`, đánh số lại các field sau), ghi trong report. Không xác định được entity chính → dừng hỏi.

   Nhãn sheet sai (ghi `1対1レビュー` mà nhiều entity) → ghi vào `Points to confirm` của report.

## Nguyên Tắc Làm Việc

**Gặp điểm lấn cấn thì DỪNG, liệt kê để user confirm, không suy luận rồi chạy tiếp.** Thà dừng với 2 RPC đã xong và 3 câu hỏi còn hơn đoán cho đủ 5 RPC. Khi dừng, vẫn ghi migration report với phần đã làm và mục `Stopped` (xem format).

## Quy Trình

1. **Kiểm tra môi trường.**

   ```bash
   git -C <cred-proto> branch --show-current      # không phải master
   docker info > /dev/null 2>&1 && echo "docker OK" || echo "docker DOWN"
   ```

   Đang ở `master` → dừng, cần branch trước. Docker down → báo ngay (`colima start` nếu máy dùng colima); không có Docker thì không lint được.
2. **Đọc Console gốc.** Toàn văn `proto/console/rpc/<name>.proto` và các `proto/console/entity/*.proto` nó tham chiếu. Tên file Console có thể lệch tên RPC (`UpdateBorrowerAssociate` nằm ở `update_borrower_associates.proto`):

   ```bash
   grep -ln "message <Rpc>Request" proto/console/rpc/
   ```

3. **Xác định loại từng RPC** (mục trên). RPC bị từ chối → ghi vào report, làm tiếp RPC còn lại.
4. **Kiểm tra RPC đã có bên Core chưa** (quy trình đầy đủ: `references/existing-core-rpcs.md`):

   ```bash
   ls proto/core/rpc/<snake_case>.proto
   grep -n "<RpcName>" proto/core/rpc/core_service.proto
   git log --diff-filter=A --format='%h %an %ad %s' --date=short -- proto/core/rpc/<snake_case>.proto
   ```

   - Đã migrate từ Console → bỏ qua, ghi `Skipped (already migrated)`.
   - Đang chạy cho minazuki (rpc bật + azuki có handler) → Hướng A (`existing-core-rpcs.md §2`), ghi `Extended`.
   - Có proto nhưng rpc comment-out, chưa có handler → dừng hỏi chọn hướng A/B (`existing-core-rpcs.md §3`).
5. **Viết `proto/core/rpc/<snake_case>.proto`** theo template chunk_1 (`proto-authoring-rules.md §3`, `§4`). Mọi field, số field, `optional`, type, tên field, validate giống Console. Message tự định nghĩa trong `core.rpc` chỉ là `<Rpc>Request`, `<Rpc>Response`, `<Rpc>FilterCondition` và message phụ của riêng request Console. Comment tiếng Nhật.
6. **Field deprecated và entity phụ** (`design-decisions.md §3`):
   - Field `deprecated = true` không phải entity → **giữ nguyên** như Console, kể cả option `[deprecated = true]` (quyết định #10). Liệt kê trong report.
   - Entity phụ trong response (side-load, deprecated hay chưa) → xoá hẳn, **không `reserved`**, đánh số lại liên tục các field sau theo thứ tự Console (quyết định #8, #9). Hướng A không đánh số lại.
7. **Bổ sung validate định dạng Console bị sót** (quyết định #4, `proto-authoring-rules.md §7`): chỉ `string.uuid` / `enum.defined_only`, phân loại field, kiểm chứng giá trị FE gửi bằng code azuki-app. Không chắc thì không thêm, ghi `Not added` trong report.
8. **Query: block JSON mẫu** trong comment request, đúng tên field Console, qua được validate của chính request (`proto-authoring-rules.md §6`).
9. **KHÔNG đăng ký vào `core_service.proto`.** Import và dòng `rpc` viết đúng theo `proto-authoring-rules.md §9` chỉ để ghi vào migration report (mục "Registration (pending)") — không sửa file `core_service.proto` trong worktree. Xem "Đăng Ký `core_service.proto`" cuối file.
10. **So field với Console** (`proto-authoring-rules.md §11`):

    ```bash
    cmp_fields proto/console/rpc/<console_file>.proto proto/core/rpc/<core_file>.proto
    ```

    Chênh lệch nào không thuộc bảng "Quyết định đã chốt" → sửa. Giữ output để ghi vào report.
11. **Lint, format, codegen:**

    ```bash
    make lint
    make format/check      # fail → make fmt rồi chạy lại
    make gen
    ```

    Tất cả chạy qua image builder `ghcr.io/finatext/cred-proto/builder`. `dist/` nằm trong `.gitignore`, không commit.
12. **Ghi migration report** theo `references/migration-report.md`, trả đường dẫn file.

## Điều Kiện Dừng

**Từ chối** (bỏ RPC đó, làm tiếp batch, ghi `Out of scope` trong report): loại `個別設計`; RPC trong danh sách không migrate hoặc chưa được JP confirm (`design-decisions.md §8`).

**Dừng** (cần user quyết, ghi `Stopped` trong report):

- Chỉ migrate được khi nới quyền
- Field ghi "deprecated" trong comment nhưng không có `deprecated = true`
- Console RPC có sort/order by, offset pagination hoặc `total_count`
- Request nhận `operator_id` / `role` / danh tính từ client
- Response nhiều entity mà không xác định được entity chính
- Mở rộng Core RPC đã có mà cần đụng số `reserved ... // 標準実装との整合性確保用`, hoặc field cùng tên khác type (`existing-core-rpcs.md §2` bước 4)
- Core RPC trùng tên có proto nhưng chưa ship (`existing-core-rpcs.md §3`)
- Không tìm thấy Console RPC trong `proto/console/rpc/`

## Bất Biến

- Không tạo `core.entity.*` / `core.rpc.*Filter` mới cho RPC migrate. Dùng lại type Console như chunk_1.
- Field, số field, type, `optional`, tên field của request/response giống Console. Không đổi type (`Money`, `Decimal`, `PhoneNumber`, `PostalAddress`, `YearMonth`... đi kèm entity Console).
- Không bớt validate Console. Không thêm validate ngoài `string.uuid` / `enum.defined_only` theo quyết định #4.
- Response Query chỉ 1 entity chính + pagination, kể cả khi Console trả nhiều entity. Không nhét count. Không tự tạo RPC mới cho entity phụ.
- Không sửa, không xoá gì trong `proto/console/**`. Không tạo breaking change cho Core RPC đang có.
- Không thêm idempotency dưới bất kỳ hình thức nào. Không thêm field vào `GetFeatureFlags`.
- Không tạo thư mục `v1`. Package cố định `core.rpc`.
- Không commit, không push, không tạo PR.
- **Không sửa `core_service.proto`** trong PR proto lẻ (xem "Đăng Ký `core_service.proto`" dưới đây) — kể cả khi RPC đã viết xong và pass hết verification.

## Điều Kiện Hoàn Thành

- Core RPC (proto file riêng) đã viết xong, đúng tên `<Rpc>Request` / `<Rpc>Response`; **chưa** đăng ký vào `CoreService` — đó là việc của PR batch riêng.
- `cmp_fields` chỉ còn chênh lệch thuộc "Quyết định đã chốt"; số field chỉ lệch Console ở chỗ đánh số lại sau field bị bỏ.
- Mọi comment tiếng Nhật; mọi request Query có JSON mẫu.
- `make lint`, `make format/check`, `make gen` pass. Vì RPC chưa đăng ký vào `CoreService`, `buf lint` có thể cảnh báo file proto "unused import"/không được service nào tham chiếu — đây là cảnh báo dự kiến, không phải lỗi cần sửa; ghi rõ trong `## Verification` của report.
- Migration report đủ mọi mục bắt buộc, kể cả khi dừng giữa chừng, kể cả mục "Registration (pending)".

## Đăng Ký `core_service.proto`

Từ nay việc đăng ký RPC vào `CoreService` (import + dòng `rpc`) **không nằm trong PR proto của từng RPC nữa** — dồn lại, đăng ký theo lô trong 1 PR riêng sau khi một số PR proto đã merge, để tránh nhiều PR cùng sửa `core_service.proto` gây conflict lúc review/merge.

- Viết đúng import và dòng `rpc` theo `proto-authoring-rules.md §9` (vị trí alphabet cho import, cạnh cụm RPC cùng domain cho dòng `rpc`), nhưng chỉ **ghi vào migration report** ở mục `## Registration (pending)`, không áp dụng vào file `core_service.proto` thật.
- Khi đến lúc gom lô đăng ký: mở PR riêng trên 1 branch mới từ `master` mới nhất, gộp phần "Registration (pending)" của các migration report liên quan thành một lần sửa `core_service.proto` (import + rpc, đúng alphabet/vị trí domain), chạy lại `make lint`/`format/check`/`gen`, rồi tạo PR bằng skill `azuki-core-api-migration-pr` với title dạng `[CRES-#####] Register <RPC group> in CoreService`.
- PR batch đăng ký chỉ nên gộp các RPC mà proto đã **merge vào `master`** (không đăng ký RPC còn nằm ở PR chưa merge, tránh rpc trỏ tới file chưa tồn tại trên `master`).

## Reference

| File | Đọc khi |
|---|---|
| [design-decisions.md](references/design-decisions.md) | Bắt đầu mọi batch: phân loại, entity chính, deprecated, ngoài phạm vi, lịch sử quyết định |
| [proto-authoring-rules.md](references/proto-authoring-rules.md) | Viết proto: template chunk_1, filter, JSON mẫu, validate, `core_service.proto`, lệnh so field |
| [existing-core-rpcs.md](references/existing-core-rpcs.md) | RPC trùng tên với Core RPC đã có (`GetDocuments`, `GetContracts`, `GetContractApplications`) |
| [migration-report.md](references/migration-report.md) | Trước khi kết thúc: format report giao cho bước tạo PR |

Sau khi PR mở, nên review lại bằng skill `azuki-review-console-rpc-to-core-proto`.
