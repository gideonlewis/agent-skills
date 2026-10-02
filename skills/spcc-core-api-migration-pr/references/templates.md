# Template PR description

Template tiếng Anh cho từng loại PR. Chỉ 2 heading `## 概要` / `## 参考リンク` giữ tiếng Nhật (template `.github/pull_request_template.md` của repo). Lấy nội dung từ migration report, không tự chế.

## 1. cred-proto — thêm RPC mới (`Mode: new`)

Bản gọn, dùng khi mọi field giống Console. Ví dụ thật: PR #2256.

```markdown
## 概要

Adds the BorrowerAssociate RPCs to Core API (Console API → Core API migration).

Following the chunk_1 example (`CreateRole`, `GetBorrowerExpatriations`), the Core RPCs reuse Console's types and keep Console's fields, field numbers, types and validation as they are.

### Target RPCs

| Core RPC | Type | Console types reused |
|---|---|---|
| `GetBorrowerAssociates` | Query | `console.entity.BorrowerAssociate`, `console.rpc.BorrowerRelatedPartyFilter` |
| `SubmitBorrowerAssociate` | Write | `console.entity.BorrowerAssociateRelation` |

No new Core entity or filter is added.

> Registration in `CoreService` will be added later in a separate batch PR.

### Differences from Console

- Comments are in Japanese, and `GetBorrowerAssociatesRequest` has a JSON example.
- `SubmitBorrowerAssociateResponse.borrower_associate_id` has `field_behavior = REQUIRED` and `string.uuid` (same as `CreateRoleResponse` in chunk_1; spec annotations only).

Everything else is identical to Console, including `bitemporal_query`, `field_mask` and `effective`. There are no deprecated fields and no added validation.

## 参考リンク

- https://finatexthd.atlassian.net/browse/CRES-#####
- Design doc: Console API から Core API への移行方針
```

Mỗi PR proto giờ chỉ 1 RPC (không phải batch nhiều RPC); `### Target RPCs` vẫn giữ dạng bảng kể cả khi chỉ 1 dòng, để nhất quán format. Dòng note "Registration in `CoreService`..." là **bắt buộc** cho mọi PR `new` (không áp dụng cho `extend` — RPC đã đăng ký sẵn — và không áp dụng cho PR batch đăng ký ở Bước 8 của workflow — PR đó làm đúng việc này). Đặt ngay dưới `### Target RPCs`, dạng 1 dòng blockquote ngắn, không phải heading riêng.

PR body **không có** các heading `Not included in this PR`, `Verified`, `Points to confirm`, `Skipped RPCs` nữa — nội dung tương ứng vẫn nằm trong migration report, chỉ không đưa vào PR. RPC bị bỏ qua / ngoài phạm vi thì thêm cột `Status` vào `### Target RPCs` (không cần heading `Skipped RPCs` riêng).

Thêm các mục sau **chỉ khi có**:

- Có field bị bỏ (entity phụ trong response) hoặc đánh số lại → `### Field mapping` chỉ gồm các field đó, dạng `| Console field | Console No. | Core No. | Handling |`.
- Có field deprecated (được giữ) → 1 dòng trong `### Differences from Console`: "`X.y` is `deprecated = true` in Console and is kept as is."
- Có validate bổ sung → `### Validation added on top of Console` (bảng `RPC | Field | Rule | Verification`).

## 2. cred-proto — mở rộng Core RPC đã có (`Mode: extend`, Hướng A)

Dùng khi Console RPC trùng tên với Core RPC đang chạy cho minazuki (skill `spcc-migrate-console-rpc-to-core-proto`, `references/existing-core-rpcs.md`).

```markdown
## 概要

Extends the existing Core RPC `GetDocuments` (built for and used by minazuki) with the fields Console needs, so that the Console `GetDocuments` can be migrated to it. Existing fields are unchanged; only new fields are added. Fields that are required in Console are `optional` in Core, because minazuki does not send them.

### Target RPCs

| Console RPC | Core RPC | Mapping type | Status |
|---|---|---|---|
| `GetDocuments` | `GetDocuments` | 1対1レビュー | Extended (existing Core RPC for minazuki) |

### Field mapping

#### GetDocuments — request

| Console field | Console No. | Core field | Core No. | Handling |
|---|---|---|---|---|
| `licensee_id` | 1 | `licensee_id` | 1 | Existing |
| `pagination` | 2 | `pagination` | 2 | Existing |
| `field_mask` | 3 | `field_mask` | 4 | Added (not `required`; minazuki does not send it) |
| `filter` | 4 | `filter` | 3 | Existing |
| `bitemporal_query` | 5 | `bitemporal_query` | 5 | Added (`optional`) |

(Same table for the filter message and the entity.)

### Required in Console, optional in Core

- `GetDocumentsRequest.field_mask`

Note: fields added to the response entity are also returned to minazuki — please confirm that's acceptable. (Also flag here any `reserved ... // 標準実装との整合性確保用` slot that had to be touched, and what was decided.)

## 参考リンク

- https://finatexthd.atlassian.net/browse/CRES-#####
```

## 3. cred-proto — PR follow-up sửa PR migrate cũ (`Mode: followup`)

```markdown
## 概要

Follow-up to #<n>. It is based on the #<n> branch so the diff shows only the fixes; merge it into #<n> if it looks good.

Aligns <RPC group> with the chunk_1 example and the migration scope (structure, types and validation unchanged from Console).

### Changes

| Item | #<n> | This PR (= Console) |
|---|---|---|
| Entity | `core.entity.OperatorRegistration` (new) | `console.entity.OperatorRegistration` |
| `field_mask` (request) | Removed | Restored, field 3 |

## 参考リンク

- #<n>
```

Ví dụ thật: cred-proto PR #2275, #2276, #2277, #2278 (viết tiếng Nhật trước khi có quy tắc tiếng Anh; cấu trúc giống).

## 4. azuki — implement handler

```markdown
## 概要

Implements the Core RPCs added in CRES-#####.

### Target RPCs

| Core RPC | Kind | Reused usecase |
|---|---|---|
| `GetBorrowerNotes` | Query | `FindBorrowerNotesUsecase` |
| `UpsertBorrowerNote` | Mutation | `UpsertBorrowerNoteUsecase` |

### Differences from the Console RPC

| Item | Console | Core | Intentional |
|---|---|---|---|
| Default sort order | `created_at DESC` | Same | — |
| Empty result | Empty list | Same | — |
| Operator ID for M2M calls | Always set | `uuid.Nil` | Yes (no operator in client credentials) |

### Permissions

- Required CorePermission: `...`
- CorePermissionGroup: `...`
- Permissions are not widened compared with Console.

### Tests

| Case | Query | Mutation |
|---|---|---|
| Success (OAuth2 token) | ✅ | ✅ |
| Success (Console operator token) | ✅ | ✅ |
| Unauthenticated | ✅ | ✅ |
| Role / scope without permission | ✅ | ✅ |
| Invalid input | ✅ | ✅ |
| DB state after write | — | ✅ |

### Points to confirm

-

### Not included in this PR

- azuki-app call-site switch, feature flag, rollout

## 参考リンク

- https://finatexthd.atlassian.net/browse/CRES-#####
- cred-proto PR: <link>
```
