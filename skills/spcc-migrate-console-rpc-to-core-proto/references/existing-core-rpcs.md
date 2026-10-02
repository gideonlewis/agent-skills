# Console RPC trùng tên với Core RPC đã có (không phải chunk_1)

Áp dụng khi Console RPC cần migrate đã có Core RPC cùng tên trong `proto/core/rpc/`, dựng trước đợt migrate cho client khác (thường là minazuki). Ví dụ trên `master` (2026-09-25): `GetDocuments`, `GetContracts`, `GetContractApplications`.

Nguyên tắc chung: **không tạo RPC thứ hai, không đổi tên để né.** Trong `CoreService` mỗi tên là duy nhất.

---

## 1. Phân loại trước: RPC Core đó có đang chạy thật không

Dữ kiện ở tin nhắn Mattermost ("already built and currently in use for minazuki") **chỉ đúng với `GetDocuments`**. `GetContracts` / `GetContractApplications` có proto nhưng chưa từng chạy. Luôn kiểm tra lại:

```bash
# rpc có đang bật trong CoreService không
grep -n "rpc <RpcName>(" proto/core/rpc/core_service.proto
# azuki có handler Core không
ls azuki/internal/presentation/core_api_presentation/internal/ | grep <snake_case>
# entity Core còn được RPC nào khác dùng không
git grep -n "core.entity.<Entity>\b" -- proto/core
```

| Loại | Dấu hiệu | Ví dụ | Cách làm |
|---|---|---|---|
| **(a) Đang chạy** | rpc bật trong `CoreService` và azuki có handler | `GetDocuments` | Hướng A (§2) |
| **(b) Chưa ship** | rpc (và import) đang comment-out `// NOTE: minazuki提供時には...`, azuki không có handler, entity Core chỉ RPC này dùng | `GetContracts`, `GetContractApplications` | **Dừng hỏi user** (§3) |

---

## 2. Hướng A — RPC đang chạy cho minazuki

Duyệt bởi hirose.hikaru (Mattermost 2026-09-25): field của nhóm update bên minazuki hầu hết optional, validate nghiệp vụ ở validator phía fsm, nên hướng này không ảnh hưởng minazuki. Đây là ngoại lệ duy nhất của quy tắc "dùng lại type Console".

### Bước 1: Lập bảng đối chiếu

Dump field của từng message cần so (request, `<Rpc>FilterCondition`, filter của entity chính, response, entity, enum dùng trong entity/filter):

```bash
fields() { git show origin/master:"$1" | awk "/^message $2 \{/,/^\}/" \
  | grep -oE '^\s+(optional |repeated )?[a-zA-Z0-9_.<>, ]+ [a-z_0-9]+ = [0-9]+( \[deprecated = true\])?|^\s+reserved [^;]+' \
  | sed -E 's/^\s+//'; }
paste -d'|' <(fields proto/console/entity/document.proto Document) \
            <(fields proto/core/entity/document.proto Document) | column -t -s'|'
```

Enum: đếm giá trị và xem `reserved`:

```bash
git show origin/master:proto/core/entity/document.proto | awk '/^enum CoreDocumentKey \{/,/^\}/'
```

### Bước 2: Ghép field theo tên, không theo số

Cùng số khác nghĩa là chuyện thường ở nhóm này (ví dụ `ContractFilter` field 2: Console `borrower_id`, Core `product_id`).

