# Quyết định thiết kế trước khi viết proto

Đọc file này trước khi viết dòng proto nào: phân loại RPC, xác định entity chính, biết khi nào dừng.

Nguồn: `docs/CoreAPI/JPDOC_2026-08-14 Console APIからCore APIへの移行方針.md` (design doc gốc), sheet mapping `JPDOC_CoreAPIエンドポイント整理 - Console -_ Core API.pdf`, chunk_1 của JP, và các quyết định trên Mattermost ghi trong `SKILL.md`.

---

## 1. Phân loại RPC (`マッピング種別`)

| Loại | Số lượng | Ý nghĩa | Hành động |
|---|---|---|---|
| `1対1レビュー` | 111 | Query map thẳng 1 Console RPC → 1 Core RPC / 1 entity | **Làm** |
| `業務操作` | 80 | Write, 1 thao tác nghiệp vụ = 1 RPC | **Làm** |
| `個別設計` | 20 | Export, generate file, aggregate nặng | Từ chối |
| `分割レビュー` | 6 | Response nhiều entity, chưa chốt tách thế nào | **Làm**, chỉ giữ entity chính |
| `分割` | 3 | Response nhiều entity, đã chốt phương án | **Làm**, chỉ giữ entity chính |

`分割` / `分割レビュー` (user chốt 2026-09-25): RPC vẫn migrate, response chỉ giữ đúng 1 entity chính. Entity phụ tách sang RPC nào là quyết định ở RPC khác, không ảnh hưởng việc migrate chính RPC này. Danh sách: `分割` = `GetBorrowers`, `GetContracts`, `GetContractApplications`; `分割レビュー` = `GetBorrowerDeduplications`, `GetBorrowerIdentityVerifications`, `GetBorrowerProvidedDocuments`, `GetEmploymentVerificationRequests`, `GetLendingSummary`, `GetTransactions`.

Từ chối (chỉ còn `個別設計`) ≠ dừng batch: bỏ RPC đó, ghi báo cáo, làm tiếp.

### Nhãn sheet không đủ tin

8 RPC trả nhiều entity mà vẫn mang nhãn `1対1レビュー` (xử lý như `分割`: chỉ giữ entity chính; ghi vào báo cáo để JP sửa sheet):

| Console RPC | Entity trong response |
|---|---|
| `GetReviewRequests` | ReviewRequest, Review, ReviewFlow, ReviewFlowStep, Operator |
| `GetReviewFlows` | ReviewFlow, ReviewFlowStep, Operator |
| `GetCreditInformations` | CreditInformation, CicKaitou, CicShokai |
| `GetSuspiciousTransactions` | SuspiciousTransaction, Borrower, TagAttachment |
| `GetOperators` | Operator, Role |
| `GetCreditInformationsWithSimilarities` | CreditInformation, CicKaitou |
| `GetContractApplicationDealProposals` | DealProposal, DealProposalAmountLimit |
| `GetScoringRequests` | ScoringRequest, ScoringResult |

Cột `全て同じEntityを返すか` trong sheet cũng ghi `TRUE` cho gần như mọi dòng, không dùng được. Luôn đếm entity trong response Console.

Entity phụ deprecated hay chưa đều xử lý giống nhau: xoá khỏi response, không `reserved`, đánh số lại (§3). Ca đã áp dụng: `GetReviewRequests` (5 map side-load).

### Khi không tra được sheet

- Response chỉ có `pagination` + 1 `repeated Entity` → `1対1レビュー`
- Có `map<string, SomeEntity>` hoặc nhiều `repeated` khác loại → vẫn làm, chỉ giữ entity chính (§2)
- Tên bắt đầu `Export` / `Count` / `Generate` / `Parse` / `IssueURL` / `ValidateAndProcess` → `個別設計`
- Tên bắt đầu `Create` / `Update` / `Delete` / `Submit` / `Upsert` / `Withdraw` / `Transition` / `Assign` / `Register` / `Send` / `Make` / `Unlink` / `Manual` → `業務操作`

---

## 2. Entity chính

Mỗi Query RPC có đúng 1 entity chính, xác định theo thứ tự:

1. Entity trùng tên RPC (`GetContracts` → `Contract`)
2. Entity ở field `repeated` đầu tiên của response, không nằm trong `map<>`
3. Entity mà `pagination` đang phân trang theo

Entity chính **luôn là type Console** (`console.entity.<X>`), import thẳng như chunk_1. Không tạo `core.entity.<X>`.

Mọi field khác trong response Console (side-load `map<string, X>`, `repeated` entity khác, count) **không migrate**, dù deprecated hay chưa:

