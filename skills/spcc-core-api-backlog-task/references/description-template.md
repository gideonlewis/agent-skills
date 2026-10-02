# Template description BE Task

Thứ tự mục cố định: Solution → RPC info → Expected → Evidence. **Không có `## Description/Overview` và `## Target`** (chunk cha đã thể hiện qua parent issue; RPC và page nằm trong Solution và bảng RPC info).

```markdown
## Solution

- `<RPC1>` — `<Mapping Type>`: <hướng xử lý> (<căn cứ: #N / cột sheet>).
  - <ghi chú phụ: entity phụ bị bỏ, validate bổ sung...>
- `<RPC2>` (gộp thêm — cùng cụm entity): <hướng xử lý>.
- **Cần confirm**: <điểm chưa đủ căn cứ, hỏi ai (user / JP)>.
- Có FF liên quan — xem cột `FF liên quan` ở bảng RPC info. (chỉ khi bảng có FF)
- Ngoài task: `<RPC>` đã có ở <SPCC-xxxx>; <việc không làm trong task này>.

## RPC info (sheet CoreAPIs)

| RPC | Mapping Type (JP) | FF liên quan | 備考 | 個別設計の方針 |
|---|---|---|---|---|
| `<RPC1>` | <giá trị> | `<ff1>`, `<ff2>` | <nguyên văn, xuống dòng → dấu cách> | — |

## Expected

- Core RPC `<RPC1>`, `<RPC2>` được thêm vào `CoreService` (cred-proto), request/response khớp Console về field, số, type, validate; khác biệt chỉ nằm trong các quyết định đã chốt và được liệt kê trong PR.
- `make lint`, `make format/check`, `make gen` pass; PR có label `release:minor`.
- <Kết quả riêng, ví dụ: response `GetBorrowers` chỉ còn `Borrower`; hướng A/B đã được chốt và ghi trong PR>.
- Các điểm cần confirm đã có câu trả lời, hoặc nằm trong mục "Points to confirm" của PR.

## Evidence

- PR/branch liên quan sẽ đính kèm khi implement.
```

## Quy tắc từng mục

| Mục | Quy tắc |
|---|---|
| Solution | Theo `solution-judgment.md`. Mỗi RPC một bullet, thứ tự giống bảng RPC info. Hiện trạng Core cần biết (RPC đã có trên master, PR đang mở trái quyết định) ghi ngay trong bullet của RPC đó. "Ngoài task" để cuối, bỏ nếu không có |
| RPC info | Ô trống → `—`. Nhiều FF cách nhau bằng dấu phẩy, mỗi FF một backtick. Giữ nguyên văn tiếng Nhật |
| Expected | Kết quả kiểm chứng được. Không nhắc skill, AI hay công cụ. Không hứa việc ngoài task (handler azuki, switch azuki-app, rollout FF) trừ khi user nói task bao gồm |
| Evidence | Mặc định một dòng như template; có PR liên quan (cột `PR Link` hoặc PR đang mở/đã merge) thì liệt kê link kèm trạng thái |

## Cập nhật task đã có

1. Đọc description hiện tại.
2. Xoá `Description/Overview` và `Target`; thông tin còn cần (hiện trạng Core, PR) chuyển vào Solution hoặc Evidence.
3. Viết lại Solution theo `solution-judgment.md`; giữ các ghi chú cụ thể còn đúng, sửa ghi chú trái quyết định đã chốt.
4. Thay bảng RPC info bằng dữ liệu sheet mới nhất.
5. Bỏ mọi câu nhắc tên skill trong Expected.
6. Summary không còn khớp RPC (thêm/bớt RPC) → đề xuất summary mới trong bản nháp.
7. Báo user diff theo từng task: mục nào đổi, ghi chú nào bị sửa hoặc xoá.
