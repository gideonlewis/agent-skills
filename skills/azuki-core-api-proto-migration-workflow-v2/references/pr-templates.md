# PR templates (v2)

Người đọc: member JP. Tiếng Anh, ngắn, chỉ nêu chỗ khác Console. Giữ 2 heading của `.github/pull_request_template.md`: `## 概要`, `## 参考リンク`.

Không đưa vào: link/ID Backlog (`SPCC-...`), Mattermost nội bộ, tiếng Việt, lịch sử làm việc, và các mục `Not included in this PR` / `Verified` / `Points to confirm` / `Skipped RPCs` (PR 1 RPC không cần; PR đăng ký lô là ngoại lệ, xem §4).

Title (< 70 ký tự, khớp `.*CRES-[0-9]+`, không prefix `feat:`):

| Loại | Title |
|---|---|
| RPC mới | `[CRES-#####] Add <RpcName> to Core API` |
| Sửa PR đã merge | `[CRES-#####] Fix <mô tả ngắn>` |
| Đăng ký lô | `[CRES-#####] Register <N> merged Core RPCs in CoreService` |

Label: `release:minor` (cred-proto bắt buộc đúng 1 label semver).

---

## 1. RPC mới

Mẫu: #2297, #2288.

```markdown
## 概要

Adds `<RpcName>` to Core API.

### Target RPCs

| Console RPC | Core RPC | Mapping type | Status |
|---|---|---|---|
| `<RpcName>` | `<RpcName>` | 1:1 review | Added |

> Registration in `CoreService` will be added later in a separate batch PR.

### Added definitions

- `core/rpc/<snake_case>.proto`
- `core/entity/<domain>.proto` (new) — `<Entity>`, `<Enum>`
- `<Message>` added to `core/entity/<x>.proto` (that file already exists on master with `<Existing>`, #<n>)
- `core.rpc.<X>Filter` added to `core/rpc/filter.proto`

Core no longer depends on `console.entity` / `console.rpc` for this RPC.

### Differences from Console

None. Request/response fields, numbering, types, and validation match Console exactly.

### Deprecated fields

None.

### Validation added on top of Console

None.

## 参考リンク

- https://finatexthd.atlassian.net/browse/CRES-#####
- Design doc: Console API から Core API への移行方針
```

`Mapping type`: `1:1 review` (`1対1レビュー`), `Business operation` (`業務操作`), `Split` (`分割`), `Split review` (`分割レビュー`).

### Viết `### Differences from Console`

Một gạch đầu dòng mỗi khác biệt, kèm lý do ngắn. Các loại thường gặp:

```markdown
- Side-loaded `borrowers` map (deprecated in Console) is dropped; the response keeps only `pagination` and `borrower_associates`. Later fields are renumbered.
- `core.entity.Borrower` is renumbered 1..N (Console has `reserved 30` and gaps at 16, 37, 38). Field names, types, and order are unchanged.
- `BorrowerRelatedPartyFilter.target` is a single-field `oneof` in Console; Core uses `optional` for the same field.
- `GuaranteeProvider` is defined in an enum-only file `core/entity/guarantee_assessment_result.proto`, because the Guarantee Assessment domain has no Core RPC yet but `BorrowerFilter` references it.
- `SubmitReviewResponse.review_id` adds `(buf.validate.field).string.uuid` and `(google.api.field_behavior) = REQUIRED` — the azuki handler always sets this field on every success path.
```

Sửa comment Console sai nghĩa theo text UI → ghi: `` Comment on `UNKNOWN_PAYMENT_IN` is aligned with the UI label (入金突合中); Console's comment is outdated. ``

### `### Deprecated fields`

```markdown
| Field | Handling |
|---|---|
| `Borrower.home_phone_number` | Kept as in Console, including `[deprecated = true]` |
```

### `### Validation added on top of Console`

```markdown
| Field | Rule | Verification |
|---|---|---|
| `GetReviewsRequest...review_request_id` | `string.uuid` | `optional`; azuki handler parses with `uuid.Parse`; azuki-app always sends a UUID from the list row |
```

---

