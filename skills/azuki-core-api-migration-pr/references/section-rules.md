# Quy tắc từng mục của PR description

Nội dung chép từ migration report; bảng dưới là giá trị hợp lệ và câu chuẩn (tiếng Anh vì PR viết tiếng Anh).

### `### Target RPCs`

List **every** RPC the user handed over. The `Status` column only accepts:

| Value | When |
|---|---|
| `Added` | Proto added in this PR (including `分割` / `分割レビュー` RPCs, which keep only the main entity) |
| `Extended (existing Core RPC for minazuki)` | Same-name Core RPC built for minazuki, extended by adding fields (approach A) |
| `Skipped (already migrated)` | Already migrated to Core (chunk_1 or an earlier migration PR) |
| `Out of scope (個別設計)` | Type `個別設計` |
| `Out of scope (not migrated)` | RPC decided not to migrate (`GetOrgEnv`, `GetSupervisorEnv`...) |

When the sheet labels an RPC `1対1レビュー` but its Console response returns several entities, add a short note right under the table (not a separate heading) with the entities counted, so JP can fix the sheet.

### `### Field mapping`

Mandatory, one table per RPC, never omitted. The `Handling` column only accepts: `Migrated`, `Renumbered`, `Removed`, `Existing`, `Added`, `Made optional`. Standard notes:

| Situation | Note |
|---|---|
| Main entity | `Main entity (console.entity.<X>)` |
| `field_mask` / `bitemporal_query` / `effective` | `Kept as in Console` |
| Filter from Console | `References console.rpc.<X>Filter` |
| Deprecated field (not an entity) | `Deprecated; kept as in Console` |
| Deprecated side-load entity | `Deprecated side-load entity (handled by another RPC)` |
| Not the main entity (side-load, other entity, count) | `Not the main entity (handled by another RPC)` |
| Approach A, new field | `Added for Console migration (optional)` |
| Approach A, required in Console | `Optional in Core; minazuki does not send it` |

Under the current rules no field is dropped except non-main entities in the response; deprecated fields are kept as in Console. A row saying a field is not migrated for a design reason means the proto is wrong — fix the proto, not the table.

### `### Deprecated fields`

List them separately even if they appear in the table: `<package>.<message>.<field>`, how it is marked (`deprecated = true`), and how it was handled: a deprecated field is **kept** as in Console (cleanup is out of scope); a deprecated side-load entity is **removed** (fields renumbered, no `reserved`). A field whose comment says "deprecated" without `deprecated = true` → ask the user before opening the PR (don't guess); once resolved, note the decision here. None → write `None`.

### `### Validation added on top of Console`

Every rule added on top of Console (`string.uuid` for ID fields, `enum.defined_only` for enums — the only two allowed, approved by JP on 2026-09-25 on condition of verification). One row per field. `Verification` states how azuki handles the field and where azuki-app gets the value; never leave it blank.

Under `Not added (needs confirmation)`: fields missing a rule that were not changed — plain `string` fields without `required`/`optional`, and fields inside reused `console.entity` / `console.rpc` types.

Nothing added and nothing skipped → write `None`.

PR description **không còn** các heading `### Skipped RPCs`, `### Points to confirm`, `### Not included in this PR`, `### Verified` — bỏ hẳn khỏi PR body kể từ giờ. Nội dung của chúng đi đâu:

- **Skipped RPC**: chỉ cần dòng trong `### Target RPCs` (`Status = Skipped (already migrated)`), không cần liệt kê chi tiết thêm ở heading riêng.
- **Points to confirm cho JP reviewer**: gộp thành 1 ghi chú ngắn ngay dưới bảng/mục liên quan (`### Target RPCs`, `### Required in Console, optional in Core`...), không phải heading riêng. Điểm chưa hỏi user thì phải hỏi user trước khi mở PR, không đẩy sang JP.
- **Registration trong `CoreService`**: 1 dòng blockquote ngắn ngay dưới `### Target RPCs` (chỉ PR `new`, xem `templates.md`), không phải heading riêng.
- **Handler azuki / feature flag / azuki-app switch / rollout chưa làm**: không ghi vào PR nữa — mặc định ai đọc PR (chỉ đổi `proto/core/**`) đều hiểu đây là proto-only.
- **`make lint`/`format/check`/`gen` pass**: không ghi vào PR — verification chỉ lưu trong migration report nội bộ; PR body không có bằng chứng chạy lệnh nữa (CI của repo tự chạy lint/format/gen trên PR).

### `## 参考リンク`

- Full Jira link: `https://finatexthd.atlassian.net/browse/CRES-#####`
- azuki PR: also link the cred-proto PR. Follow-up PR: link the original PR.
