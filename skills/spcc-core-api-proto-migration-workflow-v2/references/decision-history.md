# Lịch sử quyết định

Đọc khi cần hiểu vì sao một PR cũ khác quy tắc hiện tại, hoặc cần dẫn chứng PR khi reply review. Quy tắc hiện hành luôn là bảng "Quyết Định Đã Chốt" trong `SKILL.md`.

## Dòng thời gian

| Ngày | Quyết định | Nguồn | Trạng thái |
|---|---|---|---|
| 2026-07-30 | chunk_1 (`create_role.proto`, `get_borrower_expatriations.proto`) làm mẫu, import `console/entity/*` | JP (haruki.nazawa) | Còn giữ file chunk_1; quy tắc import **đã thay** |
| 2026-09-24 | Không thêm idempotency key cho Core Write RPC đợt này | user | Còn hiệu lực |
| 2026-09-25 | Dùng lại `console.entity` / `console.rpc` Filter như chunk_1 | user | **Đã thay** 2026-09-28 |
| 2026-09-25 | Chỉ được thêm `string.uuid` / `enum.defined_only` Console bị sót, có kiểm chứng FE | Le, Yuya Sakano, Misato Kano, Kaz Togo (Mattermost) | Còn hiệu lực |
| 2026-09-25 | RPC nhiều entity vẫn migrate, chỉ giữ entity chính; đánh số lại, không `reserved`; field deprecated giữ nguyên | user, Misato Kano ("フィールド番号の振り直しはやってもいい") | Còn hiệu lực |
| 2026-09-25 | Core RPC trùng tên: `GetDocuments` Hướng A; `GetContracts` / `GetContractApplications` dừng hỏi | hirose.hikaru | Còn hiệu lực (Hướng A chưa thử theo v2) |
| 2026-09-28 | **Core tự định nghĩa `core.entity.*` / `core.rpc.*Filter`**, không import Console | mirror-kt, sakano-yuya (review #2268, #2288, #2289–#2291) | Còn hiệu lực |
| 2026-09-28 | **Mỗi RPC một PR**; `core_service.proto` đăng ký theo lô ở PR riêng | user (sau conflict #2281 ↔ #2282) | Còn hiệu lực |
| 2026-09-28 | File dùng chung dồn vào 1 PR gốc, PR khác stack | sakano-yuya ("filter.go ... để ở PR cuối or tách 1 PR riêng") | Còn hiệu lực |
| 2026-09-28 | Filter mirror đủ field Console; enum domain khác → file enum-only | user (hỏi lại khi #2287 bỏ 5 field) | Còn hiệu lực |
| 2026-09-28 | Giữ comment Console (kể cả `TODO:`) khi field không đổi; comment sai → theo `azuki-app/locales/ja/enum.json` | user (#2287) | Còn hiệu lực |
| 2026-09-29 | **Giữ type Console** (`Money`, `PhoneNumber`, `PostalAddress`...); không convert | user (review #2350 → #2351) | Còn hiệu lực |
| 2026-09-29 | Response `string.uuid` + `REQUIRED` chỉ khi đã đọc handler | user (#2281 `SubmitBorrowerWithdrawalDecisionResponse`, #2298 `SubmitReviewResponse`) | Còn hiệu lực |
| 2026-10-02 | **Giữ `oneof` như Console** (kể cả chỉ 1 field), không đổi thành `optional` | user (sửa lỗi của #2287 ở #2374) | Còn hiệu lực; **thay** quy tắc "`oneof` 1 field → `optional`" trước đó (không có thảo luận review nào xác nhận) |

## PR minh chứng

| PR | Nội dung | Bài học |
|---|---|---|
| #2263 → #2281 | Borrower profile (4 RPC), import `console.entity.BorrowerProfile` | Merged theo quy tắc cũ; sửa lại bằng #2351 |
| #2268 → #2287 + #2288 | Gộp 2 RPC 1 PR, reviewer yêu cầu tự định nghĩa entity | Tách 1 RPC 1 PR; `Borrower` mirror sang `core.entity` |
| #2287 | `GetBorrowers`, lần đầu bỏ 5 field filter + convert type | Bỏ field filter không có lý do → phải mirror đủ; convert type bị revert ở #2351 |
| #2281 ↔ #2282 | Hai PR cùng thêm rpc vào `core_service.proto` → conflict | Lý do tách đăng ký thành PR lô |
| #2289, #2290, #2291 | Review cluster A, cả 3 cùng sửa `filter.proto` | Dồn `filter.proto` vào #2291, 2 PR còn lại stack |
| #2292–#2295 | Write RPC cụm review flow | `ReviewFlowStep` của request là message `core.rpc` (Console cũng ở `console.rpc`), không phải entity |
| #2296, #2297, #2298 | Review cluster B; #2297 là PR gốc (`ReviewResult`, `ReviewFilter`, `ReviewFlowFilter`) | Chọn PR gốc là RPC mà PR khác phụ thuộc nhiều nhất; #2298 thêm `REQUIRED` sau khi đọc handler |
| #2350 | `GetBorrowerProvidedDocuments` (tác giả khác), review bằng v2 | Import type Core đã có (`BorrowerStatus`, `CoreDocumentKey`) là đúng; không áp quy tắc convert type chưa được chốt |
| #2351 | Revert convert type của `Borrower`; tạo `core.entity` cho BorrowerProfile / BorrowerAssociate; `ReviewRequestParams` append vào `review_request.proto` | Mẫu follow-up nhiều nhóm; mẫu append file có sẵn |
| #2352 | Đăng ký 10 RPC đã merge | Mẫu PR lô; RPC chưa merge để lại PR lô sau |
| #2374 | Khôi phục `oneof` cho `BorrowerFilter.identity_verification_status` (#2287 đã đổi thành `optional`) | Mẫu follow-up 1 field; đổi `oneof`↔`optional` làm đổi kiểu sinh ra (Go, TS) nên azuki đang dùng field phải sửa converter sau khi bump |

## Lỗi đã gặp (đừng lặp lại)

- Làm cụm B trên branch cụm A → phải stash, tạo branch mới, pop, resolve.
- `Write` đè `core/entity/contract_application.proto` → mất `message ContractApplication`; khôi phục từ `origin/master` rồi append.
- Tạo branch `-v2` để sửa PR đang mở → phải `git branch -f` về branch gốc và force-push.
- Thêm `REQUIRED` cho `SubmitBorrowerWithdrawalDecisionResponse.borrower_withdrawal_decision_id` mà handler không set → revert (amend).
- Khẳng định "Money → int64" trong review #2350 khi quy tắc đó chưa từng được chốt → sai; chỉ nêu quy tắc có trong bảng quyết định.
- Local `master` cũ → danh sách RPC cần đăng ký sai; luôn so với `origin/master` sau `git fetch`.
- Đơn giản `oneof` 1 field thành `optional` (#2287) khi chưa ai yêu cầu → kiểu sinh ra khác Console (Go: con trỏ thay vì interface; TS: `?:` thay vì `{ case, value }`), phải sửa lại ở #2374. Chỉ đổi shape khi quy tắc có trong bảng quyết định VÀ có nguồn (PR/review) xác nhận.
