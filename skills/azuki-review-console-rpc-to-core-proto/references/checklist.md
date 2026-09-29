# Checklist review PR migrate Console RPC → Core proto

Đi qua theo thứ tự cho từng RPC trong PR. Quy tắc chuẩn: skill `azuki-core-api-proto-migration-workflow-v2` (bảng "Quyết Định Đã Chốt" trong `SKILL.md`, số `#` bên dưới là số trong bảng đó). Mỗi mục có lệnh kiểm tra và ca thật đã gặp.

Lệnh so field dùng xuyên suốt (giống `proto-patterns.md §10`):

```bash
cmp_fields() {  # $1 = file Console, $2 = file Core — so label + type + tên (không so số)
  norm() { grep -oE '^\s+(optional |repeated )?[a-zA-Z0-9_.<>, ]+ [a-z_0-9]+ = [0-9]+' "$1" \
    | sed -E 's/^\s+//; s/ = [0-9]+$//; s/(console|core)\.(entity|rpc)\.//g' | sort; }
  diff <(norm "$1") <(norm "$2") && echo "fields match"
}
cmp_fields proto/console/rpc/<x>.proto    proto/core/rpc/<x>.proto
cmp_fields proto/console/entity/<x>.proto proto/core/entity/<x>.proto
```

Prefix `console.` / `core.` bị chuẩn hoá nên lệnh chỉ báo khác biệt thật về label, type, tên.

---

## 1. Không import Console (#1)

```bash
grep -n "console" proto/core/rpc/<file>.proto proto/core/rpc/filter.proto proto/core/entity/<file>.proto
```

