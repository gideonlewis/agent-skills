---
name: spcc-review-console-rpc-to-core-proto
description: >
  Review PR trong repo cred-proto migrate Console RPC sang Core proto — bất kể
  PR do skill `spcc-core-api-proto-migration-workflow-v2`, người khác hay AI
  agent khác viết. Đối chiếu field-by-field với proto Console gốc theo các quyết
  định đã chốt: Core tự định nghĩa core.entity / core.rpc Filter (không import
  console), giữ nguyên type Console (Money, PhoneNumber, PostalAddress...), filter
  mirror đủ field, đánh số entity liên tục nhưng enum giữ số Console, chỉ bỏ
  side-load trong response, field deprecated giữ nguyên, chỉ bổ sung string.uuid
  / enum.defined_only có kiểm chứng, response REQUIRED chỉ khi handler luôn set,
  1 RPC 1 PR và core_service.proto đăng ký theo lô. Dùng khi được yêu cầu
  "review PR", "check PR", "kiểm tra PR này" kèm link/số PR cred-proto liên quan
  Core API migration, hoặc khi cần xác định PR migrate cũ có cần PR follow-up
  không. Không dùng để tự viết proto migrate (xem
  `spcc-core-api-proto-migration-workflow-v2`), và không dùng cho review code
  Go ở azuki hay code TypeScript ở azuki-app.
---

# Review PR migrate Console RPC → Core proto

## Khi nào dùng

Có 1 hoặc nhiều PR trong `cred-proto` thêm Core RPC tương ứng Console RPC, cần biết đúng hay sai so với Console gốc trước khi merge. PR do chính skill `spcc-core-api-proto-migration-workflow-v2` tạo cũng nên review lại bằng skill này.

Skill này chỉ làm 1 việc hẹp: đối chiếu **field-by-field** giữa Console và Core theo quy tắc riêng của đợt migrate. Review chung (logic Go, security...) dùng skill `code-review`.

## Nguồn quy tắc

Quy tắc chuẩn nằm ở skill `spcc-core-api-proto-migration-workflow-v2`:

- `SKILL.md` mục "Quyết Định Đã Chốt": bảng 13 quyết định
- `references/proto-patterns.md`: template, file enum-only, append, filter, validate (§9), Hướng A (§8), lệnh so field (§10), `core_service.proto` (§11)
- `references/pr-templates.md`: template PR (RPC mới, stack, follow-up, đăng ký lô)
- `references/decision-history.md`: dòng thời gian quyết định và PR minh chứng — dùng để biết PR được viết trước hay sau quyết định

