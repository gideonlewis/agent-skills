# Quy ước viết proto cho Core RPC migrate

Mọi quy ước dưới đây rút ra từ chunk_1 và các quyết định trong `SKILL.md`. Trích dẫn file để đối chiếu.

---

## 0. Nguồn tham khảo duy nhất: chunk_1

| Loại | File Core | File Console gốc |
|---|---|---|
| Query | `proto/core/rpc/get_borrower_expatriations.proto` | `proto/console/rpc/get_borrower_expatriations.proto` |
| Write (Create) | `proto/core/rpc/create_role.proto` | `proto/console/rpc/create_role.proto` |

chunk_1 do haruki.nazawa làm (commit `39187a07525`, 2026-07-30). Misato bổ sung docs cho CreateRole sau đó (commit `cb540864a3`, PR #2200).

**Lấy từ chunk_1:**

- Import type Console: `console/entity/*`, `console/rpc/filter.proto`. Không tạo entity/filter bên Core.
- Field, số field, `optional`, type, tên field, validate của request/response giống Console, gồm cả `field_mask`, `bitemporal_query`.
- Response Create: ID có `(google.api.field_behavior) = REQUIRED` + `string.uuid`.

**Không lấy** (style chunk_1 chưa làm):

- Comment tiếng Anh → file mới viết tiếng Nhật (§1).
- Thiếu block JSON mẫu ở request Query → file mới phải có (§6).

**Không dùng làm mẫu** các Core RPC khác. Chúng dựng cho client khác, không phải migrate từ Console:

| Nhóm | RPC | Dựng cho |
|---|---|---|
| Partner phase 1 (02–03/2026) | `CreateBorrower`, `UpdateBorrower`, `Create/UpdateDraftContractApplication`, `SubmitContractApplication`, `InvalidateAndRerequestContractApplicationReview`, `GetCICInquiries`, `GetCICInquiryRequests`, `GetDocuments`, `IssuePresignedGetURLsForDocuments`, `Create/UpdateDraftContract`, `SignContract`, `GetContracts`/`GetContractApplications` (comment-out) | minazuki |
| Platform Console | `GetPlatformEnv`, `GetFeatureFlags`, `GetFeatureFlagOverrides` | Platform Console |
| Thẻ / clearing | `GetCreditCards`, `SubmitCreditCardIssuanceResult`, `CreateClearingUploadUrl`, `CompleteClearingFileUpload` | macaron-message-dispatcher |
| CIC file import (CRES-19905) | 4 RPC `*CreditInformation*` | Chuyển thẳng từ console/ sang core/ |

---

## 1. Ngôn ngữ comment

Skill viết tiếng Việt, **comment trong `.proto` viết tiếng Nhật**, kể cả dòng `rpc` trong `core_service.proto`. Không trộn 2 ngôn ngữ trong 1 comment.

```proto
// console/rpc/create_role.proto
// The role name.
string name = 2 [(buf.validate.field).required = true];

// core/rpc/create_role.proto (sau PR #2200)
// 作成するロール名
string name = 2 [(buf.validate.field).required = true];
```

`buf lint` (rule `COMMENTS`) chỉ bắt **có** comment, không bắt ngôn ngữ.

---

## 2. File, package, header

- File: `proto/core/rpc/<snake_case của tên RPC>.proto`, `package core.rpc;`. Tên file theo tên RPC, kể cả khi file Console lệch tên (Console `update_borrower_associates.proto` → Core `update_borrower_associate.proto`).
- Không tạo thư mục `v1` (`PACKAGE_VERSION_SUFFIX` đã miễn cho `core`).
- Thứ tự: `syntax` → dòng trống → `package` → dòng trống → import xếp alphabet (`buf format` tự sắp).
- Không `option go_package`, không `java_*`, không `google.api.http`.

---

## 3. Template Query (`1対1レビュー`)

Theo `get_borrower_expatriations.proto`. Số field **theo Console của từng RPC**, không cố định. Ví dụ dưới là chunk_1 (Console có `field_mask = 3`, `filter = 4`, `bitemporal_query = 5`).

```proto
syntax = "proto3";

package core.rpc;

import "buf/validate/validate.proto";
import "console/entity/borrower_expatriation.proto";
import "console/rpc/filter.proto";
import "cred_type/bitemporal/bitemporal_query.proto";
import "cred_type/filter/logical_operator.proto";
import "cred_type/pagination/pagination.proto";
import "google/protobuf/field_mask.proto";

// 海外転出・帰国に伴う居住状態変更の申請の検索リクエスト
//
// 借主IDと状態で検索するサンプル:
// {
//   "licenseeId": "spc",
//   "pagination": {
//     "pageSize": 100
//   },
//   "fieldMask": "",
//   "filter": {
//     "logicalOperator": "LOGICAL_OPERATOR_AND",
//     "borrowerExpatriationFilters": [
//       {
//         "borrowerId": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
//         "status": "BORROWER_EXPATRIATION_STATUS_SETTLED"
//       }
//     ]
//   }
// }
message GetBorrowerExpatriationsRequest {
  // Licensee ID
  string licensee_id = 1 [(buf.validate.field).required = true];

  // ページネーションリクエスト
  cred_type.pagination.TokenPaginationRequest pagination = 2 [(buf.validate.field).required = true];

  // レスポンスのフィールドマスク
  google.protobuf.FieldMask field_mask = 3 [(buf.validate.field).required = true];

  // 申請の検索条件
  optional GetBorrowerExpatriationsFilterCondition filter = 4;

  // 過去時点の申請を照会するための bitemporal クエリ
  optional cred_type.bitemporal.BitemporalQuery bitemporal_query = 5;
}

// 申請の検索条件
message GetBorrowerExpatriationsFilterCondition {
  // logical_operator は、ネストされた条件とフィールドの両方に使用する論理演算子です。
  cred_type.filter.LogicalOperator logical_operator = 1 [
    (buf.validate.field).required = true,
    (buf.validate.field).enum.defined_only = true
  ];

  // nested_conditions は、さらにネストされたフィルター条件のリストです。
  repeated GetBorrowerExpatriationsFilterCondition nested_conditions = 2;

  // borrower_expatriation_filters は、申請のフィルターです。
  repeated console.rpc.BorrowerExpatriationFilter borrower_expatriation_filters = 3;
}

// 申請の検索レスポンス
message GetBorrowerExpatriationsResponse {
  // ページネーションレスポンス
  cred_type.pagination.TokenPaginationResponse pagination = 1;

  // 申請
  repeated console.entity.BorrowerExpatriation borrower_expatriations = 2;
}
```

Bắt buộc:

- **Mọi field của Console đều có**, đúng tên, đúng type, đúng `optional`/`repeated`, đúng thứ tự, và đúng số khi không có field nào bị bỏ. Field `deprecated = true` (không phải entity) cũng giữ, kể cả option `[deprecated = true]`. Ngoại lệ duy nhất: field response không phải entity chính (side-load, entity khác, count) → xoá hẳn, **không `reserved`**, đánh số lại liên tục các field sau (`design-decisions.md §2–3`). Console không có `field_mask` thì Core cũng không có. Console đặt `pagination` ở response là số 2 thì Core cũng là số 2.
- **Validate giống Console**, cộng phần bổ sung được phép ở §7. Kể cả chỗ Console thiếu `required` (ví dụ `GetOperatorNotificationsRequest.licensee_id`) thì Core cũng không thêm.
- Có dòng trống giữa các field (file Console thường không có — không bắt chước).
- Type cùng file gọi tên trần; type Console gọi đủ `console.entity.<X>` / `console.rpc.<X>Filter`.

---

## 4. Template Write (`業務操作`)

### Create

Theo `create_role.proto`: request giống Console; response trả ID như Console, được thêm annotation:

```proto
// ロール作成レスポンス
message CreateRoleResponse {
  // 作成されたロールID
  string role_id = 1 [
    (google.api.field_behavior) = REQUIRED,
    (buf.validate.field).string.uuid = true
  ];
}
```

Rule ở response **không có hiệu lực lúc chạy** (azuki chỉ validate `req.Msg`, không có interceptor validate response). Tác dụng chỉ ở spec OpenAPI (`format: uuid`, `required: [roleId]`). Chỉ thêm cho ID mà azuki sinh bằng UUID.

### Update

Giữ shape Console. Ví dụ PR #2275:

```proto
// 借主関係者更新リクエスト
message UpdateBorrowerAssociateRequest {
  // Licensee ID
  string licensee_id = 1 [(buf.validate.field).required = true];

  // 更新対象フィールド
  google.protobuf.FieldMask field_mask = 2 [(buf.validate.field).required = true];

  // 更新対象の借主関係者
  console.entity.BorrowerAssociate borrower_associate = 3 [(buf.validate.field).required = true];

  // 変更を適用する有効期間
  //
  // 未指定の場合は現在時刻を開始時刻とし、終了時刻なしとして扱います。
  optional cred_type.bitemporal.TimeRange effective = 4;
}
```

Không tách payload `UpdateXxx`, không tách ID ra top-level (pattern `update_borrower.proto` là của minazuki). Field nào thực sự được cập nhật do `replacements<Entity>()` trong handler azuki quyết định, như bên Console.

### Delete / Submit / các Write khác

Giữ nguyên request/response Console, gồm cả `effective`, `optional console.entity.ReviewRequestParams review_request`, response rỗng `{}`.

---

## 5. Filter

RPC migrate **không thêm message vào `proto/core/rpc/filter.proto`**. `<Rpc>FilterCondition` (định nghĩa trong file RPC) tham chiếu thẳng filter Console, giữ **tên message và tên field Console**:

```proto
// chunk_1
repeated console.rpc.BorrowerExpatriationFilter borrower_expatriation_filters = 3;

// PR #2275 — tên field Console không theo convention, vẫn giữ
repeated console.rpc.BorrowerRelatedPartyFilter borrower_related_party_filter = 3;

// PR #2276 — Console gọi là notification_filters, không phải operator_notification_filters
repeated console.rpc.OperatorNotificationFilter notification_filters = 3;
```

`proto/core/rpc/filter.proto` chỉ chứa filter của các RPC dựng cho client khác. Ngoại lệ: mở rộng filter của RPC minazuki theo Hướng A (§10).

---

## 6. Block JSON mẫu (Query)

Mọi request message của RPC Query có block JSON mẫu trong comment. Quy tắc này từng bị quên ở 3 batch liền, kiểm tra lại trước khi coi là xong:

```bash
grep -L "サンプル" proto/core/rpc/get_*.proto
```

Mẫu phải:

- Pretty-print, key camelCase **theo đúng tên field Console** (`borrowerRelatedPartyFilter`, `notificationFilters`).
- `licenseeId` là `"spc"`.
- Có mặt mọi field `required`. `field_mask` ghi `"fieldMask": ""` (JSON của FieldMask là chuỗi path nối bằng dấu phẩy).
- `pageSize` trong 1–100.
- Enum dùng giá trị đã định nghĩa, không dùng `*_UNSPECIFIED`.
- ID là UUID hợp lệ (bảng §8).

Mẫu nằm trong comment message (hiện ra ở description của schema trong OpenAPI). Không dùng `gnostic.openapi.v3.operation` cho Query.

---

## 7. Validate

**Mặc định giữ y hệt Console.** Không bớt rule nào. Không thêm validate nghiệp vụ hay phụ thuộc nhiều field (giới hạn số tiền, "bắt buộc khi field khác là X"...): Kaz Togo muốn logic đó nằm ở validator phía fsm vì business có thể đổi.

**Ngoại lệ được phép** (Le, Yuya Sakano, Misato Kano, Kaz Togo, Mattermost 2026-09-25): chỉ 2 rule, cho field Console bị sót:

| Rule | Áp cho |
|---|---|
| `(buf.validate.field).string.uuid = true` | Field ID mà handler azuki parse bằng `uuid.Parse` / `uuid.MustParse` |
| `(buf.validate.field).enum.defined_only = true` | Field enum |

Không mở rộng sang `email`, `uri`, `min_len`, `gte`... khi chưa hỏi user.

### Phân loại field trước khi thêm

azuki dùng `buf.build/go/protovalidate` v1.3.0. Field proto3 **không có presence** (`string` thường) vẫn bị áp rule khi để trống, nên `string.uuid` từ chối `""`. Đây là rủi ro Sakano-san nêu.

| Kiểu field Console | Thêm được không |
|---|---|
| Đã `required = true` | Được. `""` vốn đã bị từ chối |
| `optional string` | Được. Không gửi thì bỏ qua |
| `repeated string` → `repeated.items.string.uuid` | Được. Danh sách rỗng không ảnh hưởng |
| Enum bất kỳ → `enum.defined_only` | Được. `*_UNSPECIFIED = 0` là giá trị đã định nghĩa, rule chỉ chặn số lạ |
| `string` thường, không `required`, không `optional` | **Không tự thêm.** Handler thường kiểm tra `!= ""` cho loại này (ví dụ `GetCreditInformationCICSummaryRequest.contract_application_id`), tức FE có gửi rỗng. Ghi vào PR |

**Chỉ thêm vào message thuộc `core.rpc`.** Field nằm trong type Console dùng lại (`console.entity.BorrowerAssociate.id`, `console.entity.OperatorReviewFlowUpdate.review_flow_id`...) thì không thêm được (sửa là sửa Console) → chỉ ghi vào PR.

`licensee_id` không phải UUID (`"spc"`), không thuộc ngoại lệ này.

### Kiểm chứng bắt buộc cho mỗi rule

Điều kiện JP đặt ra (Misato: "một lần sai là breaking change"; Togo: "đối chiếu với code FE là xác định được"):

1. azuki: handler Console xử lý field thế nào.

   ```bash
   grep -n "Get<FieldCamel>()" azuki/internal/presentation/console_api_presentation/internal/<snake_case_rpc>/handler.go
   ```

2. azuki-app: tìm chỗ gọi RPC, xác nhận giá trị gửi lên luôn hợp lệ (ID lấy từ response hoặc route param; enum lấy từ hằng số generate; không phải input tự do, không có nhánh gửi rỗng).

   ```bash
   grep -rn "<rpcNameCamelCase>\|<RpcName>Request" azuki-app/src
   ```

3. Không chắc → không thêm, ghi vào mục cần confirm của PR.

Liệt kê mọi rule đã thêm kèm kết quả kiểm chứng trong mục `## Validation added on top of Console` của migration report (`migration-report.md`); skill tạo PR chép sang PR description.

Ví dụ đã được JP xem:

```proto
// UpdateRoleRequest.role_id — Console đã required
string role_id = 2 [
  (buf.validate.field).required = true,
  (buf.validate.field).string.uuid = true
];

// SubmitBorrowerSuspensionDecisionRequest.result — enum
console.entity.BorrowerSuspensionDecisionResult result = 3 [
  (buf.validate.field).required = true,
  (buf.validate.field).enum.defined_only = true
];
```

---

## 8. Annotation tuỳ chọn và giá trị mẫu

- `(gnostic.openapi.v3.property) = { example: {yaml: "..."} }`: tuỳ chọn cho field request (CreateRole có, do PR #2200). Không bắt buộc.
- `(google.api.field_behavior) = REQUIRED`: chỉ cho ID trong response Create (§4).

Giá trị mẫu dùng thống nhất:

| Loại | Giá trị |
|---|---|
| licensee id | `spc` |
| borrower id | `6ba7b810-9dad-11d1-80b4-00c04fd430c8` |
| product id | `550e8400-e29b-41d4-a716-446655440000` |
| contract id | `f47ac10b-58cc-4372-a567-0e02b2c3d479` |
| contract application id | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` |
| id khác | `019bbb7d-06fa-70e6-9800-8b8f29b30e4c` |

---

## 9. Đăng ký vào `core_service.proto`

> **Không áp dụng mục này vào file `core_service.proto` trong PR proto lẻ.** Từ giờ đăng ký RPC dồn theo lô, ở 1 PR riêng, để tránh nhiều PR cùng sửa file này gây conflict lúc review/merge. Mục này chỉ dùng để biết viết đúng import/dòng `rpc` (ghi vào migration report, mục "Registration (pending)") cho PR batch sau chép lại — xem "Đăng Ký `core_service.proto`" trong SKILL.md chính.

- Một import cho mỗi file RPC, xếp alphabet.
- Dòng `rpc` đặt cạnh cụm RPC cùng domain; domain mới thì thêm cuối `CoreService`. Không sắp xếp lại RPC có sẵn.
- Tham chiếu type fully qualified (`core.rpc.GetXxxRequest`).
- Comment: `// <TênRPC> <mô tả tiếng Nhật>`, chi tiết thì thêm dòng `//` trống rồi gạch đầu dòng `- `:

  ```proto
  // SendBorrowerIndividualEmail 借主へ個別メールを送信する
  //
  // - オペレーターが特定の借主宛に個別メールを送信します。
  // - 送信結果は対応履歴として記録されます。
  rpc SendBorrowerIndividualEmail(core.rpc.SendBorrowerIndividualEmailRequest) returns (core.rpc.SendBorrowerIndividualEmailResponse);
  ```

### PUBLIC và `gnostic.openapi.v3.operation`

Chỉ 4 RPC có (`CreateBorrower`, `CreateDraftContractApplication`, `CreateDraftContract`, `CreateRole`), do PR docs của Misato ngày 2026-08-25.

- `option (google.api.method_visibility).restriction = "PUBLIC"` **không lọc gì**: RPC không gắn nhãn vẫn có trong spec OpenAPI đã publish (tag `v1.167.0-openapi` có `GetBorrowerExpatriations`). azuki không đọc nhãn này.
- **Không tự gắn** cho RPC mới trừ khi user yêu cầu.
- Khi xem diff `dist/openapi`, tin bản CI hoặc tag `*-openapi`; bản sinh local có lúc lệch.

### Comment-out

RPC chưa ship thì comment cả import lẫn dòng `rpc`, kèm `// NOTE: <lý do>`. Khi kiểm tra "Core RPC đã có chưa" phải nhìn cả phần comment-out.

---

## 10. Hướng A: mở rộng Core RPC đã có cho minazuki

Áp dụng khi Console RPC trùng tên với Core RPC đang chạy cho minazuki. Quy trình đầy đủ (phân loại đang chạy / chưa ship, ghép field theo tên, chỗ phải dừng hỏi, bảng đối chiếu hiện tại): `existing-core-rpcs.md`. Hiện chỉ `GetDocuments` thuộc diện này; `GetContracts` / `GetContractApplications` chưa ship nên phải hỏi trước.

- Giữ nguyên mọi field đang có (số, type, tên), kể cả type response `core.entity.<X>`.
- Thêm field ở số chưa dùng, lớn hơn số lớn nhất hiện có. Không lấp vào số `reserved`.
- Field Console bắt buộc → `optional` bên Core, không `required`.
- `field_mask` → `google.protobuf.FieldMask field_mask = <số mới>;` không `required`.
- Filter còn thiếu field → thêm vào `core.rpc.<X>Filter` hiện có trong `filter.proto`, `optional`, validate như Console (+ §7).
- Enum Core thiếu giá trị → thêm giá trị với **đúng số của enum Console**. Nếu số đó đang `reserved` với comment `標準実装との整合性確保用` → dừng hỏi (phải thêm vào baseline chuẩn trước).
- Entity có `reserved ... // 標準実装との整合性確保用` → dừng hỏi trước khi thêm field.

Ví dụ phần request `GetDocuments` (minh hoạ cách đặt số, chưa phải thiết kế đã duyệt):

```proto
message GetDocumentsRequest {
  // Licensee ID
  string licensee_id = 1 [(buf.validate.field).required = true];

  // ページネーションリクエスト
  cred_type.pagination.TokenPaginationRequest pagination = 2 [(buf.validate.field).required = true];

  // 書類の検索条件
  optional GetDocumentsFilterCondition filter = 3;

  // レスポンスのフィールドマスク（Console 移行のため追加。minazuki は送信しないため required にしない）
  google.protobuf.FieldMask field_mask = 4;

  // 過去時点の書類を照会するための bitemporal クエリ（Console 移行のため追加）
  optional cred_type.bitemporal.BitemporalQuery bitemporal_query = 5;
}
```

---

## 11. Kiểm tra field khớp Console

Chạy cho từng RPC trước khi commit. Lệnh so label, type, tên của mọi field (bỏ tiền tố package và số field, sắp xếp để không phụ thuộc thứ tự message). Không so số vì field sau field bị bỏ được đánh số lại:

```bash
cmp_fields() {  # $1 = file Console, $2 = file Core — so label + type + tên (không so số)
  norm() { grep -oE '^\s+(optional |repeated )?[a-zA-Z0-9_.<>, ]+ [a-z_0-9]+ = [0-9]+' "$1" \
    | sed -E 's/^\s+//; s/ = [0-9]+$//; s/(console\.)?(entity|rpc)\.//g; s/core\.rpc\.//g' | sort; }
  diff <(norm "$1") <(norm "$2") && echo "fields match"
}
cmp_fields proto/console/rpc/update_borrower_associates.proto proto/core/rpc/update_borrower_associate.proto
```

Kết quả hợp lệ: `fields match`, hoặc chỉ còn chênh lệch thuộc "Quyết định đã chốt" (field response bị xoá vì không phải entity chính; field thêm theo Hướng A). Field deprecated bị thiếu trong Core là **sai** — phải giữ. **Số field** kiểm tra riêng bằng mắt: không có field nào bị bỏ thì số phải giống Console; có field bị bỏ thì các field sau đánh số liên tục, giữ thứ tự Console. Validate không nằm trên cùng dòng khai báo field nên lệnh này không bắt được — so validate bằng mắt với file Console.

---

## 12. Buf lint — rule dễ vướng

`proto/buf.yaml` bật `DEFAULT` + `COMMENTS`.

- `COMMENTS`: mọi file, message, field, enum, giá trị enum, service, rpc phải có comment.
- `RPC_REQUEST_STANDARD_NAME` / `RPC_RESPONSE_STANDARD_NAME` / `RPC_REQUEST_RESPONSE_UNIQUE`: mỗi rpc có `<Rpc>Request` / `<Rpc>Response` riêng, cùng package. Không dùng lại message của rpc khác, không dùng `google.protobuf.Empty`.
- `PACKAGE_DIRECTORY_MATCH`, `FILE_LOWER_SNAKE_CASE`, `ENUM_VALUE_PREFIX`, `ENUM_ZERO_VALUE_SUFFIX`.
- `breaking: use: [FILE]`: đổi số/type field đã release sẽ bị chặn — liên quan trực tiếp tới Hướng A.
- Xoá file `proto/core/entity/<x>.proto` thì xoá luôn dòng import của nó trong `filter.proto` (và mọi file khác), nếu không `buf lint` báo `imported file does not exist` (đã gặp ở PR #2278).