- Còn `import "console/entity/..."`, `import "console/rpc/filter.proto"`, hoặc `console.entity.X` / `console.rpc.X` → **Cần sửa**. Phải định nghĩa `core.entity.X` / `core.rpc.XFilter`.
- Ngoại lệ không phải finding: file chunk_1 (`create_role.proto`, `get_borrower_expatriations.proto`) và Core RPC không phải migrate (`get_operator_notifications.proto`, `submit_credit_information_file_import_decision.proto`) — #12.
- PR merge trước 2026-09-28 dùng console entity (#2281, cụm BorrowerAssociate) → finding "cần follow-up"; đã sửa ở #2351.
- Tên field tham chiếu filter phải là tên Console, kể cả không theo convention. Ca thật: #2257 đổi `notification_filters` → `operator_notification_filters`; #2256 đổi `borrower_related_party_filter` → `borrower_associate_filters`.

---

## 2. Entity / filter mirror Console (#2, #3, #4, #5)

```bash
cmp_fields proto/console/entity/<x>.proto proto/core/entity/<x>.proto
git show origin/master:proto/core/entity/<x>.proto | grep -E "^(message|enum) "   # file có sẵn trên master
gh pr diff <n> -- proto/core/entity/<x>.proto | grep -E "^-(message|enum) "        # PR có xoá message nào
```

- **Type**: giữ type Console (`google.type.Money`, `PhoneNumber`, `PostalAddress`, `Decimal`, `Date`, `DateTime`, `cred_type.*`). Đổi sang `int64` / `string`, tách field → **Cần sửa**. Ca thật: #2287 đổi `PostalAddress` → 4 field phẳng, `PhoneNumber` → `string`, `Money` → `int64` → revert ở #2351.
- **Message riêng của Console** (`YearMonth`, `Sex`...) → phải có message Core cùng tên, cùng field.
- **Số field entity/filter**: liên tục 1..N theo thứ tự Console. Còn `reserved` / khoảng trống → **Nên sửa**. Đảo thứ tự → **Cần sửa**.
- **Enum**: giữ đúng giá trị, số, khoảng trống và `reserved` như Console. Đánh số lại enum → **Cần sửa**.
- **Filter**: đủ mọi field Console, kể cả field tham chiếu domain chưa có Core RPC. Bỏ field → **Cần sửa**. Ca thật: #2287 lần đầu bỏ 5 field `BorrowerFilter` (`core_system_tag` còn, các field khác mất) → phải khôi phục. `oneof` 1 field → `optional` là hợp lệ.
- **Enum domain khác**: file `core/entity/<domain>.proto` chỉ chứa enum cần dùng, có comment `…ドメインの Core RPC が未実装のため、…が参照する enum のみ定義する。` Thiếu comment → **Nên sửa**.
- **File có sẵn**: PR xoá message/enum đang có trên `master` (do `Write` đè) → **Blocker** (`buf lint` sẽ báo `cannot find core.entity.X` nếu RPC khác dùng; nếu không ai dùng thì mất âm thầm). Type đã có ở Core mà PR định nghĩa lại → **Cần sửa** (import). Ca thật đúng: #2350 import `BorrowerStatus`, `CoreDocumentKey` có sẵn.
- **Comment**: giữ comment Console (kể cả `TODO:`) khi field không đổi. Mất `TODO:` → **Nên sửa**.

---

## 3. Request / response giống Console (#3, #7, #8)

```bash
cmp_fields proto/console/rpc/<console_file>.proto proto/core/rpc/<core_file>.proto
```

Chênh lệch chỉ được là: side-load bị xoá (mục 6), field thêm theo Hướng A (mục 7). Request/response giữ số Console; chỉ đánh lại các field sau side-load bị xoá. Các dạng lệch đã gặp (tất cả **Cần sửa**):

| Dạng lệch | Ca thật |
|---|---|
| Bỏ `field_mask` vì "dead field" / "client không gửi" | #2257 (`GetOperatorNotifications`), #2264 (`GetOperatorRegistrations`) |
| Đánh số lại khi không bỏ field nào | #2264: `bitemporal_query` 4→3, `filter` 5→4 |
| Đảo thứ tự field response | #2264: Console `operator_registrations = 1, pagination = 2`, Core đảo ngược |
| Mất `optional` | #2264: `OperatorRegistration.operator_id` (Console `optional string`) |
| Bỏ `effective` | #2256: `Update/DeleteBorrowerAssociate` |
| Thêm field Console không có | Console không có `pagination` / `field_mask` (ví dụ `GetReviewFlowSteps`, `GetBorrowerProfiles`) thì Core cũng không có |

Tên file Console có thể lệch tên RPC (`update_borrower_associates.proto`): tìm bằng `grep -ln "message <Rpc>Request" proto/console/rpc/`.

### Shape Write RPC

- **Update** giữ shape Console (`field_mask` + cả entity + `effective`). PR tách payload `UpdateXxx` hoặc tách ID ra top-level → **Cần sửa**. Ca thật: #2256 `UpdateBorrowerAssociate`.
- `review_request` dùng `core.entity.ReviewRequestParams` (trong `core/entity/review_request.proto`, #2351). Còn `console.entity.ReviewRequestParams` → **Cần sửa** (mục 1).
- Message cục bộ của request Console (ví dụ `console.rpc.ReviewFlowStep` của `CreateReviewFlow`) → phải ở `core.rpc`, không phải `core.entity` (trùng tên entity `ReviewFlowStep` đầy đủ). RPC khác import lại → PR đó phải stack (#2294 → #2295).
- **Response `REQUIRED`** (#6): `string.uuid` + `(google.api.field_behavior) = REQUIRED` chỉ hợp lệ khi handler set field ở **mọi** nhánh thành công:

  ```bash
  cat azuki/internal/presentation/console_api_presentation/internal/<snake_case_rpc>/handler.go
  ```

  Handler không set mà PR có `REQUIRED` → **Cần sửa**. Ca thật: `SubmitBorrowerWithdrawalDecisionResponse.borrower_withdrawal_decision_id` (scenario không trả ID) → revert. Handler luôn set mà PR không có → không phải lỗi, có thể gợi ý (**Nên sửa**). Ca thật: #2298 `SubmitReviewResponse.review_id` được bổ sung sau review.

---

## 4. Validate request (#6)

So bằng mắt với file Console (lệnh `cmp_fields` không bắt validate).

- **Bớt rule Console có** → **Cần sửa**.
- **Thêm rule khác `string.uuid` / `enum.defined_only`** (`email`, `min_len`, `gte`, CEL, `required` Console không có...) → **Cần sửa**. Ca thật: #2257, #2263 thêm `required` cho `licensee_id` trong khi Console không có (`GetOperatorNotificationsRequest`, `SubmitBorrowerWithdrawalDecisionRequest`).
- **Thêm `string.uuid` lên `string` thường** (không `required`, không `optional`) → **Blocker**: protovalidate v1.3.0 từ chối `""`, request FE đang gửi rỗng sẽ lỗi.
- **Rule thêm vào `proto/console/**`** → **Blocker**.
- **Rule hợp lệ nhưng thiếu kiểm chứng**: PR description không có mục `### Validation added on top of Console` hoặc thiếu `Verification` → **Cần sửa**. Tự kiểm chứng nếu có thể:

  ```bash
  grep -n "Get<FieldCamel>()" azuki/internal/presentation/console_api_presentation/internal/<snake_case_rpc>/handler.go
  grep -rn "<rpcNameCamelCase>\|<RpcName>Request" azuki-app/src
  ```

---

## 5. Field deprecated (#8)

```bash
grep -n "deprecated = true" proto/console/rpc/<console_file>.proto proto/console/entity/<x>.proto
```

- Field `deprecated = true` (không phải side-load) → phải **còn nguyên** trong message Core, cả ở request/response lẫn entity Core mirror: cùng type, còn option `[deprecated = true]`. Bỏ hoặc thay bằng `reserved` → **Cần sửa**.
- Side-load deprecated trong response → phải bị bỏ (mục 6).
- PR description có mục `### Deprecated fields` ghi rõ giữ hay bỏ.

---

## 6. Response 1 entity chính (#7)

- Response Query chỉ có `pagination` (nếu Console có) + 1 `repeated <Entity>`. Còn `map<string, Entity>`, `repeated` entity khác, hoặc field count → **Cần sửa**.
- Console response nhiều entity (`分割`, `分割レビュー`, hoặc nhãn `1対1レビュー` mà nhiều entity) vẫn được migrate: field side-load phải bị xoá (không `reserved`, đánh số lại nếu có field sau), PR liệt kê các entity đã bỏ. Không yêu cầu PR tạo RPC cho entity phụ.
- Request/filter vẫn giữ như Console, kể cả filter theo field của entity liên quan. PR bỏ filter vì "entity đó sẽ tách ra" → **Cần sửa**.
- Entity chính chọn sai (không trùng tên RPC, không phải `repeated` đầu tiên) → **Cần sửa**.

---

## 7. Console RPC trùng tên với Core RPC có sẵn

```bash
git log --diff-filter=A --format='%h %an %ad %s' --date=short -- proto/core/rpc/<file>.proto
grep -n "rpc <RpcName>(" proto/core/rpc/core_service.proto
```

Quy trình chuẩn: `proto-patterns.md §8` của skill v2. Xác định RPC Core đó đang chạy (rpc bật + azuki có handler, ví dụ `GetDocuments`) hay chưa ship (rpc comment-out, ví dụ `GetContracts`, `GetContractApplications`). PR đụng RPC chưa ship mà không ghi hướng đã được user/JP chọn → **Cần hỏi JP**.

- Core RPC đang chạy cho minazuki → chỉ được mở rộng theo Hướng A:
  - Không đổi số, type, tên field đang có → vi phạm là **Blocker** (breaking cho minazuki, `buf breaking` cũng chặn).
  - Field mới ở số chưa dùng, `optional`, không `required`. `field_mask` thêm vào mà `required` → **Blocker**.
  - Thêm field vào entity/enum có `reserved ... // 標準実装との整合性確保用` mà PR không ghi đã hỏi → **Cần hỏi JP**.
  - PR description phải có danh sách field required bên Console đã thành `optional`, và câu hỏi "field thêm vào response cũng trả cho minazuki" → thiếu là **Cần sửa**.
- Type mới cho field thêm vào phải là `core.entity.*` (#1). Hướng A chưa có PR thật theo v2 → nếu PR import `console/entity/*` cho Hướng A, ghi **Cần hỏi JP** thay vì **Cần sửa**.
- Field cùng tên khác type mà PR tự đổi → **Blocker**.
- PR tạo RPC thứ hai với tên khác để né trùng → **Cần sửa**.

---

## 8. Block JSON mẫu (Query)

```bash
grep -L "サンプル" proto/core/rpc/get_*.proto
```

- Thiếu mẫu → **Nên sửa**.
- Mẫu dùng tên field khác Console (ví dụ `operatorNotificationFilters` thay vì `notificationFilters`) → **Nên sửa**.
- Mẫu không qua được validate của chính request (thiếu `fieldMask` khi Console `required`, `pageSize` > 100, enum `*_UNSPECIFIED`, ID không phải UUID) → **Nên sửa**.

---

## 9. Comment

- Comment viết mới trong `proto/core/**` là tiếng Nhật, kể cả dòng `rpc` trong `core_service.proto`. Ca thật: #2264 viết tiếng Anh toàn bộ → **Nên sửa**.
- Comment copy nguyên từ Console (kể cả header enum tiếng Anh như `// Unspecified`) → chấp nhận, không phải finding.
- Comment Console sai nghĩa so với UI → sửa theo `azuki-app/locales/ja/enum.json` là đúng (ví dụ `UNKNOWN_PAYMENT_IN` → 入金突合中, `IN_REVIEW_IDENTITY_VERIFICATION` → 本人確認中, #2287).
- Comment mô tả rule không còn đúng (ví dụ "7桁であること" cho postal code đã tách) → **Nên sửa**.

---

## 10. PR 1 RPC, stack, `core_service.proto` (#9, #10)

- PR gộp nhiều RPC (trừ PR follow-up sửa nhiều nhóm như #2351) → **Nên sửa** / đề xuất tách. Ca thật: #2268 → tách thành #2287 + #2288.
- PR 1 RPC có diff đụng `core_service.proto` → **Cần sửa**: bỏ ra, để PR đăng ký lô.
- PR đăng ký lô (title `Register ... in CoreService`): import xếp alphabet, 1 import mỗi file; `rpc` cạnh cụm cùng domain hoặc cuối service; chỉ RPC **đã merge vào `master`** — RPC chưa merge sẽ làm `buf` lỗi (`imported file does not exist`). Mẫu: #2352.
- Nhiều PR mở cùng sửa `filter.proto` / cùng entity file → gợi ý dồn vào 1 PR gốc, các PR khác stack (mẫu: #2291 cho #2289/#2290; #2297 cho #2296/#2298).
- PR stack: base là branch PR gốc, description có "Stacked on #...". Thiếu → **Nên sửa**. Base `master` nhưng dùng type chỉ có ở PR khác chưa merge → **Cần sửa** (CI sẽ fail sau khi rebase).
- `git diff --stat origin/master` của PR có file bị xoá mà PR không cố ý → branch cũ, cần rebase → **Cần sửa**.
- PR tự gắn `option (google.api.method_visibility).restriction = "PUBLIC"` mà user không yêu cầu → **Nên sửa**.

---

## 11. Không đưa vào việc ngoài phạm vi (#13)

Có bất kỳ mục nào → **Cần sửa**:

- Field `idempotency_key`, `option idempotency_level`, comment hợp đồng chống trùng
- Thay đổi cấu trúc `BitemporalQuery`, bỏ/đổi `FieldMask` ở Query
- Field mới trong `GetFeatureFlagsResponse`
- Sửa Console RPC/entity
- Sửa chunk_1 / Core RPC không phải migrate khi không được yêu cầu (#12)

---

## 12. ID tạo ra nhưng không trả về → Cần hỏi JP

Console tự thân cũng không trả thì không phải lỗi của PR, nhưng ghi lại để hỏi. Không yêu cầu thêm field vào Core.

- `SubmitBorrowerEmailAddressChangeDecision`: response `{}` dù có tạo `review_request`.
- `SubmitBorrowerWithdrawalDecision`: scenario tạo decision ID nhưng chỉ trả review request ID.
- `SubmitOperatorRegistrationResult`: `acceptanceID`, `newOperatorID` tạo trong scenario rồi bỏ đi.

---

## 13. Ảnh hưởng FE

- Entity Core mirror Console, giữ type → shape JSON giống Console, FE chỉ cần đổi service. Không cần ghi gì thêm.
- PR đổi type / tách field → ghi rõ field nào làm FE vỡ: `entity.address.postalCode` → `entity.postalCode`; `phoneNumber.nationalNumber` → `phoneNumber` (string); `annualIncome.units` → `annualIncome` (number).
- Đánh số lại entity Core không ảnh hưởng FE (JSON theo tên), chỉ ảnh hưởng client binary — hiện chưa có (entity Core chưa được handler nào dùng).
- Hướng A: field Console bắt buộc thành `optional` → FE phải xử lý trường hợp field vắng mặt.

---

## 14. PR description

Theo `pr-templates.md` của skill v2:

- Title chứa `CRES-#####`, < 70 ký tự; đúng 1 label semver (thường `release:minor`).
- Tiếng Anh; chỉ `## 概要` / `## 参考リンク` tiếng Nhật. Không có Backlog (`SPCC-...`), Mattermost nội bộ, tiếng Việt → vi phạm là **Nên sửa**.
- Có: `### Target RPCs`, blockquote "Registration in `CoreService` will be added later in a separate batch PR.", `### Added definitions` (ghi file nào mới / append), `### Differences from Console` (hoặc `None`), `### Deprecated fields`, `### Validation added on top of Console` (mỗi rule có `Verification`).
- PR stack: dòng "Stacked on #..." đầu `## 概要`.
- Không có `Not included in this PR` / `Verified` / `Points to confirm` / `Skipped RPCs` (trừ PR đăng ký lô) — có thừa là **Nên sửa** mức nhẹ.
- Hướng A: có danh sách field required → optional và câu hỏi về response trả cho minazuki.

---

## Ca thật

| PR | Nội dung | Vấn đề / bài học | Kết quả |
|---|---|---|---|
| #2256 | BorrowerAssociate (4 RPC) | Core entity riêng kiểu cũ, `PhoneNumber` → string, tách `PostalAddress`, payload `UpdateXxx`, bỏ `effective` | Follow-up #2275; entity Core mirror lại ở #2351 |
| #2257 | GetOperatorNotifications, SendBorrowerIndividualEmail | `subject` string → enum, bỏ `field_mask`, đổi tên field filter/response, thêm `licensee_id required` | Follow-up #2276 |
| #2263 → #2281 | BorrowerProfile (4 RPC) | Import `console.entity.BorrowerProfile` (quy tắc cũ) | Merged; follow-up #2351 |
| #2264 | GetOperatorRegistrations | Mất `optional operator_id`, bỏ `field_mask`, đánh số lại, đảo field response, comment tiếng Anh | Follow-up #2278 |
| #2268 | GetBorrowers + GetEmailSuppressions 1 PR | Reviewer (mirror-kt) yêu cầu tự định nghĩa entity | Tách #2287, #2288 |
| #2287 | GetBorrowers | Bỏ 5 field filter, convert type | Filter khôi phục trước merge; type revert ở #2351 |
| #2289–#2291 | Review cluster A | 3 PR cùng sửa `filter.proto` | Dồn filter vào #2291, 2 PR stack |
| #2296–#2298 | Review cluster B | #2297 là PR gốc; #2298 thiếu `REQUIRED` cho `review_id` dù handler luôn set | Bổ sung trước merge |
| #2350 | GetBorrowerProvidedDocuments (tác giả khác) | Đúng v2; reviewer (mình) nêu nhầm "Money → int64" | Rút lại finding; bài học: chỉ nêu quy tắc có trong bảng |
| #2351 | Follow-up Borrower / BorrowerProfile / BorrowerAssociate | Mẫu follow-up nhiều nhóm, append `ReviewRequestParams` vào file có sẵn | — |
| #2352 | Đăng ký 10 RPC | Mẫu PR lô | Merged |
