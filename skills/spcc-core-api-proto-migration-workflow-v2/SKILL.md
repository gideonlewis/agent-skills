---
name: spcc-core-api-proto-migration-workflow-v2
description: >
  Workflow trọn gói trong 1 skill để migrate Console RPC sang Core API ở repo
  cred-proto: tạo branch, đọc Console gốc, viết proto Core với entity/filter
  TỰ ĐỊNH NGHĨA (không import console.entity / console.rpc), giữ nguyên type
  Console (Money, PhoneNumber, PostalAddress...), verify lint/format/gen,
  commit/push, tạo PR tiếng Anh, xử lý review và đăng ký core_service.proto
  theo lô. Mỗi RPC một PR. Dùng khi được yêu cầu "migrate RPC X sang Core",
  "làm SPCC-xxxx", "sửa PR theo v2", "fix PR còn dùng console entity", "đăng ký
  các RPC đã merge vào core_service", hoặc cần tách/stack PR để tránh conflict
  filter.proto. Review PR migrate thì dùng skill
  spcc-review-console-rpc-to-core-proto (cùng bộ quy tắc).
---

# Migrate Console RPC → Core proto (v2)

## Khi Nào Dùng

- Migrate 1 Console RPC sang Core API, từ branch tới PR (user đưa nhiều RPC → làm tuần tự, mỗi RPC một branch/PR).
- Sửa PR migrate (đang mở hoặc đã merge) còn dùng `console.entity` / `console.rpc`, hoặc lệch quyết định bên dưới.
- Đăng ký theo lô các RPC đã merge vào `core_service.proto`.

Không dùng cho: handler azuki, switch azuki-app, feature flag, rollout. Review PR → `spcc-review-console-rpc-to-core-proto`.

Skill này thay cho chuỗi 4 skill v1 (`cred-proto-git`, `spcc-migrate-console-rpc-to-core-proto`, `spcc-core-api-migration-pr`, `spcc-core-api-proto-migration-workflow`). Skill v1 vẫn còn nhưng **quy tắc của chúng đã cũ** (dùng lại console entity, gộp batch 3-5 RPC) — khi mâu thuẫn, theo skill này.

## Quyết Định Đã Chốt

Nguồn sự thật. Code, README hay PR cũ mâu thuẫn với bảng này thì bảng này thắng. Lịch sử và PR minh chứng: [references/decision-history.md](references/decision-history.md).

