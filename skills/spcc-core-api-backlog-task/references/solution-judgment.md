# Viết Solution từ nhận định

Mỗi RPC trong Solution gồm: **hướng xử lý**, **căn cứ** (cột sheet / proto / quyết định #), và **điểm cần confirm** (nếu có). Số quyết định `#N` lấy theo bảng "Quyết định đã chốt" của skill `spcc-migrate-console-rpc-to-core-proto`. Được phép ghi số quyết định trong task; không ghi tên skill.

## 1. Theo `Mapping Type (JP)`

| Mapping Type | Hướng xử lý viết trong Solution |
|---|---|
| `1対1レビュー` | Migrate 1-1: request/response dùng lại `console.entity` / filter Console, field, số, type, validate giống Console (#2, #3). Nếu response thực tế có nhiều entity (Case 2 = TRUE) thì xử lý như `分割` |
| `業務操作` | RPC ghi/thao tác: giữ nguyên shape request Console. Update giữ `field_mask` + cả entity + `effective` (#3). Không thêm idempotency (#5) |
| `分割` | Vẫn migrate. Response **chỉ giữ entity chính**, bỏ entity phụ, đánh số lại field (#8, #9). Request/filter giữ như Console. Liệt kê entity phụ bị bỏ (cột `Entities Included`) |
| `分割レビュー` | Như `分割`, thêm điểm **Cần confirm với JP** về hướng tách, trích `備考` làm căn cứ |
| `個別設計` | Đọc `個別設計の方針`: "このまま移行" / "このまま実装" → làm như `1対1レビュー`. Hướng thiết kế khác → mô tả hướng đó, ghi **Cần review thiết kế với JP trước khi implement** |
| Trống | Suy từ proto Console (Query hay Write, một hay nhiều entity), ghi rõ "Mapping Type trống trong sheet, nhận định từ proto" |

## 2. Tình huống bổ sung

| Tình huống | Viết thêm |
|---|---|
| Core RPC trùng tên đang active (ví dụ `GetDocuments`) | Hướng A: giữ entity Core, chỉ thêm field Console cần, field required bên Console thành `optional`, không đánh số lại (#6, #9) |
| Core RPC trùng tên đang comment-out, chưa ship (ví dụ `GetContracts`, `GetContractApplications`) | **Cần chọn hướng A/B trước khi implement** (#6); nêu ngắn hai hướng |
| Tên Console và Core khác nhau | Ghi `ConsoleName → CoreName` |
| Entity phụ cần RPC Core riêng (theo `備考` hoặc page cần dữ liệu đó) | Nêu RPC mới phát sinh, gộp vào task nếu cùng domain, hoặc ghi **Cần confirm** nơi đặt RPC |
| Field `deprecated = true` | Giữ nguyên như Console (#10); chỉ entity phụ deprecated mới bị bỏ |
| Console thiếu validate ID/enum | Chỉ được thêm `string.uuid` / `enum.defined_only`, có kiểm chứng giá trị FE gửi (#4). Chỉ nêu khi đã thấy rõ trong proto Console |
| `Feature Flags Used` có giá trị | Chỉ ghi **một dòng** cuối Solution (xem ví dụ §4): "Có FF liên quan — xem cột FF liên quan ở bảng RPC info". Không ghi hướng xử lý handler theo FF (FF có thể đã clean được) |
| `備考` có `⚠️ FE分散リスク` | Ghi rủi ro phía FE (số chỗ gọi trực tiếp) để FE task cân nhắc; BE không đổi hướng |
| `備考` "多数ドメインの集約" | **Cần confirm với JP**: giữ ReadModel tổng hợp hay tách theo domain |

## 3. Không viết

- "Thiết kế entity `Xxx` mới cho Core" (trái #2).
- "Thêm idempotency key", "refactor BitemporalQuery", "chuẩn hoá FieldMask" (#5).
- "Dùng `reserved` cho field bị bỏ" (#9).
- "Bỏ field deprecated" (#10).
- Nhận định không có căn cứ ("có lẽ", "chắc là") mà không đánh dấu **Cần confirm**.

## 4. Ví dụ

```markdown
- `GetBorrowers` — `分割`: migrate, response chỉ giữ `Borrower`; bỏ 7 entity phụ (`Contract`, `ContractApplication`, `Product`, `LoanSummary`, `TagAttachment`, `BorrowerProfile`, `EmailSuppression`), đánh số lại field (#8, #9). Request/filter giữ như Console.
- `GetEmailSuppressions` (RPC mới phát sinh): Core RPC riêng cho `EmailSuppression` tách khỏi `GetBorrowers`, vì page popup-contentsetting-dialog cần dữ liệu này. Không có Console RPC tương ứng.
  - **Cần confirm**: request/filter (theo `borrower_id`?) do không có Console làm mẫu.
- Có FF liên quan — xem cột `FF liên quan` ở bảng RPC info.
```
