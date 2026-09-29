# Nguồn dữ liệu và ID

## 1. Sheet `CoreAPI`

Spreadsheet id: `1Jyq5AlOxA25aSU_iW9fs9md0U7hx1csUrJuUXNzKQao` (đọc qua `google_sheets-get_values`).

### Tab `MigPages`

| Cột | Ý nghĩa |
|---|---|
| Order | Mức ưu tiên (`P1`..`P5`); dòng header chunk có Order + ChunkName |
| ChunkName | Tên flag `enable_console_api_to_core_api_migrate_chunk_N` (dòng header) kèm link Jira |
| PageURL, Additional Page Subject info | Page thuộc chunk |
| Page Complexity | Độ phức tạp page |
| Console RPC | RPC page gọi (nhiều dòng trong một ô) |
| Entity Used, Core RPC, RPC Usage | Entity và Core RPC tương ứng |
| DEV POINT, QA/QC SP, Ready to Migrate, Status, Assignee | Theo dõi tiến độ, không dùng để rã task |

Các dòng page nằm dưới dòng header chunk cho tới header chunk kế tiếp.

### Tab `CoreAPIs`

| Cột | Dùng trong task |
|---|---|
| Domain | Nhóm task, tiền tố summary |
| Console RPC (As is) / Core RPC (To be) | Tên RPC; khác tên thì ghi `Console → Core` |
| Migrate to Core? (JP) | `移行しない` → loại |
| Mapping Type (JP) | `1対1レビュー`, `業務操作`, `分割`, `分割レビュー`, `個別設計` → hướng xử lý (`solution-judgment.md`) |
| 全て同じEntityを返すか, Case 2 (Multi-entity)?, Entities Included (case 2) | Phát hiện RPC trả nhiều entity |
| BE Status | `Already` / `Done` → loại |
| PR Link | Đã có PR → ghi vào Evidence |
| Feature Flags Used | Cột `FF liên quan` của bảng RPC info |
| Note (TEQ) | Tham khảo, không copy vào task |
| 備考, 個別設計の方針 | Copy nguyên văn vào bảng RPC info, đồng thời dùng làm căn cứ cho Solution |
| Migration Execution Order | **Không dùng** |

RPC mới phát sinh (Core RPC không có Console tương ứng, không có dòng trong sheet): vẫn đưa vào bảng, `Mapping Type` ghi `— (RPC mới, không có trong sheet)`.

## 2. Backlog (TEQ)

| Mục | Giá trị |
|---|---|
| Project | `SPCC` (id `149054`) |
| Issue type | BE Task `946464` (FE Task `946463`, JP User Story `825231`) |
| Category | Core API `521051` |
| Priority | Normal `3` |
| Parent | Ticket chunk |

Ticket chunk P1 đã có:

| Chunk | Ticket | Issue id |
|---|---|---|
| chunk_2 | SPCC-3617 | 45128893 |
| chunk_8 | SPCC-3618 | 45129261 |
| chunk_32 | SPCC-3619 | 45129660 |
| chunk_35 | SPCC-3620 | 45129808 |
| chunk_36 | SPCC-3621 | 45129901 |
| chunk_37 | SPCC-3622 | 45130004 |
| chunk_41 | SPCC-3623 | 45130109 |
| chunk_44 | SPCC-3624 | 45130192 |
| chunk_45 | SPCC-3626 | 45130331 |

Chunk khác: tìm bằng `teq_backlog-get_issues` (keyword = tên chunk, category `521051`).

**Khử trùng RPC**: lấy toàn bộ BE Task category Core API (`get_issues` với `issueTypeId=946464`, `categoryId=521051`, phân trang), rồi trích tên RPC trong backtick ở mục Solution. RPC đã có → không đưa vào task mới; nếu page của chunk hiện tại cũng cần RPC đó thì ghi ở mục "Ngoài task" (xem `description-template.md`).

## 3. Field khi tạo task

| Field | Giá trị |
|---|---|
| `projectId` | `149054` |
| `issueTypeId` | `946464` |
| `categoryId` | `[521051]` |
| `priorityId` | `3` |
| `parentIssueId` | issue id của ticket chunk |
| `summary` | `[BE] <domain> — <RPC hoặc nhóm RPC> (<ghi chú ngắn nếu cần>)` |
| `description` | theo `description-template.md` |
| assignee, milestone, start/due date | Để trống, trừ khi user chỉ định |

## 4. Repo `cred-proto`

- `proto/core/rpc/core_service.proto`: RPC trùng tên đang active (đã ship, ví dụ `GetDocuments` cho minazuki), hay đang bị comment-out (chưa ship, ví dụ `GetContracts`, `GetContractApplications`).
- `proto/console/rpc/<rpc>.proto`: response có entity phụ hay không, và có entity `deprecated` hay không.

Đường dẫn repo không có → bỏ bước này và ghi **Cần confirm** hiện trạng Core RPC trong Solution.