| Kết quả ghép | Xử lý |
|---|---|
| Có ở cả 2, cùng type | `Existing` — giữ nguyên số Core |
| Có ở cả 2, khác type | **Dừng hỏi** |
| Chỉ Console có, không deprecated | `Added` — thêm vào Core (bước 3) |
| Chỉ Console có, deprecated | Không thêm (Hướng A chỉ thêm field Console cần; field deprecated không cần), liệt kê trong report |
| Chỉ Core có | Giữ nguyên, không xoá |
| Field response không phải entity chính (side-load, count) | Không thêm (quyết định #8) |

### Bước 3: Thêm field

- **Số mới**: sau số lớn nhất hiện có trong message. Không dùng lại số `reserved`.
- **Type**: đúng type Console. Enum/message chỉ có ở Console thì import `console/entity/*` (file `core.entity` được phép import `console.entity`), ví dụ `optional console.entity.ContractStatus status = 10;`.
- **Presence**: field mới của request/filter/entity khai báo `optional` (scalar, enum) hoặc để message/`repeated` như Console. Field Console có `required = true` → bỏ `required` bên Core.
- `field_mask` → `google.protobuf.FieldMask field_mask = <số mới>;` **không `required`** (minazuki không gửi, `required` sẽ làm mọi request của minazuki lỗi).
- `bitemporal_query` → `optional cred_type.bitemporal.BitemporalQuery bitemporal_query = <số mới>;`.
- **Filter của entity khác** trong `FilterCondition` Console (ví dụ `GetContractApplications` có `contract_application_approval_filters`, `product_filters`, `borrower_filters`) → thêm `repeated console.rpc.<X>Filter <tên Console> = <số mới>;`.
- **Validate**: chép rule Console của field đó (trừ `required`), cộng `string.uuid` / `enum.defined_only` theo `proto-authoring-rules.md §7`. Field mới là `optional` nên thêm `string.uuid` an toàn.

### Bước 4: Chỗ phải dừng hỏi

- Field cần thêm trùng số đang `reserved ... // 標準実装との整合性確保用` trong entity/enum Core. Comment đó nghĩa là số field phải khớp một baseline dùng chung nhiều sản phẩm: "thêm vào baseline chuẩn trước, dùng cùng ID". Không tự bỏ `reserved`.
- Enum Core thiếu giá trị mà Console có (số nằm trong khoảng `reserved`).
- Field cùng tên khác type.

### Bước 5: PR

Ghi vào migration report (`Mode: extend`); skill `spcc-core-api-migration-pr` dùng template "extending an existing Core RPC". Luôn có:

- Bảng đối chiếu có cả số Console lẫn số Core.
- Danh sách field required bên Console đã thành `optional` bên Core.
- Câu hỏi: field thêm vào response entity cũng trả cho minazuki — có chấp nhận không (hirose-san mới trả lời phần request/update).
- Ảnh hưởng FE: FE nhận `core.entity.<X>` chứ không phải `console.entity.<X>`. Tên field JSON phần lớn giống, nhưng type TS khác (enum Core khác enum Console), nên FE cần lớp chuyển đổi.

`core_service.proto` không đổi (rpc đã có).

---

## 3. RPC chưa ship (rpc comment-out) — dừng hỏi user

`GetContracts` / `GetContractApplications` có proto (`get_contracts.proto`, `get_contract_applications.proto`, entity `core/entity/contract.proto`, `contract_application.proto`) nhưng:

- import và dòng `rpc` trong `core_service.proto` đang comment-out (`// NOTE: minazuki提供時にはこのAPIは提供されないためコメントアウト`)
- azuki không có handler trong `core_api_presentation`
- `core.entity.Contract` / `ContractApplication` không được Core RPC nào khác dùng

Không có client nào chạy thật, nhưng proto đã nằm trong các bản release (sinh code Go/TS). Có 2 hướng, **user/JP quyết**:

| Hướng | Cách làm | Được | Mất |
|---|---|---|---|
| **A** (như §2) | Giữ `core.entity.*`, chỉ thêm field | `release:minor`, không đụng file đã release | Số field khác Console; FE phải chuyển đổi `core.entity` ↔ `console.entity`; entity Core của minazuki được mở rộng cho Console dù minazuki không dùng |
| **B** (như RPC migrate thường) | Viết lại request/response theo Console, dùng `console.entity.Contract` / `ContractApplication` như chunk_1 | Giống hệt Console, FE chỉ đổi service | Đổi type/số field của message đã release → breaking (`buf breaking` FILE); cần label `release:major` hoặc JP xác nhận chấp nhận; entity `core.entity.Contract` / `ContractApplication` thành không dùng |

Dù chọn hướng nào, việc **bật dòng `rpc`** (bỏ comment) cũng là một quyết định riêng: rpc sẽ xuất hiện trong `CoreService` cho mọi caller có quyền. Ghi vào PR.

Chưa có quyết định → dừng, báo lại bảng trên.

---

## 4. Bảng đối chiếu hiện tại (master, 2026-09-25)

### `GetDocuments` — loại (a), Hướng A

| Message | Console | Core hiện có | Cần làm |
|---|---|---|---|
| Request | `licensee_id=1`, `pagination=2`, `field_mask=3` (required), `filter=4`, `bitemporal_query=5` | `licensee_id=1`, `pagination=2`, `filter=3` | Thêm `field_mask=4` (không required), `bitemporal_query=5` |
| `DocumentFilter` | `document_id=1`, `document_template_id=2`, `subject=3`, `subject_id=4`, `core_document_key=5`, `org_document_key=6`, `status=7`, `scoped_borrower_id=8`, `scoped_operator_id=9` | `subject=1`, `subject_id=2` | Thêm 7 field còn lại ở số 3–9 |
| `Document` | 13 field, số 1–13 | Có `id`, `licensee_id`, `subject`, `subject_id`, `core_document_key`, `file_size`, `content_type`, `status`, `bitemporal_time`; `reserved 3, 6, 8, 12, 14 to 100 // 標準実装...` | 4 field Console (`document_template_id`, `subject_state`, `org_document_key`, `scoped_borrower_id`) nằm đúng các số `reserved` baseline → **dừng hỏi** |
| Enum `DocumentSubject` | 16 giá trị | 1 giá trị, `reserved 1 to 14 // 標準実装...` | **Dừng hỏi** (Console trả document subject khác sẽ thành `UNSPECIFIED`) |
| Enum `CoreDocumentKey` | 55 giá trị | 1 giá trị (`= 46`), `reserved 1 to 45 // 標準実装...` | **Dừng hỏi** |

→ Request/filter làm được ngay. Entity/enum phụ thuộc quyết định baseline `標準実装` của JP.

### `GetContracts` — loại (b), dừng hỏi

| Message | Console | Core hiện có |
|---|---|---|
| Request | `licensee_id=1`, `pagination=2`, `field_mask=3`, `filter=4`, `bitemporal_query=5` | `licensee_id=1`, `pagination=2`, `filter=3` |
| `ContractFilter` | `contract_id=1`, `borrower_id=2`, `status=3`, `guarantee_executed=4` | `contract_id=1`, `product_id=2` |
| Response | `contracts=2` + 4 map side-load (3–6) | `contracts=2` |
| `Contract` | 17 field, 1 deprecated (Money, Decimal, `ContractStatus`, bitemporal...) | 9 field (`amount int64`, `repayment_count`, `matures_on`...) — trùng tên với Console: `id`, `product_id`, `borrower_id`, `contract_application_id`, `contracted_at` (khác số) |

### `GetContractApplications` — loại (b), dừng hỏi

| Message | Console | Core hiện có |
|---|---|---|
| Request | `pagination=1`, `field_mask=2`, `filter=3`, `bitemporal_query=4`, `licensee_id=5` | `licensee_id=1`, `pagination=2`, `filter=3` |
| `FilterCondition` | thêm `contract_application_approval_filters=4`, `product_filters=5`, `borrower_filters=6` | chỉ `contract_application_filters=3` |
| `ContractApplicationFilter` | `contract_application_id=1`, `borrower_id=2`, `status=3`, `product_id=4` | `contract_application_id=1`, `product_id=2` |
| Response | `contract_applications=2` + 6 map side-load (3–8) | `contract_applications=2` |
| `ContractApplication` | 17 field, 2 deprecated | 5 field (`id`, `product_id`, `borrower_id`, `amount`, `repayment_count`) |

Bảng này là ảnh chụp tại 2026-09-25. Chạy lại lệnh ở §2 bước 1 trước khi làm.