| # | Quyết định |
|---|---|
| 1 | **Core tự định nghĩa `core.entity.*` và `core.rpc.*Filter`**. RPC Core không import `console/entity/*`, `console/rpc/filter.proto`. |
| 2 | **Giữ nguyên type field của Console**: `google.type.Money`, `PhoneNumber`, `PostalAddress`, `Decimal`, `Date`, `DateTime`, `cred_type.*`. Không convert sang `int64` / `string` / tách field. Message riêng của Console (ví dụ `YearMonth`) → mirror thành message Core cùng tên. |
| 3 | **Đánh số**: request/response giữ số Console (chỉ đánh lại khi bỏ side-load, xem #7). Message entity/filter Core mới đánh liên tục 1..N theo thứ tự field Console, bỏ `reserved`/khoảng trống (Console không có khoảng trống thì trùng số). **Enum giữ nguyên giá trị và số Console**, kể cả khoảng trống và `reserved`. |
| 4 | **Filter mirror đủ mọi field Console**, kể cả field tham chiếu domain mà Core chưa có RPC. Enum/type của domain đó → tạo file `core/entity/<domain>.proto` **chỉ chứa phần cần dùng**. `oneof` giữ nguyên là `oneof` (cùng tên oneof, kể cả khi chỉ có 1 field), không đổi thành `optional`. |
| 5 | **Trước khi tạo `core/entity/<x>.proto`, kiểm tra file đã có trên `master` chưa.** Có rồi → append vào file đó, không ghi đè. Enum/message đã có ở Core → import, không định nghĩa lại. |
| 6 | **Validate**: request giữ đúng rule Console; chỉ được thêm `string.uuid` / `enum.defined_only` khi đã kiểm chứng giá trị FE gửi. Không thêm `string.uuid` lên `string` thường (không `required`/`optional`) vì request rỗng sẽ bị từ chối. Response chỉ thêm `string.uuid` + `(google.api.field_behavior) = REQUIRED` khi **đã đọc handler azuki** và thấy field luôn được set ở mọi nhánh thành công. |
| 7 | **Response nhiều entity** (`分割`, `分割レビュー`, side-load `map<...>`): giữ entity chính + `pagination`, xoá side-load (deprecated hay chưa), không `reserved`, đánh số lại liên tục nếu có field phía sau. |
| 8 | **Giữ như Console**: field `deprecated = true` (kể cả option), `field_mask` / `bitemporal_query` / `effective` (kể cả dead field); không thêm field Console không có (ví dụ `pagination`). Update RPC giữ shape Console (field_mask + entity + effective). |
| 9 | **Mỗi RPC một PR**, không sửa `core_service.proto` trong PR đó. Đăng ký dồn vào PR lô riêng, chỉ gồm RPC **đã merge** vào `master`. |
| 10 | **File dùng chung** (`filter.proto`, entity/enum nhiều RPC cần): dồn vào 1 PR gốc, các PR còn lại stack lên branch của PR gốc. RPC dùng message do PR khác định nghĩa (ví dụ `core.rpc.ReviewFlowStep`) cũng stack. |
| 11 | **Comment**: tiếng Nhật cho comment mới; giữ nguyên comment Console (kể cả dòng `TODO:`) khi field không đổi; comment Console sai nghĩa → sửa theo text UI ở `azuki-app/locales/ja/enum.json`. |
| 12 | **Không đụng** chunk_1 (`create_role.proto`, `get_borrower_expatriations.proto`) và Core RPC không phải migrate (ví dụ `get_operator_notifications.proto`, `submit_credit_information_file_import_decision.proto`) nếu không được yêu cầu rõ. |
| 13 | **Ngoài phạm vi**: idempotency key, refactor `BitemporalQuery`, chuẩn hoá `FieldMask`, thêm field vào `GetFeatureFlags`, sửa `proto/console/**`. |

## Xác Định Loại RPC

1. User ghi loại → dùng loại đó.
2. Suy từ tên: `Get*` → `1対1レビュー`; `Create*`, `Update*`, `Delete*`, `Submit*`, `Upsert*`, `Withdraw*`, `Transition*`, `Assign*`, `Register*`, `Send*` → `業務操作`; `Export*`, `Generate*`, `Count*`, `Parse*`, `IssueURL*`, `ValidateAndProcess*` → `個別設計`, **từ chối**.
3. Luôn đếm entity trong response Console (nhãn sheet không đủ tin). Nhiều entity → áp dụng quyết định #7; ghi chú trong PR nếu nhãn sheet sai.
4. Console RPC trùng tên Core RPC đã có (`GetDocuments`, `GetContracts`, `GetContractApplications`) → [references/proto-patterns.md §8](references/proto-patterns.md).

## Quy Trình

### Bước 0 — Chuẩn bị

```bash
git -C <cred-proto> status --porcelain     # phải sạch; có thay đổi lạ → dừng hỏi, không stash/reset
git -C <cred-proto> fetch origin master
docker info > /dev/null 2>&1 && echo "docker OK" || echo "docker DOWN"   # DOWN → báo user (colima start)
```

Có ticket Backlog (SPCC-xxxx) → đọc description để lấy danh sách RPC, PR cũ liên quan và điểm đã chốt. Có PR cũ → đọc body và review comment:

```bash
gh pr view <n> --repo Finatext/cred-proto --json title,body,files,baseRefName,state
gh api repos/Finatext/cred-proto/pulls/<n>/comments --jq '.[] | "\(.user.login) \(.path): \(.body)"'
```

Comment có link Slack nội bộ không đọc được → hỏi user nội dung, không đoán.

### Bước 1 — Branch

- **RPC mới**: `git switch -c feature/CRES-#####-core-api-<kebab-rpc> origin/master`.
- **Sửa PR đang mở**: làm trên **chính branch của PR** (`git switch <branch> && git reset --hard origin/<branch> && git rebase origin/master`). Không tạo branch `-v2` — GitHub không đổi được head branch của PR có sẵn.
- **Sửa PR đã merge**: branch mới từ `origin/master`, PR follow-up.
- **Stack** (quyết định #10): `git switch -c <branch> origin/<branch-PR-gốc>`, sau khi tạo PR thì `gh pr edit <n> --base <branch-PR-gốc>`. Nếu PR gốc bị rebase, chuyển riêng commit của PR stack sang: `git rebase --onto origin/<branch-PR-gốc> <commit-cũ-của-PR-gốc>`.

Chọn PR gốc khi nhiều RPC cùng cần file dùng chung: RPC mà các RPC còn lại phụ thuộc nhiều nhất (ví dụ `GetReviews` chứa `ReviewResult` mà `SubmitReview` cần, nên mang luôn `ReviewFlowFilter` cho `GetReviewFlows`).

### Bước 2 — Đọc Console gốc

Đọc toàn văn `proto/console/rpc/<name>.proto` (tên file có thể lệch tên RPC: `grep -ln "message <Rpc>Request" proto/console/rpc/`) và mọi `proto/console/entity/*.proto` nó tham chiếu, kể cả enum domain khác dùng trong filter. Liệt kê: entity chính, side-load, field deprecated, type đặc biệt, message cục bộ của RPC (ví dụ `console.rpc.ReviewFlowStep`).

### Bước 3 — Viết proto Core

1. **Entity** `proto/core/entity/<domain>.proto`: kiểm tra trước (`ls`, `git grep -n "^message X \|^enum X " origin/master -- proto/core/`). Chưa có → tạo; có file → append; có sẵn type → import.
2. **Filter** trong `proto/core/rpc/filter.proto`: mirror đủ field (quyết định #4), thêm import `core/entity/*` theo alphabet, append message cuối file.
3. **RPC** `proto/core/rpc/<snake_case>.proto`: mirror request/response, đổi `console.entity.X` / `console.rpc.X` thành `core.entity.X` / `core.rpc.X`. Query có block JSON mẫu trong comment request.
4. Không sửa `core_service.proto` (quyết định #9).

Template, comment chuẩn, lệnh so field: [references/proto-patterns.md](references/proto-patterns.md).

### Bước 4 — Verify

```bash
make lint && make format/check && make gen   # format fail → make fmt; gen "server unavailable" → chạy lại
grep -rn "console\." proto/core/rpc/<file>.proto   # phải rỗng
git status --short
git diff --stat origin/master -- proto/          # chỉ đúng file trong scope
```

`git diff --stat origin/master` có file **bị xoá** mà mình không xoá → branch cũ hơn `master` (PR khác vừa merge) → commit rồi `git rebase origin/master` trước khi push.

### Bước 5 — Commit, push

- Chỉ `git add` đúng file trong scope. Không commit `dist/`.
- Message: `feat|fix: [CRES-#####] <tóm tắt tiếng Anh>` + vài dòng lý do + dòng attribution theo cấu hình session.
- Đã rebase → `git push --force-with-lease`. User yêu cầu amend → `git commit --amend --no-edit` rồi `--force-with-lease`.

### Bước 6 — PR

- Title: `[CRES-#####] Add <RpcName> to Core API` (hoặc `Fix ...`, `Register <group> in CoreService`), < 70 ký tự, khớp regex CI `.*CRES-[0-9]+`.
- Body tiếng Anh theo [references/pr-templates.md](references/pr-templates.md). Chỉ `## 概要` / `## 参考リンク` giữ tiếng Nhật. Không có mục `Not included in this PR` / `Verified` / `Points to confirm` / `Skipped RPCs`.
- `gh pr create --repo Finatext/cred-proto --base <master|branch-PR-gốc> --head <branch> --title "..." --body-file <file>` rồi `gh pr edit <n> --add-label "release:minor"`.
- Kiểm tra lại: `gh pr view <n> --json baseRefName,mergeable,mergeStateStatus,files`. `BEHIND` do PR không liên quan merge → không cần rebase; `DIRTY` → rebase và resolve.

### Bước 7 — Review và conflict

- Sửa theo comment trên đúng branch PR, reply ngắn tiếng Anh (`Fixed — ...`). User nói không cần reply → không reply.
- Finding của Copilot/reviewer mâu thuẫn quyết định đã chốt → không sửa theo, reply giải thích bằng quyết định + bằng chứng (file Console, code handler).
- Conflict `filter.proto` / `core_service.proto` (2 PR cùng append cuối file) → rebase, giữ cả 2 khối, import xếp alphabet, chạy lại Bước 4.
- Comment đảo ngược một quyết định trong bảng → dừng, hỏi user xác nhận trước khi áp dụng hàng loạt; sau khi chốt, cập nhật bảng quyết định của skill này và skill review.

### Bước 8 — Đăng ký `core_service.proto` theo lô (chỉ khi user yêu cầu)

1. Liệt kê RPC đã merge nhưng chưa đăng ký: so `ls proto/core/rpc/*.proto` với import trong `core_service.proto` trên `origin/master` mới nhất (reset local `master` trước — local có thể cũ).
2. Loại RPC còn ở PR chưa merge (`gh pr view <n> --json state`).
3. Branch `feature/CRES-#####-register-core-service` từ `origin/master`; thêm import theo alphabet, dòng `rpc` cạnh cụm cùng domain (domain mới → cuối service), comment `// <Rpc> <mô tả tiếng Nhật>`.
4. Verify, PR `[CRES-#####] Register <N> merged Core RPCs in CoreService`, liệt kê RPC + PR nguồn và RPC chưa đưa vào.

## Điều Kiện Dừng (hỏi user)

- Loại `個別設計` hoặc RPC chưa được xác nhận migrate.
- Response nhiều entity mà không xác định được entity chính.
- Console RPC có sort/order by, offset pagination, `total_count`, hoặc nhận `operator_id` / role / danh tính từ client.
- Chỉ migrate được khi nới quyền.
- Console RPC trùng tên Core RPC chưa ship, hoặc Hướng A đụng `reserved ... // 標準実装との整合性確保用`.
- Review comment mâu thuẫn quyết định đã chốt, hoặc trỏ tới tài liệu không đọc được.

## Báo Cáo Cho User

```text
PR: <link> (base: <base>, label: release:minor, mergeable: <state>)
RPC: <tên> — <Added | Fixed | Registered>
Entity/filter Core mới: <liệt kê; file nào append>
Validate bổ sung: <không | rule + bằng chứng handler>
Stack trên / thứ tự merge: <nếu có>
Cần JP confirm: <nếu có>
Chưa làm: handler azuki, switch azuki-app, feature flag, rollout, đăng ký core_service.proto
```

## Anti-patterns

- Import `console/entity/*` hoặc `console/rpc/filter.proto` trong Core RPC.
- Convert `Money` / `PhoneNumber` / `PostalAddress` hay tách field để "đẹp hơn".
- Bỏ field filter vì "domain đó chưa có ở Core" — tạo enum-only file thay vì bỏ.
- Dùng `Write` tạo `core/entity/*.proto` mà chưa kiểm tra file đã tồn tại (đã từng ghi đè mất `message ContractApplication`).
- Thêm `REQUIRED` cho field response vì "giống field kia", chưa đọc handler (đã sai ở `SubmitBorrowerWithdrawalDecisionResponse`).
- Tạo branch `-v2` để sửa PR đang mở.
- Làm 2 RPC trên cùng branch vì quên tạo branch mới.
- Sửa `core_service.proto` trong PR của một RPC; đăng ký RPC chưa merge.
- Push khi `git diff --stat origin/master` có file bị xoá lạ.
- Sửa file chunk_1 hoặc Core RPC không thuộc migrate khi chưa được yêu cầu.

## Red Flags

🚩 `grep -rn "console\." proto/core/rpc/` vẫn trả về file vừa sửa.
🚩 `git diff --stat origin/master` có dòng `-` lớn ở file không liên quan.
🚩 PR base là branch khác nhưng description không ghi "Stacked on #...".
🚩 Một quyết định đổi lần thứ 2 trong tuần (đã xảy ra: dùng lại console entity → tự định nghĩa; convert type → giữ type) — hỏi lại user trước khi làm hàng loạt.

## Reference

| File | Đọc khi |
|---|---|
| [references/proto-patterns.md](references/proto-patterns.md) | Viết proto: template Query/Write, entity enum-only, append, filter, JSON mẫu, validate, so field, Hướng A |
| [references/pr-templates.md](references/pr-templates.md) | Viết PR description: RPC mới, stack, follow-up, đăng ký lô, reply review |
| [references/decision-history.md](references/decision-history.md) | Cần hiểu vì sao PR cũ khác quy tắc, hoặc cần dẫn chứng PR khi reply review |
