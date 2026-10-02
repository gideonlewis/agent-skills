# Format migration report

Migration report là **đầu ra của skill này và đầu vào của skill tạo PR** (`spcc-core-api-migration-pr`). Viết bằng **tiếng Anh** (PR description tiếng Anh, bước sau chép thẳng các bảng). Ghi ra file ngoài repo (scratchpad / `/tmp`), không commit.

Giữ đúng tên heading và giá trị cột dưới đây — skill tạo PR và workflow đọc theo tên này. Mục không có nội dung thì ghi `None`, không xoá heading.

---

## Mẫu

````markdown
# Migration report

- Repo: cred-proto
- Branch: feature/CRES-20700-core-api-borrower-notes
- Base: master
- Ticket: CRES-20700
- Mode: new            # new | followup | extend
- Original PR: None    # số PR gốc khi Mode = followup
- Result: done         # done | stopped

## Target RPCs

| Console RPC | Core RPC | Mapping type (sheet) | Entities in Console response | Status |
|---|---|---|---|---|
| `GetBorrowerNotes` | `GetBorrowerNotes` | 1対1レビュー | 2 (`BorrowerNote`, `Borrower`) | Added |
| `GetBorrowerExpatriations` | `GetBorrowerExpatriations` | 1対1レビュー | 1 | Skipped (already migrated) |
| `ExportBorrowers` | — | 個別設計 | — | Out of scope (個別設計) |

## Files changed

- `proto/core/rpc/get_borrower_notes.proto` (added)

## Registration (pending)

`core_service.proto` không sửa trong PR này — đăng ký theo lô ở PR riêng sau. Ghi sẵn đúng nội dung sẽ cần thêm để PR batch đăng ký chỉ việc chép:

- Import (xếp đúng vị trí alphabet trong `core_service.proto`): `import "core/rpc/get_borrower_notes.proto";`
- Dòng `rpc` (đặt cạnh cụm RPC cùng domain, ví dụ sau `GetBorrowerAssociates`):

  ```proto
  // GetBorrowerNotes 借主メモを検索する
  rpc GetBorrowerNotes(core.rpc.GetBorrowerNotesRequest) returns (core.rpc.GetBorrowerNotesResponse);
  ```

## Field mapping

### GetBorrowerNotes

| Message | Console field | Console No. | Core field | Core No. | Handling | Note |
|---|---|---|---|---|---|---|
| Request | `licensee_id` | 1 | `licensee_id` | 1 | Migrated | |
| Request | `field_mask` | 3 | `field_mask` | 3 | Migrated | Kept as in Console |
| Response | `borrower_notes` | 2 | `borrower_notes` | 2 | Migrated | Main entity (`console.entity.BorrowerNote`) |
| Response | `borrowers` | 3 | — | — | Removed | Not the main entity (handled by another RPC) |

## Deprecated fields

- `console.rpc.GetBorrowerNotesRequest.legacy_note_id` (`deprecated = true`) → kept as in Console (cleaning up deprecated fields is out of scope)

## Validation added on top of Console

| RPC | Field | Added rule | Verification |
|---|---|---|---|
| `UpdateRole` | `role_id` | `string.uuid` | Already `required` in Console. azuki parses it with `uuid.MustParse`; azuki-app sends the ID returned by `GetRoles` |

Not added (needs confirmation):

- `GetCreditInformationCICSummary.contract_application_id`: plain `string`, `string.uuid` would reject `""`.

## Skipped RPCs

- `GetBorrowerExpatriations`: already migrated in chunk_1 (`proto/core/rpc/get_borrower_expatriations.proto`, registered in `CoreService`).

## Required in Console, optional in Core

None

## Points to confirm

- The sheet labels `GetBorrowerNotes` as `1対1レビュー`, but its Console response returns `BorrowerNote` and `Borrower`. Only `BorrowerNote` is kept.

## Stopped

None

## Verification

- `make lint`: pass
- `make format/check`: pass
- `make gen`: pass
- `cmp_fields`:
  - `get_borrower_notes`: only `borrowers` removed (not the main entity)

## Follow-up context

None
````

---

## Giá trị hợp lệ

| Cột / trường | Giá trị |
|---|---|
| `Mode` | `new` (RPC mới), `followup` (sửa PR cũ), `extend` (mở rộng Core RPC đã có) |
| `Result` | `done`, `stopped` (còn điểm cần user quyết — xem `## Stopped`) |
| `Status` (Target RPCs) | `Added`, `Extended (existing Core RPC for minazuki)`, `Skipped (already migrated)`, `Out of scope (個別設計)`, `Out of scope (not migrated)`, `Stopped (needs decision)` |
| `Handling` (Field mapping) | `Migrated`, `Renumbered` (migrated, số khác Console do field trước bị xoá), `Removed`, `Existing`, `Added`, `Made optional` |

Ghi chú (`Note`) chuẩn:

| Tình huống | Note |
|---|---|
| Entity chính | `Main entity (console.entity.<X>)` |
| `field_mask` / `bitemporal_query` / `effective` | `Kept as in Console` |
| Filter lấy từ Console | `References console.rpc.<X>Filter` |
| Field deprecated (không phải entity) | `Deprecated; kept as in Console` |
| Entity phụ deprecated | `Deprecated side-load entity (handled by another RPC)` |
| Không phải entity chính (side-load, entity khác, count) | `Not the main entity (handled by another RPC)` |
| Hướng A, field mới | `Added for Console migration (optional)` |
| Hướng A, required bên Console | `Optional in Core; minazuki does not send it` |

## Quy tắc từng mục

- **Target RPCs**: liệt kê **mọi** RPC user đưa, kể cả RPC bị bỏ qua / từ chối / dừng.
- **Registration (pending)**: bắt buộc với mọi RPC `Added` / `Extended`. Ghi đúng import + dòng `rpc` theo `proto-authoring-rules.md §9` như thể sắp đăng ký thật, để PR batch sau chỉ việc chép-dán. RPC `Skipped` / `Out of scope` / `Stopped` thì không cần mục này (hoặc ghi `None`).
- **Field mapping**: mỗi RPC `Added` / `Extended` một bảng, gồm mọi field của request, `<Rpc>FilterCondition` và response (Hướng A: thêm filter, entity, enum). Field Console không phải deprecated mà Core không có → proto sai, sửa proto chứ không ghi vào bảng.
- **Validation added on top of Console**: mỗi rule một dòng, `Verification` không được trống. Field thiếu rule mà không thêm → `Not added`.
- **Required in Console, optional in Core**: chỉ Hướng A; không có thì `None`.
- **Points to confirm**: chỉ điểm cần **JP reviewer** quyết. Điểm chưa hỏi user thì phải hỏi user trước, không đẩy vào đây. Hướng A luôn có câu "Fields added to the response are also returned to minazuki."
- **Stopped**: `Result = stopped` thì mỗi điểm dừng một dòng, dạng `<RPC>: <vấn đề> — option A: ... / option B: ...`. Workflow không được sang bước tạo PR khi mục này khác `None`.
- **Verification**: kết quả thật của lệnh, không ghi "pass" khi chưa chạy. Không chạy được (Docker down) → ghi rõ `not run (<lý do>)`.
- **Follow-up context** (`Mode = followup`): số PR gốc, danh sách điểm sửa dạng `#<n> → this change`, và review comment của PR gốc đã tự hết hiệu lực nhờ thay đổi này.
