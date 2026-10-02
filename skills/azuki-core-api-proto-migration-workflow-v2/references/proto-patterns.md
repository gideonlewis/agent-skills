# Proto patterns — Core RPC migrate (v2)

Mẫu viết proto theo bảng "Quyết Định Đã Chốt" trong `SKILL.md`. Mẫu lấy từ PR đã được JP approve: #2287 + #2351 (Borrower), #2288 (EmailSuppression), #2291 ← #2289/#2290 (Review cluster A), #2297 ← #2296/#2298 (Review cluster B), #2292–#2295.

Mọi ví dụ dưới đây: comment tiếng Nhật cho phần viết mới; comment copy từ Console giữ nguyên.

---

## 1. File, package

- RPC: `proto/core/rpc/<snake_case_rpc>.proto`, `package core.rpc;`.
- Entity: `proto/core/entity/<domain>.proto`, `package core.entity;`. Tên file theo file Console tương ứng (`console/entity/review_flow.proto` → `core/entity/review_flow.proto`).
- Type cùng package gọi tên trần hoặc đủ `core.entity.X` / `core.rpc.X`; không còn `console.` nào.
- Có dòng trống giữa các field.

---

## 2. Template Query (`1対1レビュー`)

Số field theo Console của từng RPC. Ví dụ `GetReviews` (#2297):

```proto
syntax = "proto3";

package core.rpc;

import "buf/validate/validate.proto";
import "core/entity/review.proto";
import "core/rpc/filter.proto";
import "cred_type/bitemporal/bitemporal_query.proto";
import "cred_type/filter/logical_operator.proto";
import "cred_type/pagination/pagination.proto";
import "google/protobuf/field_mask.proto";

// 再鑑の検索リクエスト
//
// 特定の再鑑を検索するサンプル:
// {
//   "licenseeId": "spc",
//   "pagination": {
//     "pageSize": 10
//   },
//   "fieldMask": {
//     "paths": ["id", "result"]
//   },
//   "filter": {
//     "logicalOperator": "LOGICAL_OPERATOR_AND",
//     "reviewFilters": [
//       { "reviewRequestId": "6ba7b810-9dad-11d1-80b4-00c04fd430c8" }
//     ]
//   }
// }
message GetReviewsRequest {
  // Licensee ID
  string licensee_id = 1 [(buf.validate.field).required = true];

  // ページネーションリクエスト
  cred_type.pagination.TokenPaginationRequest pagination = 2 [(buf.validate.field).required = true];

  // フィールドマスク
  google.protobuf.FieldMask field_mask = 3 [(buf.validate.field).required = true];

  // 再鑑の検索条件
  optional GetReviewsFilterCondition filter = 4;

  // 過去時点の再鑑を照会するための bitemporal クエリ
  optional cred_type.bitemporal.BitemporalQuery bitemporal_query = 5;
}

// 再鑑の検索条件
message GetReviewsFilterCondition {
  // logical_operator は、ネストされた条件とフィールドの両方に使用する論理演算子です。
  cred_type.filter.LogicalOperator logical_operator = 1 [
    (buf.validate.field).required = true,
    (buf.validate.field).enum.defined_only = true
  ];

  // nested_conditions は、さらにネストされたフィルター条件のリストです。
  repeated GetReviewsFilterCondition nested_conditions = 2;

  // review_filters は、再鑑のフィルターです。
  repeated core.rpc.ReviewFilter review_filters = 3;
}

// 再鑑の検索レスポンス
message GetReviewsResponse {
  // ページネーションレスポンス
  cred_type.pagination.TokenPaginationResponse pagination = 1;

  // 再鑑
  repeated core.entity.Review reviews = 2;
}
```

- Console không có `pagination` / `field_mask` (ví dụ `GetReviewFlowSteps`, `GetReviewSubjectSettings`) → Core cũng không có.
- Tên field filter giữ tên Console, kể cả không theo convention (`borrower_related_party_filter`).
- Side-load trong response Console (`map<string, X> ... [deprecated = true]`) → xoá (quyết định #7).

---

## 3. Template Write (`業務操作`)

### Create / Submit

Request, response giữ Console. Tham số tạo 再鑑申請 dùng `core.entity.ReviewRequestParams` (trong `core/entity/review_request.proto`):

```proto
// 再鑑申請パラメータ。指定すると再鑑申請が作成される
optional core.entity.ReviewRequestParams review_request = 5;
```

Response ID chỉ thêm annotation khi đã đọc handler (quyết định #6):

```proto
// 再鑑提出レスポンス
message SubmitReviewResponse {
  // 作成された再鑑ID
  string review_id = 1 [
    (buf.validate.field).string.uuid = true,
    (google.api.field_behavior) = REQUIRED
  ];
}
```

Kiểm chứng:

```bash
cat azuki/internal/presentation/console_api_presentation/internal/<snake_case_rpc>/handler.go
# tìm chỗ build response: field phải được gán ở MỌI nhánh return thành công.
# Handler không gán, hoặc scenario không trả giá trị đó ra (ví dụ SubmitBorrowerWithdrawalDecision:
# scenario tạo decision ID nhưng chỉ return review request ID) → không thêm, ghi vào PR để JP confirm.
```

Rule ở response không chạy lúc runtime (azuki chỉ validate `req.Msg`); tác dụng ở spec OpenAPI.

### Update

Giữ shape Console: `field_mask` + cả entity + `effective`. Không tách payload `UpdateXxx`.

```proto
// 借主関係者更新リクエスト
message UpdateBorrowerAssociateRequest {
  // Licensee ID
  string licensee_id = 1 [(buf.validate.field).required = true];

  // 更新対象フィールド
  google.protobuf.FieldMask field_mask = 2 [(buf.validate.field).required = true];

  // 更新対象の借主関係者
  core.entity.BorrowerAssociate borrower_associate = 3 [(buf.validate.field).required = true];

  // 変更を適用する有効期間
  optional cred_type.bitemporal.TimeRange effective = 4;
}
```

### Message cục bộ của RPC

Console định nghĩa message chỉ dùng trong request (ví dụ `console.rpc.ReviewFlowStep` trong `create_review_flow.proto`, được `update_review_flow.proto` import lại) → Core định nghĩa trong `core.rpc` ở file tương ứng, RPC kia import file đó và **stack PR** (quyết định #10). Không đưa sang `core.entity` (trùng tên với entity `ReviewFlowStep` đầy đủ).

---

## 4. Entity Core mới

Mirror message Console: đủ field, cùng tên, cùng type (quyết định #2), cùng `optional`/`repeated`, cùng validate, comment Console giữ nguyên (kể cả dòng `TODO:`).

Đánh số: liên tục 1..N theo thứ tự field Console. Console có `reserved` hoặc khoảng trống (ví dụ `console.entity.Borrower` có `reserved 30`, bỏ trống 16, 37, 38) → Core đánh lại liên tục, không `reserved`. Console liên tục → trùng số.

Enum: giữ nguyên giá trị, số, khoảng trống và `reserved`:

```proto
enum ReviewSubject {
  // ...
  // お知らせ配信
  REVIEW_SUBJECT_ANNOUNCEMENT = 39;

  reserved 40;
  reserved "REVIEW_SUBJECT_AI_OPERATOR_REGISTRATION";

  // 和解契約登録
  REVIEW_SUBJECT_SETTLEMENT_AGREEMENT_TERMS_DECISION = 41;
}
```

Enum/message cục bộ của entity Console (ví dụ `YearMonth` trong `borrower_profile.proto`, `Sex` trong `borrower.proto`) → định nghĩa cùng file entity Core.

---

## 5. File chỉ chứa enum (domain chưa có Core RPC)

Filter cần enum của domain khác mà Core chưa có (quyết định #4):

```proto
syntax = "proto3";

package core.entity;

// 保証会社
//
// Guarantee Assessment ドメインの Core RPC が未実装のため、
// Borrower のフィルターで参照する enum のみ定義する。
enum GuaranteeProvider {
  // Unspecified
  GUARANTEE_PROVIDER_UNSPECIFIED = 0;
  // SMBCCF
  GUARANTEE_PROVIDER_SMBCCF = 1;
  // QUANTS
  GUARANTEE_PROVIDER_QUANTS = 2;
}
```

Ví dụ đã merge: `tag_attachment.proto` (`CoreSystemTag`, `TagAttachmentSubject`), `borrower_identity_verification.proto`, `guarantee_assessment_result.proto`, `employment_verification_request.proto`.

Khi RPC của domain đó migrate sau này → append message entity vào đúng file, xoá dòng comment "enum のみ定義する".

Tạm định nghĩa enum trước message (vì filter của PR gốc cần, entity đầy đủ ở PR stack) — dùng comment:

```proto
// GetReviewFlowSteps (別PR) が ReviewFlowStep entity を追加するまでの間、
// ReviewFlowStepFilter が参照する enum のみ先に定義する。
```

---

## 6. Kiểm tra trước khi tạo / append

```bash
ls proto/core/entity/<domain>.proto                          # file đã có chưa
git grep -n "^message <X> \|^enum <X> " origin/master -- proto/core/   # type đã có ở đâu chưa
git show origin/master:proto/core/entity/<domain>.proto      # đọc nội dung hiện có trước khi sửa
```

- File có sẵn → Edit/append, **không Write đè**. Ca thật: tạo `contract_application.proto` bằng Write đã xoá mất `message ContractApplication` (của `GetContractApplications` đang comment-out) → `buf lint` báo `cannot find core.entity.ContractApplication`; khôi phục bằng `git show origin/master:<path> > <path>` rồi append.
- Type có sẵn → import (ví dụ `BorrowerStatus`, `ContractApplicationStatus`, `CICInquiryStatus`, `CoreDocumentKey` đã có — #2350 import đúng).

---

## 7. Filter

Mirror đủ field của `console.rpc.<X>Filter`, cùng tên, cùng validate. Đánh số liên tục theo thứ tự Console. `oneof` giữ nguyên là `oneof` (cùng tên oneof, kể cả chỉ 1 field), không đổi thành `optional`: kiểu sinh ra khác nhau (Go interface vs con trỏ, TS `{ case, value }` vs `?:`) nên code azuki / FE sẽ khác Console.

```proto
// 借主関係者のフィルター
message BorrowerRelatedPartyFilter {
  // 借主関係者ID（完全一致）
  optional string borrower_associate_id = 1 [(buf.validate.field).string.uuid = true];

  // 借主ID（完全一致）
  optional string borrower_id = 2 [(buf.validate.field).string.uuid = true];

  // メールアドレス（完全一致）
  optional string email_address = 3 [(buf.validate.field).string.email = true];

  // 電話番号（完全一致）
  optional string phone_number = 4;
}
```

- Append cuối file; import `core/entity/*` mới xếp alphabet.
- Nhiều PR cùng thêm filter → conflict ở cuối file. Dồn vào PR gốc (quyết định #10); nếu vẫn conflict khi rebase → giữ cả 2 khối.
- Filter cho RPC mới không có Console tương ứng (ví dụ `EmailSuppressionFilter` của `GetEmailSuppressions`) → thiết kế theo field mà query azuki hỗ trợ (`internal/module/<module>/entity/<x>_query.go`), ghi rõ trong PR để JP confirm.

---

## 8. Console RPC trùng tên Core RPC đã có

Kiểm tra trước:

```bash
grep -n "rpc <RpcName>(" proto/core/rpc/core_service.proto          # rpc có bật không
ls azuki/internal/presentation/core_api_presentation/internal/ | grep <snake_case>   # có handler không
```

| Loại | Dấu hiệu | Cách làm |
|---|---|---|
| Đang chạy cho minazuki | rpc bật + có handler (`GetDocuments`) | **Hướng A**: giữ entity Core, chỉ thêm field Console cần ở số mới, `optional`, bỏ `required`; `field_mask` thêm vào không `required`. Không đổi số/type/tên field đang có. Field trùng số `reserved ... // 標準実装との整合性確保用` → dừng hỏi. |
| Chưa ship | rpc comment-out `// NOTE: minazuki提供時には...` (`GetContracts`, `GetContractApplications`) | **Dừng hỏi user** chọn Hướng A (thêm field) hay viết lại theo Console (breaking, cần `release:major` hoặc JP chấp nhận). Bật dòng `rpc` là quyết định riêng. |

Hướng A trước đây cho phép import `console/entity/*` cho field mới. Theo quyết định #1, type mới cần định nghĩa ở `core.entity` — chưa có PR thật nào áp dụng Hướng A theo v2, nên xác nhận với user trước khi làm.

PR Hướng A luôn có: bảng field cả số Console lẫn số Core, danh sách field required bên Console thành `optional`, câu hỏi "field thêm vào response cũng trả cho minazuki — có chấp nhận không".

---

## 9. Validate

Mặc định y hệt Console, không bớt rule. Ngoại lệ duy nhất (JP 2026-09-25) cho field Console bị sót:

| Rule | Áp cho | Điều kiện |
|---|---|---|
| `string.uuid` | Field ID azuki parse bằng `uuid.Parse` | Field `required`, `optional`, hoặc `repeated` (dùng `repeated.items.string.uuid`) |
| `enum.defined_only` | Field enum | Luôn được |

- `string` thường (không `required`, không `optional`) → **không thêm** `string.uuid`: protovalidate v1.3.0 từ chối `""`, FE có thể đang gửi rỗng.
- Không thêm `required` Console không có (ví dụ `SubmitBorrowerWithdrawalDecisionRequest.licensee_id` Console không `required` → Core cũng không, dù 3 RPC cùng cụm có).
- Không thêm `email`, `min_len`, `gte`, CEL... khi chưa hỏi user.
- Kiểm chứng mỗi rule: `grep -n "Get<FieldCamel>()" azuki/internal/presentation/console_api_presentation/internal/<rpc>/handler.go` và `grep -rn "<RpcName>Request" azuki-app/src`. Không chắc → không thêm.

---

## 10. So field với Console

```bash
cmp_fields() {  # $1 = file Console, $2 = file Core — so label + type + tên (không so số)
  norm() { grep -oE '^\s+(optional |repeated )?[a-zA-Z0-9_.<>, ]+ [a-z_0-9]+ = [0-9]+' "$1" \
    | sed -E 's/^\s+//; s/ = [0-9]+$//; s/(console|core)\.(entity|rpc)\.//g' | sort; }
  diff <(norm "$1") <(norm "$2") && echo "fields match"
}
cmp_fields proto/console/rpc/<console>.proto proto/core/rpc/<core>.proto
cmp_fields proto/console/entity/<x>.proto proto/core/entity/<x>.proto
```

Chênh lệch hợp lệ duy nhất: side-load bị xoá. Số field kiểm tra riêng theo quyết định #3; `oneof` kiểm tra riêng bằng `grep -n "oneof" <file Console> <file Core>` (số lượng và tên oneof phải khớp).

---

## 11. `core_service.proto` (chỉ PR đăng ký lô)

- Một import mỗi file RPC, xếp alphabet.
- Dòng `rpc` cạnh cụm cùng domain (borrower cạnh `UpdateBorrower` / `SubmitBorrower*`); domain mới → cuối `CoreService`. Không sắp xếp lại rpc có sẵn.
- Comment `// <RpcName> <mô tả tiếng Nhật>`.
- Không tự gắn `option (google.api.method_visibility).restriction = "PUBLIC"`.
- Chỉ đăng ký file đã có trên `master`; đăng ký file chưa merge → `imported file does not exist`.

---

## 12. Buf lint — rule dễ vướng

- `COMMENTS`: mọi file, message, field, enum, giá trị enum, rpc phải có comment.
- `RPC_REQUEST_STANDARD_NAME` / `RPC_RESPONSE_STANDARD_NAME`: mỗi rpc có `<Rpc>Request` / `<Rpc>Response` riêng.
- `ENUM_VALUE_PREFIX`, `ENUM_ZERO_VALUE_SUFFIX`: enum Core copy từ Console thường đã đúng.
- Import không dùng (ví dụ bỏ field `Money` nhưng còn `google/type/money.proto`) → lỗi; thiếu import → `cannot find ... in this scope`.
- Xoá file entity → xoá mọi dòng import của nó.
