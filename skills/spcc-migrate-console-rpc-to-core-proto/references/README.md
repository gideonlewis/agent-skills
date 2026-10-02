# References — spcc-migrate-console-rpc-to-core-proto

| File | Nội dung |
|---|---|
| `design-decisions.md` | Phân loại RPC, entity chính, field deprecated, việc ngoài phạm vi, Write RPC, trùng tên với Core RPC có sẵn, quyền hạn, nhóm không làm, lịch sử quyết định. Đọc đầu mỗi batch. |
| `proto-authoring-rules.md` | Template chunk_1 (Query, Write), filter, JSON mẫu, validate, annotation, `core_service.proto`, Hướng A, lệnh `cmp_fields`, buf lint. Đọc khi viết proto. |
| `existing-core-rpcs.md` | Quy trình cho Console RPC trùng tên với Core RPC đã có (không thuộc chunk_1): phân loại đang chạy / chưa ship, ghép field, chỗ phải dừng hỏi, bảng đối chiếu `GetDocuments` / `GetContracts` / `GetContractApplications`. |
| `migration-report.md` | Format migration report — đầu ra của skill, đầu vào của skill tạo PR. Đọc trước khi kết thúc batch. |
