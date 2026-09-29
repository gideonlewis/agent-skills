# Quy tắc rã task

## 1. Lọc RPC

| Trường hợp | Xử lý | Ghi ở đâu |
|---|---|---|
| `Migrate to Core?` = `移行しない` | Loại | Báo cáo cho user |
| `BE Status` = `Already` / `Done` | Loại | Báo cáo cho user |
| `GetFeatureFlags` | Loại (Core đã có sẵn) | Không ghi |
| `個別設計の方針` = "不要" / "消える機能…" / "…消す" | Loại, không migrate | Báo cáo cho user |
| RPC đã thuộc task của chunk khác | Không tạo lại | Mục "Ngoài task" của task cùng domain |
| RPC mới phát sinh do tách entity phụ (ví dụ `GetEmailSuppressions`) | Đưa vào task của RPC gốc | Solution + bảng RPC info |

## 2. Nhóm task

1. Nhóm theo **Domain**, rồi theo **cụm entity** (cùng entity chính, ví dụ `Cancellation`, `Delegation`, `Role`).
2. **Tối đa 5 RPC** mỗi task. Cụm lớn hơn thì chia theo Query / Write, hoặc theo entity con.
3. RPC lẻ cùng cụm entity với một task đã có trong chunk → **gộp thêm**, và ghi `(gộp thêm — cùng cụm entity)` sau tên RPC.
4. **Tách task riêng** cho:
   - `個別設計` có hướng thiết kế riêng (ví dụ "entity Get系全てにCount APIを生やす").
   - `分割レビュー`, khi cần review hướng tách entity với JP.
   - Core RPC trùng tên đang comment-out, khi cần user/JP chọn hướng A/B.
   - RPC mà `備考` cảnh báo rủi ro lớn (`⚠️ FE分散リスク`, "多数ドメインの集約").
5. Thứ tự task trong bản nháp: task chặn page (blocking) trước, rồi theo thứ tự page trong `MigPages`. Không dùng `Migration Execution Order`.

## 3. Bản nháp trình user

```text
chunk_N (SPCC-xxxx) — <số page> page, <số RPC> RPC cần làm

| # | Summary | RPC | Ghi chú |
|---|---|---|---|
| 1 | [BE] contract — Cancellation (4 RPC) | `GetCancellations`, ... | — |
| 2 | [BE] contract — GetContracts (cần chọn hướng A/B) | `GetContracts` | Core RPC comment-out |

Loại: `GetFeatureFlags` (có sẵn), `XxxYyy` (移行しない)
Đã có ở task khác: `GetBorrowers` → SPCC-3676
```

Kèm description đầy đủ của từng task ngay sau bảng.
