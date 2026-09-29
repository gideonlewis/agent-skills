---
name: azuki-core-api-backlog-task
description: >
  Rã một chunk migrate Console API → Core API (feature flag
  enable_console_api_to_core_api_migrate_chunk_N) thành các BE Task trên
  Backlog TEQ (project SPCC) và viết description cho từng task gồm
  Solution, RPC info (sheet CoreAPIs), Expected, Evidence. Solution được viết
  từ nhận định dựa trên sheet CoreAPIs/MigPages, proto hiện có và các quyết
  định migrate đã chốt với JP. Dùng khi user nói "rã task chunk_N", "tạo BE
  task cho chunk...", "viết/cập nhật description task Backlog", "rà soát task
  đã rã". Không viết proto, không tạo PR.
---

# Rã task và viết description Backlog cho Core API migration

## Khi Nào Dùng

- **Rã task mới**: user đưa một hoặc nhiều chunk (ví dụ `chunk_32`, hoặc "các chunk P1 còn lại") và muốn tạo BE Task con dưới ticket chunk.
- **Cập nhật description**: user muốn viết lại description của task đã có theo format hiện tại (bỏ `Description/Overview` và `Target`, bổ sung RPC info, sửa ghi chú đã lỗi thời).

Không dùng để viết proto (`azuki-migrate-console-rpc-to-core-proto`) hay tạo PR (`azuki-core-api-migration-pr`).

## Nguồn Dữ Liệu

Chi tiết ID, cột và cách đọc: `references/data-sources.md`.

| Nguồn | Dùng để |
|---|---|
| Sheet `CoreAPI` tab `MigPages` | Danh sách page và Console RPC của chunk, thứ tự ưu tiên (P1..P5) |
| Sheet `CoreAPI` tab `CoreAPIs` | Thông tin từng RPC: `Migrate to Core? (JP)`, `Mapping Type (JP)`, Case 2, entity phụ, `BE Status`, `Feature Flags Used`, `備考`, `個別設計の方針` |
| Backlog SPCC | Ticket chunk cha, các BE Task đã có (để khử trùng RPC giữa các chunk) |
| Repo `cred-proto` | `core_service.proto` (Core RPC trùng tên đã có hay chưa, còn comment-out hay không), proto Console tương ứng |
| Các quyết định đã chốt | Bảng "Quyết định đã chốt" trong skill `azuki-migrate-console-rpc-to-core-proto`, tóm tắt cho task ở `references/solution-judgment.md` |

**Không dùng** cột `Migration Execution Order`.

## Quy Trình

1. **Xác định chunk**: lấy dòng header chunk trong `MigPages` (Order, ChunkName = flag, link Jira) và ticket chunk cha trên Backlog. Không tìm thấy ticket cha → hỏi user.
2. **Gom RPC**: toàn bộ Console RPC của các page trong chunk (cột `Console RPC`), bỏ trùng.
3. **Lọc** theo `references/breakdown-rules.md` §1:
   - Bỏ RPC `移行しない`, RPC `BE Status` = `Already`/`Done`, và `GetFeatureFlags`.
   - Bỏ RPC đã nằm trong một BE Task của chunk khác (mỗi RPC chỉ thuộc một task, là task của chunk đầu tiên cần nó).
4. **Tra thông tin RPC** trong `CoreAPIs`, và kiểm tra `core_service.proto` xem RPC trùng tên đã tồn tại chưa.
5. **Nhóm task** theo `references/breakdown-rules.md` §2: theo domain/cụm entity, tối đa 5 RPC một task, RPC `個別設計` hoặc cần quyết định A/B tách task riêng.
6. **Viết description** theo `references/description-template.md`. Phần Solution viết theo `references/solution-judgment.md`: mỗi RPC một hướng xử lý cụ thể, rút ra từ sheet, proto và quyết định đã chốt, kèm điểm cần confirm nếu có.
7. **Trình bản nháp cho user**: bảng task (summary, RPC, ghi chú) và description đầy đủ. **Chờ user đồng ý** rồi mới tạo hoặc cập nhật trên Backlog.
8. **Tạo / cập nhật** task (field Backlog: `references/data-sources.md` §3).
9. **Báo cáo**: link task, RPC mỗi task, RPC bị loại và lý do, câu hỏi còn mở.

## Nguyên Tắc Viết

- Viết tiếng Việt. Tên RPC, entity, field, flag đặt trong backtick. Giá trị copy từ sheet (tiếng Nhật) giữ nguyên văn.
- **Không có mục `Description/Overview` và `Target`.**
- Solution là **nhận định có căn cứ**: mỗi hướng xử lý phải dẫn được về một nguồn (cột sheet, proto, hoặc quyết định đã chốt). Không đủ căn cứ thì ghi thành điểm **Cần confirm**, không tự quyết.
- Expected chỉ mô tả kết quả kiểm chứng được. **Không nhắc tên skill** hay công cụ AI.
- Không ghi thông tin trái quyết định đã chốt, ví dụ "thiết kế entity Core mới" (trái #2) hay "thêm idempotency key" (trái #5).
- Task đã có mà ghi chú lỗi thời → khi cập nhật thì sửa luôn, và liệt kê các chỗ đã sửa trong báo cáo.

## Red Flags

🚩 Tạo hoặc cập nhật ticket khi user chưa duyệt bản nháp.
🚩 Một RPC xuất hiện trong hai task.
🚩 Sắp xếp hay chọn task dựa vào `Migration Execution Order`.
🚩 Solution chỉ chép lại `Mapping Type` mà không nói sẽ làm gì với RPC.
🚩 Expected có "tuân theo skill ...".