- Xoá field đó khỏi response Core, **không `reserved`**; field sau nó (nếu có) đánh số lại liên tục (§3).
- Liệt kê trong PR (bảng `### Field mapping`, ghi chú `Not the main entity (handled by another RPC)`). Không tự tạo RPC mới cho entity phụ, không hỏi phải tách thế nào — đó là việc của RPC khác.
- Request và filter **giữ như Console**, kể cả filter theo field của entity liên quan (ghi chú sheet cho `GetBorrowers`: "Borrower検索条件は維持し関連entityは別Core APIに分割する").
- Không xác định được entity chính (response là tập số liệu tổng hợp, ví dụ `GetLendingSummary`) → dừng hỏi.

---

## 3. Field deprecated

Nhận ra 3 dạng Console dùng:

1. `[deprecated = true]` ở field/enum value, thường kèm comment `// deprecated: ...` / `// Deprecated: Do not use.`
2. `option deprecated = true;` ở message/enum (hiếm, trong `console/worker/worker.proto`)
3. `reserved` số + tên

Xử lý (user chốt 2026-09-25: chỉ bỏ entity deprecated; field deprecated còn lại không thuộc phạm vi migrate):

| Vị trí | Xử lý |
|---|---|
| Entity phụ trong response (`map<string, X> [deprecated = true]`, `repeated X` entity khác) | **Bỏ** (§2, quyết định #8), không `reserved`, đánh số lại field sau |
| Field `deprecated = true` không phải entity, trong message `core.rpc` (request, response, FilterCondition) | **Giữ nguyên** như Console: cùng số, cùng type, giữ option `[deprecated = true]` và comment. Liệt kê trong report/PR |
| Field deprecated nằm trong type Console dùng lại (`console.entity.*`, `console.rpc.*Filter`) | Giữ (không sửa Console). Liệt kê trong report/PR nếu RPC dùng tới |

Không tự xác định "field deprecated này còn dùng hay không" để bỏ riêng: dọn field deprecated là việc làm sau khi migrate xong, không thuộc đợt này.

Chỉ có comment ghi "deprecated" mà không có option → **dừng và hỏi**.

### Đánh số lại thay cho `reserved` (chốt 2026-09-25)

Nguồn: Misato Kano, thread review PR proto — "フィールド番号の振り直しはやってもいいと思います"; team chốt trong discuss là đánh số lại, không dùng `reserved`. Review của ViTran ở #2256, #2257 cũng yêu cầu bỏ `reserved`.

Hiện chỉ entity phụ trong response bị bỏ, nên đánh số lại chỉ xảy ra khi entity phụ nằm **trước** field khác trong response Console. Thường entity phụ nằm sau entity chính (ví dụ `GetContractsResponse`: `pagination = 1`, `contracts = 2`, map side-load 3–6), nên bỏ đi không làm đổi số field nào.

- Chỉ đánh số lại message tự định nghĩa trong `core.rpc`. Type Console dùng lại (entity, filter) không đụng tới.
- **Không đánh số lại** Core RPC đang chạy (Hướng A, `existing-core-rpcs.md`): đổi số field đã release là breaking cho minazuki.
- Không có field nào bị bỏ → giữ nguyên số Console.

---

## 4. Ngoài phạm vi đợt migrate

### Idempotency

Không thêm field `idempotency_key`, không thêm `option idempotency_level`, không viết comment mô tả hợp đồng chống trùng. User chốt 2026-09-24 dù cột `冪等キー要否` trong sheet ghi `必要` cho mọi `業務操作`.

Bối cảnh (không phải hướng dẫn): azuki đã có interceptor idempotency (`internal/lib/connect/middleware/idempotent.go`, header `Idempotency-Key`), hiện chỉ wire cho kintsuba. Console cũng không chống trùng cho Write RPC, nên Core chưa có không phải regression.

### Refactor BitemporalQuery, chuẩn hoá FieldMask

JP (Kaz Togo) đề xuất tái cấu trúc `BitemporalQuery` (tìm theo khoảng thời gian, tách ngày hiệu lực/ngày xác định) và chỉ dùng `FieldMask` cho Update, triển khai nghiêm ngặt. Chốt 2026-09-25: **ngoài phạm vi**, giữ như Console.

---

## 5. RPC dạng Write (`業務操作`)

- 1 thao tác nghiệp vụ = 1 RPC. Không tạo RPC theo nút bấm UI (`ApproveAndNotify` là NG theo design doc).
- Xử lý phụ (thông báo, chuyển trạng thái) nằm trong server, không lộ ra proto.
- **Create**: request giống Console. Response trả ID như Console; có thể thêm `(google.api.field_behavior) = REQUIRED` + `string.uuid` cho ID như `CreateRoleResponse.role_id` của chunk_1 (chỉ là annotation cho spec, azuki không validate response).
- **Update**: giữ đúng shape Console, thường là `licensee_id`, `field_mask`, cả entity Console, `effective`. Không tách payload `UpdateXxx`, không tách ID ra top-level. Ca đã sửa: `UpdateBorrowerAssociate` ở PR #2275.
- **Delete / Unlink**: giữ `effective` nếu Console có.
- Response rỗng thì `message XxxResponse {}` như Console.

---

## 6. Console RPC trùng tên với Core RPC đã có

### Trùng tên không phải lỗi kỹ thuật

Console và Core là 2 service, 2 package: `/console.rpc.ConsoleService/GetDocuments` và `/core.rpc.CoreService/GetDocuments` là 2 procedure khác nhau; message `console.rpc.GetDocumentsRequest` và `core.rpc.GetDocumentsRequest` sinh code ở 2 thư mục khác nhau. FE import kèm alias (`CreateRoleRequest as CoreCreateRoleRequest`).

Ràng buộc thật: **trong `CoreService` mỗi tên RPC là duy nhất.** Không tạo RPC thứ hai, không đặt tên khác để né.

### Phân loại

| Tình huống | Xử lý |
|---|---|
| RPC Core đã migrate từ Console (chunk_1, PR migrate đã merge) | Bỏ qua, ghi vào PR |
| RPC Core **đang chạy cho minazuki** (rpc bật + azuki có handler) | Hướng A (`existing-core-rpcs.md §2`) |
| RPC Core có proto nhưng rpc comment-out, chưa có handler | Dừng hỏi chọn hướng A/B (`existing-core-rpcs.md §3`) |
| RPC Core của Platform Console (`GetFeatureFlags`...) | Ngoài phạm vi migrate |

Trùng tên trên `master` tại 2026-09-25:

| RPC | Core dựng cho | Loại trong sheet | Xử lý |
|---|---|---|---|
| `CreateRole`, `GetBorrowerExpatriations` | chunk_1 | — | Bỏ qua |
| `GetDocuments` | minazuki (production) | `1対1レビュー` | **Hướng A** |
| `IssuePresignedGetURLsForDocuments` | minazuki | `個別設計` | Từ chối |
| `GetContracts`, `GetContractApplications` | dựng cho minazuki nhưng **chưa ship** (rpc + import comment-out, azuki không có handler, entity không RPC nào khác dùng) | `分割` | Dừng hỏi chọn hướng A/B (`existing-core-rpcs.md §3`) |
| `GetFeatureFlags` | Platform Console | — | Ngoài phạm vi |

`kintsuba` **không** dùng `CoreService` (có service riêng `KintsubaIncomingService`), nên không có trùng tên với kintsuba.

### Hướng A: giữ entity Core, chỉ thêm field Console cần

Quy trình từng bước và bảng đối chiếu hiện tại của `GetDocuments`, `GetContracts`, `GetContractApplications`: `existing-core-rpcs.md`. Tóm tắt:

Duyệt bởi hirose.hikaru (người dựng các RPC đó) trên Mattermost 2026-09-25: field của nhóm update bên minazuki hầu hết là optional (trừ `licensee_id`…), validate nghiệp vụ nằm ở validator phía fsm, nên hướng này không ảnh hưởng minazuki.

Đây là **ngoại lệ duy nhất** của quy tắc "dùng lại type Console". Cách làm:

- **Chỉ thêm**, không đổi số, type, tên của field đang có. Không đổi type của field response (ví dụ không đổi `core.entity.Document` sang `console.entity.Document`, vì cùng số field khác nghĩa là breaking change cho minazuki).
- Field mới (request, filter, entity) đặt ở số chưa dùng, sau số lớn nhất hiện có.
- Field Console bắt buộc (`required = true`, hoặc luôn có giá trị) → khai báo `optional` bên Core, bỏ `required`. Lý do: minazuki không gửi / không có giá trị cho field đó.
- `field_mask` của Console (`required`) → thêm dưới dạng field **không required**. `bitemporal_query` → `optional`.
- Validate định dạng (`string.uuid`, `enum.defined_only`) vẫn áp dụng được theo `proto-authoring-rules.md §7`, vì field mới là `optional`.
- Entity Core có `reserved ... // 標準実装との整合性確保用` (ví dụ `core/entity/document.proto`) nghĩa là số field phải khớp một baseline dùng chung nhiều sản phẩm: **dừng và hỏi** trước khi thêm field vào entity đó.

Ghi vào mục cần confirm của PR, lần nào cũng ghi:

- Field thêm vào **response** cũng sẽ trả cho minazuki. Câu hỏi này chưa được trả lời trên Mattermost (hirose-san chỉ nói về field update), nên cần JP xác nhận.
- Danh sách field required bên Console đã đổi thành `optional` bên Core.

---

## 7. Quyền hạn — không nới rộng

Trích design doc:

> Console RPCと同等以上に制限し、移行を理由に権限を広げない。

Tầng proto không có annotation permission. Nhưng nếu thấy RPC chỉ chạy được khi nới quyền, hoặc request nhận `operator_id` / `role` / danh tính từ client thay vì context → **dừng và báo**, không bê field đó sang Core.

---

## 8. Nhóm không làm bằng skill này

`個別設計` (design doc liệt kê): export dữ liệu lớn / xử lý dài; ghi vào nhiều hệ thống; phân quyền đặc thù chỉ Console có; aggregate query mà tách response sẽ chậm nhiều. Ví dụ: `ExportBorrowers`, `ExportTransactions`, `GenerateLoanBalanceCertificate`, `GMOIssueToken`, `IssueUploadURL`, `CountAwaitingOperatorActions`.

Không migrate: `GetOrgEnv`, `GetSupervisorEnv` (sheet ghi `移行しない`), `SignInByIDToken`, `InviteOperators`.

Chưa được JP confirm (không còn nơi gọi ở FE): `GetDunningTargets`, `CreateOAuth2Client`, `GetEmailChangeVerificationDecisions`, `SubmitBorrowerSolicitationRestriction`, `SubmitEmailChangeVerificationDecision`, `SubmitEmploymentVerificationRevalidate`, `CreateDocumentTemplate`. User đưa RPC nào trong số này → hỏi lại trước khi làm.

---

## 9. Bảng field — output bắt buộc cho PR

Mỗi RPC một bảng, bê vào PR description:

```markdown
### GetBorrowerAssociates

| Console field | Số | Xử lý | Ghi chú |
|---|---|---|---|
| `licensee_id` | 1 | Migrate | |
| `pagination` | 2 | Migrate | |
| `filter` | 3 | Migrate | `console.rpc.BorrowerRelatedPartyFilter`, giữ tên field Console |
| `bitemporal_query` | 4 | Migrate | |
| `borrower_associates` (response) | 2 | Migrate | `console.entity.BorrowerAssociate` |
```

Cột "Xử lý" chỉ có: `Migrate`, `Removed (không phải entity chính)`, `Thêm (Hướng A)`, `Đổi thành optional (Hướng A)`. Field migrate có số khác Console vì đánh số lại → ghi cả số Console và số Core.

---

## 10. Lịch sử quyết định (để hiểu vì sao PR cũ khác quy tắc)

| Thời điểm | Thay đổi |
|---|---|
| 2026-07-30 | chunk_1 (JP): dùng lại type Console, giữ field_mask/bitemporal_query |
| trước 2026-09 | TEQ tạo core entity riêng, bỏ field_mask dead, đổi type (Money→int64, PhoneNumber→string, tách PostalAddress, YearMonth→Date) |
| 2026-09 (Misato) | Đảo ngược: cấu trúc/type/validate giữ như Console; field_mask/bitemporal_query/effective luôn giữ |
| 2026-09-24 | Idempotency ngoài phạm vi |
| 2026-09-25 | Dùng lại entity/filter Console như chunk_1, không tạo core entity |
| 2026-09-25 | Cho phép bổ sung `string.uuid` / `enum.defined_only` có kiểm chứng; BitemporalQuery/FieldMask refactor ngoài phạm vi |
| 2026-09-25 | Hướng A cho Core RPC trùng tên của minazuki |
| 2026-09-25 | `分割` / `分割レビュー` / RPC nhiều entity vẫn migrate, chỉ giữ entity chính; tách entity phụ là việc của RPC khác |
| 2026-09-25 | Field bị bỏ: xoá hẳn và đánh số lại, không dùng `reserved` |
| 2026-09-25 | Chỉ bỏ entity deprecated; field `deprecated = true` khác giữ nguyên như Console (dọn deprecated ngoài phạm vi) |

PR đã sửa theo quy tắc hiện tại bằng PR follow-up: #2256 → #2275, #2257 → #2276, #2263 → #2277, #2264 → #2278. Nhánh `feature/CRES-20669-core-api-borrower` (GetBorrowers, GetEmailSuppressions) và `feature/CRES-20678-core-api-product-tag` (GetProducts, GetTagAttachments) còn theo quy tắc cũ.
