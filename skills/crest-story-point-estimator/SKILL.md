---
name: crest-story-point-estimator
description: Ước lượng Fibonacci Story Point (1,2,3,5,8,13,21,50,100) cho ticket trong dự án CREST dựa trên tiêu chí phạm vi ảnh hưởng, độ phức tạp kỹ thuật và độ không chắc chắn. Dùng khi được yêu cầu "estimate story point", "ước lượng điểm ticket CREST", "point ticket này bao nhiêu", hoặc khi refine backlog/sprint planning cho dự án CREST.
---

# CREST Story Point Estimator

## Khi nào dùng

- User đưa 1 hoặc nhiều ticket CREST (URL Jira `CRES-xxxx` hoặc mô tả công việc) và hỏi nên estimate bao nhiêu điểm.
- User yêu cầu review/estimate lại point đã có.
- Sprint planning / backlog refinement cho dự án CREST.

## Nguồn tiêu chí

Tham khảo wiki Backlog: `04_Rules/CREST Project Fibonacci Story Point Estimation Criteria`
(https://teq-dev.backlog.com/alias/wiki/1228328)

## Quy trình thực hiện

### Phase 1: Thu thập thông tin ticket

- Nếu có URL Jira/Backlog → lấy title, description, comment (dùng tool tương ứng: Jira/Backlog MCP).
- Nếu chỉ có mô tả text → hỏi lại nếu thiếu thông tin quan trọng (FE/BE, số màn hình, tích hợp bên ngoài...).

### Phase 2: Phân tích theo 3 trục

- **Phạm vi ảnh hưởng**: số file/màn hình bị ảnh hưởng, số môi trường/account.
- **Độ phức tạp kỹ thuật**: có pattern tương tự để copy không? cần thiết kế mới không? có Workflow/phê duyệt không?
- **Độ không chắc chắn**: yêu cầu đã rõ ràng chưa? có phụ thuộc vendor/team ngoài không?

### Phase 3: Đối chiếu bảng tiêu chí

| Điểm | Câu hỏi chốt (Yes → chọn mức này) |
|---|---|
| 1 | Biết ngay vị trí cần sửa, 1 file, không cần điều tra? |
| 2 | Có implementation tương tự để tham khảo, chỉ FE hoặc chỉ BE? |
| 3 | Nhiều vị trí/file/môi trường nhưng lặp lại cùng 1 pattern? |
| 5 | Cần cả FE+BE, mở rộng tính năng có sẵn, tối đa 1 màn hình mới? |
| 8 | Nhiều màn hình mới/cải tổ lớn, đụng vào xác thực/phân quyền? |
| 13 | Tạo flow màn hình mới hoàn chỉnh, có tích hợp Workflow phê duyệt? |
| 21 | Tích hợp nhiều hệ thống, quản lý trạng thái phức tạp, cần thiết kế từ đầu? |
| 50 | Là một nhóm tính năng (Epic), nên cân nhắc chia nhỏ? |
| 100 | Tích hợp vendor ngoài, yêu cầu còn thay đổi liên tục, bắt buộc chia nhỏ? |

So sánh tương đối với **ticket tham khảo** cùng mức điểm (CRES-13585, CRES-12711, CRES-13654, CRES-13401, CRES-11475, CRES-12911, CRES-13155, CRES-10161, CRES-10589, CRES-6474, CRES-775).

### Phase 4: Áp dụng quy tắc vận hành

- Nếu phân vân giữa 2 mức → chọn mức cao hơn (độ không chắc chắn cao hơn = điểm cao hơn).
- Nếu ước tính ≥ 50pt → đề xuất chia nhỏ ticket thay vì giữ nguyên điểm lớn.
- Nhắc rằng điểm là đo **độ phức tạp/phạm vi tương đối**, không phải số ngày làm việc thuần túy (dù mỗi mức có khung thời gian tham khảo).

### Phase 5: Output cho user

- Điểm đề xuất (1 con số Fibonacci).
- Giải thích ngắn gọn theo 3 trục (phạm vi / kỹ thuật / không chắc chắn).
- Ticket tham khảo gần nhất để so sánh.
- Nếu ≥50pt: gợi ý cách chia nhỏ thành sub-ticket.
- Nếu thiếu thông tin để quyết định giữa 2 mức: hỏi lại user (1 câu hỏi, có choices là các mức điểm nghi ngờ).

## Lưu ý

- Không tự bịa thêm tiêu chí ngoài wiki; nếu ticket có đặc thù không khớp bảng, nêu rõ giả định đang dùng.
- Khi estimate nhiều ticket cùng lúc, trình bày dạng bảng: `Ticket | Điểm | Lý do ngắn`.
- Có thể dùng trực tiếp Backlog/Jira MCP tool để lấy nội dung ticket thay vì yêu cầu user paste tay.

## Anti-patterns to Avoid

- ❌ Không estimate dựa trên "có bao nhiêu ngày" mà dựa vào độ phức tạp tương đối.
- ❌ Không thêm tiêu chí/quy tắc ngoài wiki CREST.
- ❌ Không estimate ticket ≥50pt mà không gợi ý chia nhỏ.
- ❌ Không để user chọn mà không có lý do tại sao mỗi mức.

## Red Flags

🚩 Estimate giữa 2 mức mà không rõ → hỏi lại user (dùng AskUserQuestion).
🚩 Ticket ≥50pt → luôn đề xuất chia nhỏ.
🚩 Thiếu thông tin quan trọng (FE/BE scope, tích hợp external?) → hỏi trước khi estimate.