Đọc bảng "Quyết Định Đã Chốt" trước khi review. PR mâu thuẫn với bảng đó là finding, kể cả khi PR được viết trước ngày quyết định (khi đó finding là "cần PR follow-up", không phải lỗi của tác giả). **Không đưa ra quy tắc không có trong bảng** (đã sai 1 lần: yêu cầu `Money` → `int64` ở #2350 khi quy tắc đó chưa từng được chốt).

Skill v1 `spcc-migrate-console-rpc-to-core-proto` còn quy tắc cũ (dùng lại console entity) — không lấy làm chuẩn.

## Nguyên tắc nền

- **CI pass không chứng minh gì về nội dung.** `buf lint` chỉ bắt cú pháp và việc có comment. Lỗi thật đều nằm ở tầng đối chiếu với Console.
- **Luôn mở file Console gốc** (rpc + entity + filter). Chỉ đọc diff thì không biết field nào bị bỏ, đổi số hay đổi type.
- **Không lấy Core RPC dựng cho minazuki/Platform Console/macaron làm tiền lệ** (`get_credit_cards.proto`, `get_contracts.proto`, `update_borrower.proto`...). Mẫu đúng: PR đã merge theo v2 (#2288, #2297, #2351).
- **Mọi finding kèm bằng chứng**: đường dẫn file + dòng của Console proto, Core proto, hoặc code azuki/azuki-app.

## Quy trình

1. **Lấy ngữ cảnh PR:**

   ```bash
   gh pr view <n> --json title,author,headRefName,baseRefName,isDraft,files,labels,body,mergeable,mergeStateStatus
   gh pr diff <n>
   gh pr checks <n>
   gh api repos/Finatext/cred-proto/pulls/<n>/comments -q '.[]|.user.login+" @"+.path+": "+.body'
   ```

2. **Base branch.** Base khác `master` → PR stack. Xem PR nền, ghi thứ tự merge; đừng báo "thiếu định nghĩa X" khi X nằm ở PR nền.
3. **Checkout nhánh PR để chạy lệnh**, không làm bẩn worktree của user:

   ```bash
   git fetch origin <headRefName> master
   git worktree add /tmp/review-<n> origin/<headRefName>
   ```

4. **Với từng RPC:** tìm file Console (`grep -ln "message <Rpc>Request" proto/console/rpc/`), chạy `cmp_fields` cho rpc, entity, filter, rồi đi qua `references/checklist.md` theo thứ tự.
5. **Kiểm chứng bằng code** cho các điểm cần: validate bổ sung (azuki handler + azuki-app call site), `REQUIRED` ở response (handler set ở mọi nhánh), ID mồ côi. Không tìm thấy code tương ứng → ghi "chưa verify được", không mặc định đúng hay sai.
6. **Report** theo format bên dưới. Dọn worktree: `git worktree remove /tmp/review-<n>`.

## Format report

Xếp theo mức độ:

| Mức | Ý nghĩa | Ví dụ |
|---|---|---|
| **Blocker** | Sai hợp đồng dữ liệu, breaking change, lộ dữ liệu, validate làm request đang chạy bị lỗi | Đổi số field Core RPC đang chạy cho minazuki; `string.uuid` trên `string` thường; sửa `proto/console/**`; ghi đè file `core/entity` có sẵn làm mất message |
| **Cần sửa** | Lệch quyết định đã chốt | Import `console/entity/*` / `console/rpc/filter.proto`; đổi `PhoneNumber` → `string`, `Money` → `int64`; bỏ field filter; bỏ `field_mask`; thêm `required` Console không có; `REQUIRED` ở response khi handler không set; sửa `core_service.proto` trong PR 1 RPC |
| **Nên sửa** | Style, tài liệu | Comment tiếng Nhật mới bị viết tiếng Anh; thiếu JSON mẫu; mô tả PR thiếu mục; còn `reserved` trong entity Core |
| **Cần hỏi JP** | Không phải lỗi của PR, nhưng cần xác nhận | ID tạo ra nhưng không trả về; field response mới của Hướng A cũng trả cho minazuki; filter cho RPC không có Console tương ứng |

Mỗi finding: file:dòng, Console nói gì, Core nói gì, quyết định nào bị lệch, cách sửa. Điểm đã kiểm tra và đúng cũng nêu ngắn để tác giả không phải tự kiểm lại.

Nhiều finding "Cần sửa" cùng gốc (PR làm theo quy tắc cũ) → gom lại, đề xuất 1 PR follow-up (skill `spcc-core-api-proto-migration-workflow-v2`, mẫu `pr-templates.md §3`) thay vì liệt kê rời rạc.

## Anti-patterns

- Kết luận "field X nên bỏ vì là dead field / vì domain đó Core chưa có RPC" — Console có thì Core giữ; enum domain khác vào file enum-only.
- Khen PR "đẹp hơn Console" khi PR đổi type hoặc tách field (`YearMonth` → `google.type.Date`, tách `PostalAddress`, `Money` → `int64`) — là finding.
- Coi import `console/entity/*` là đúng vì "giống chunk_1" — quy tắc đó đã thay ngày 2026-09-28.
- Đề xuất thêm validate ngoài 2 rule được phép, hoặc thêm field vào response "cho hữu ích" — ghi thành câu hỏi, không phải yêu cầu sửa.
- Đưa quy tắc không có trong bảng quyết định vào finding.
- Review PR stack mà không xem base branch.
- Chỉ đọc diff, không mở Console gốc.