## 2. RPC stack trên PR khác

Như §1, thêm đoạn này ngay dưới `## 概要` (mẫu: #2298, #2296):

```markdown
**Stacked on #<n> (`<RootRpc>`)**: this RPC reuses `<core.entity.X>`, defined in that PR (consolidated there to limit how many PRs touch the shared `filter.proto` / `<entity>.proto`). Base branch here is `<root-branch>`, not `master` — merge #<n> first, then retarget/merge this one into `master`.
```

PR gốc thêm câu trong `### Added definitions`:

```markdown
- `core.rpc.ReviewFilter` / `ReviewFlowFilter` added to `core/rpc/filter.proto` — consolidated here so only one PR touches the shared file. `GetReviewFlows` and `SubmitReview` (separate PRs) stack on this branch.
```

Khi PR gốc merge, GitHub thường tự retarget PR stack về `master`; nếu không → `gh pr edit <n> --base master`, rồi kiểm tra `git diff --stat origin/master` chỉ còn file của PR stack.

---

## 3. Follow-up sửa PR đã merge

Mẫu: #2351.

```markdown
## 概要

Follow-up for <PR list> merged before <quyết định> was settled: <1 câu quyết định>.

### 1. <Nhóm thay đổi thứ nhất> (#<n>)

<Bảng field khi đổi type/đánh số:>

| Field(s) | Console type | #<n> (reverted here) |
|---|---|---|
| `address` | `google.type.PostalAddress` | split into `postal_code` / `administrative_area` / ... |

<1-2 câu: tác động (ví dụ "`core.entity.Borrower` isn't consumed by any azuki handler or FE yet, so renumbering is safe").>

### 2. <Nhóm thay đổi thứ hai> (#<n>)

- `core/entity/<x>.proto` (new) — `<Entity>`
- `core.rpc.<X>Filter` (new, `core/rpc/filter.proto`)
- Updates `<rpc_a>.proto`, `<rpc_b>.proto` to reference the new Core types instead of Console's.

All new entities/filters mirror Console's field names, types, and validation — no conversions, no dropped fields.

### Not touched

- `create_role.proto`, `get_borrower_expatriations.proto` — chunk_1 reference examples.

## 参考リンク

- https://finatexthd.atlassian.net/browse/CRES-#####
- #<n>, #<m>
```

---

## 4. Đăng ký lô `core_service.proto`

Mẫu: #2352. Đây là loại duy nhất có `### Not included` và `### Verified`.

```markdown
## 概要

Registers <N> Core RPCs in `CoreService` that were merged as standalone proto files — per the policy of shipping 1 RPC per PR and batching registration separately, to avoid many PRs conflicting on `core_service.proto`.

### RPCs registered

| RPC | Source PR |
|---|---|
| `GetBorrowers` | #2287 |

### Not included

- `<Rpc>` (#<n>) — still open

These will be added in a follow-up registration PR once their PRs merge.

### Verified

- `make lint`, `make format/check`, `make gen` — all pass.
- Diff is scoped to `core/rpc/core_service.proto` only (imports + `rpc` declarations).

## 参考リンク

- https://finatexthd.atlassian.net/browse/CRES-#####
```

---

## 5. Reply review (tiếng Anh, 1-3 câu)

Đã sửa:

```text
Fixed — mirrored all Console BorrowerFilter fields; cross-domain enums are defined in enum-only Core files.
```

Finding mâu thuẫn quyết định đã chốt (dẫn bằng chứng, không sửa):

```text
This is intentional: Core keeps Console's field types (google.type.Money / PhoneNumber / PostalAddress) — see #2351. Console: proto/console/entity/borrower.proto L42.
```

```text
Not added: Console's SubmitBorrowerWithdrawalDecisionRequest.licensee_id has no `required`, and we only add string.uuid / enum.defined_only on top of Console.
```

Căn comment theo tên UI:

```text
Updated the enum comments to match the UI labels in azuki-app (locales/ja/enum.json), e.g. UNKNOWN_PAYMENT_IN → 入金突合中.
```

User nói không cần reply → không reply.
