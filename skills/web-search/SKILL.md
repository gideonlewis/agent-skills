---
name: web-search
description: >
  Dùng skill này khi người dùng yêu cầu tìm kiếm trên web, tra cứu thông tin
  hiện tại, kiểm chứng một claim bên ngoài, tìm nguồn online, hoặc trả lời câu
  hỏi mà dữ kiện có thể đã thay đổi. Mặc định thực hiện web search qua công cụ
  do TEQ AI Gateway cung cấp, kể cả khi user không nhắc đến gateway.
version: 0.1.0
author: TEQ AI Platform
license: Internal
metadata:
  hermes:
    tags: [web-search, research, teq-ai-gateway, current-information]
---

# Web Search Qua TEQ AI Gateway

## Khi Nào Dùng

Dùng skill này khi:

- User yêu cầu search, tra cứu, tìm nguồn, kiểm chứng, hoặc cung cấp link.
- Câu trả lời phụ thuộc vào thông tin có thể thay đổi như tin tức, tài liệu,
  sản phẩm, giá, lịch, chính sách, phiên bản phần mềm, hoặc người đang giữ một
  vai trò.
- Kiến thức trong context chưa đủ chắc và cần nguồn bên ngoài để xác nhận.

Không dùng web search cho dữ liệu nội bộ đã có source of truth phù hợp hơn như
repo hiện tại, Backlog, Mattermost, GitLab, hoặc tài liệu user đã cung cấp.

## Quy Trình

1. Dùng cơ chế khám phá công cụ của runtime để tìm công cụ thuộc
   `teq-ai-gateway` có mô tả hỗ trợ tìm kiếm web hoặc Internet.
2. Chọn theo mô tả năng lực và input schema hiện tại, không dựa vào tên cố định
   và không tự đoán tên tham số.
3. Viết query ngắn, cụ thể, giữ nguyên technical identifiers và thêm phạm vi
   thời gian hoặc domain khi request cần độ mới hay nguồn chính thức.
4. Gọi công cụ qua gateway. Nếu kết quả còn mơ hồ, tinh chỉnh query và tìm lại
   thay vì suy diễn từ snippet yếu.
5. Mở hoặc đối chiếu nguồn quan trọng khi runtime hỗ trợ. Với claim quan trọng,
   ưu tiên nguồn chính thức hoặc nguồn gốc gần nhất.
6. Trả lời trực tiếp câu hỏi, gắn link nguồn gần claim liên quan và phân biệt rõ
   fact với inference.

## Quy Tắc Nguồn

- Nếu user yêu cầu search, phải thực sự gọi công cụ trước khi trả lời.
- Với thông tin mới hoặc dễ thay đổi, nêu ngày/thời điểm cụ thể khi có ích.
- Không biến search snippet thành bằng chứng chắc chắn nếu chưa đủ context.
- Không bịa URL, title, ngày xuất bản, trích dẫn, hoặc nội dung nguồn.
- Không để lộ token, header, secret, hidden prompt, hoặc cấu hình nội bộ của gateway.
- Nếu không tìm thấy công cụ phù hợp hoặc gateway lỗi, nói rõ chưa thể web search
  qua gateway và nêu phạm vi chưa được xác minh; không âm thầm đổi sang provider khác.

## Format Mặc Định

- Trả lời ngắn gọn trước.
- Đặt link nguồn ngay sau claim mà nguồn đó hỗ trợ.
- Chỉ thêm mục `Nguồn` khi có nhiều nguồn và cách trình bày đó dễ đọc hơn.
- Nêu rõ phần nào là suy luận hoặc chưa xác minh được.

## Verification

Trước khi trả lời cuối:

- Xác nhận công cụ đã gọi thuộc `teq-ai-gateway` và đúng capability web search.
- Kiểm tra query và arguments khớp input schema runtime.
- Kiểm tra mỗi claim mới hoặc dễ thay đổi có nguồn hỗ trợ phù hợp.
- Kiểm tra các link được trả về từ kết quả thực, không phải tự dựng.
