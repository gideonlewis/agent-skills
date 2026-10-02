---
name: spcc-calendar
description: >
  Dùng skill này khi cần đặt, dời, hoặc hủy lịch họp cho dự án spc-collab —
  các yêu cầu kiểu "họp DEV", "họp với PO", "sync BrSE", "mời QC review",
  "họp all team spc", hoặc nhắc tên module như Kinako, CoreAPI, Ohagi kèm ý
  định đặt lịch. Skill này chỉ lo phần đặc thù dự án: expand nhóm người
  (DEV/PO/BrSE/QC/All) thành email cụ thể và thêm prefix module vào tiêu đề
  meeting; phần free/busy, đề xuất phòng/giờ, và tạo event thật vẫn giao cho
  skill `google-calendar`. Không dùng cho lịch cá nhân không liên quan
  spc-collab, hoặc khi user đã cho sẵn đầy đủ email/phòng cụ thể — trường hợp
  đó dùng thẳng `google-calendar`.
version: 0.1.0
author: TEQ AI Platform
license: Internal
metadata:
  hermes:
    tags: [calendar, scheduling, spc-collab, meeting-room]
---

# SPC Collab Calendar

Lớp cấu hình riêng cho dự án spc-collab, chạy trên nền `google-calendar`. Skill
này không tự gọi tool calendar — nó chuẩn bị input đúng chuẩn dự án (nhóm
người, prefix tiêu đề, phòng mặc định) rồi **chủ động gọi `Skill` tool với
`skill: google-calendar`** để nạp và chạy phần còn lại (free/busy, đề xuất
slot, tạo/update/hủy event). Đây là invocation thật (chain sang skill khác),
không phải chỉ nhắc tên suông rồi tự nhớ lại nội dung — nhắc tên suông dễ khiến
agent áp dụng sai hoặc thiếu bước vì không có nội dung gốc trong context.

## Khi Nào Dùng

Dùng khi request đặt lịch nhắc đến một nhóm vai trò cố định của spc-collab
(DEV, PO, BrSE, QC, hoặc All) hoặc một module của dự án (Kinako, CoreAPI,...).
Nếu user đã tự liệt kê đủ email cụ thể và không cần prefix module, việc expand
nhóm là thừa — lúc đó dùng thẳng `google-calendar`.

## Nhóm Người

Mở rộng tên nhóm thành email theo bảng dưới. Không tự đoán thêm người ngoài
danh sách; nếu user nhắc một người không có trong bảng, resolve qua
`mattermost_search_users` như hướng dẫn của `google-calendar`, không gộp vào
nhóm cố định này.

| Nhóm | Email |
|---|---|
| DEV | quanhuynh@teqnological.asia, vitran@teqnological.asia, tienbui@teqnological.asia, dungnguyen@teqnological.asia, namly@teqnological.asia, giaoquynh@teqnological.asia, dinhnguyen@teqnological.asia |
| PO | ngocnguyen@teqnological.asia |
| BrSE | dungnguyen@teqnological.com, oanhbui@teqnological.asia |
| QC | oanhtran@teqnological.asia, thaohuynh@teqnological.asia |
| All | Toàn bộ email ở DEV + PO + BrSE + QC (12 email, không trùng lặp) |

Lưu ý: có hai địa chỉ `dungnguyen` khác domain (`@teqnological.asia` ở DEV và
`@teqnological.com` ở BrSE) — đây là hai người khác nhau, không phải trùng
lặp, giữ nguyên cả hai khi mời "All".

Khi user chỉ nói "mời DEV và PO" (không phải "All"), chỉ cộng đúng hai nhóm đó,
không tự thêm QC/BrSE.

## Quy Ước Tiêu Đề Meeting

Tiêu đề luôn có dạng `[Module] Nội dung`, ví dụ `[Kinako] Sync tuần`,
`[CoreAPI] Review API contract`. Module là tên hạng mục/dự án con đang bàn
(Kinako, CoreAPI, Ohagi, hoặc module khác của spc-collab).

Nếu user không nói rõ module trong yêu cầu đặt lịch, hỏi lại trước khi tạo
event thay vì đoán — sai prefix gây khó lọc lịch theo module về sau.

## Phòng Họp

Dùng đúng bảng phòng và calendar ID của `google-calendar`
(xem `google-calendar/SKILL.md` mục "Phòng Họp TEQ") — không định nghĩa lại
danh sách phòng ở đây để tránh hai bản lệch nhau theo thời gian:

- `R01`, `R02` — lầu 3.
- `R03`, `R04`, `OS01` (seminar/toàn bộ team) — lầu 5.

Áp dụng nguyên tắc chọn phòng và buffer giữa các meeting y như
`google-calendar` mô tả (ưu tiên lầu 3, buffer 10-15 phút, v.v).

## Quy Trình

1. Xác định module → tiêu đề dạng `[Module] ...`. Hỏi lại nếu chưa rõ.
2. Xác định nhóm người cần mời (DEV/PO/BrSE/QC/All hoặc kết hợp) → expand
   thành email theo bảng trên. Thêm người ngoài nhóm (nếu có) bằng cách resolve
   qua Mattermost như `google-calendar` hướng dẫn.
3. Gọi `Skill` tool với `skill: google-calendar`, kèm theo trong prompt:
   danh sách email đã expand ở bước 2, tiêu đề `[Module] ...` đã xác định ở
   bước 1, và intent gốc của user (duration, ngày/giờ mong muốn, có cần phòng
   hay không). Để `google-calendar` tự chạy workflow của nó: chọn phòng theo
   bảng phòng TEQ, check free/busy cho tất cả attendee + phòng, đề xuất tối đa
   3 lựa chọn.
4. Chỉ tạo event sau khi user xác nhận nhóm người, module/tiêu đề, và
   slot/phòng — theo đúng bước Verification của `google-calendar` (skill đó tự
   thực thi bước này khi được gọi ở bước 3, không cần lặp lại thủ công).

## Anti-patterns

- Tự bịa thêm người vào nhóm DEV/PO/BrSE/QC/All ngoài bảng cố định ở trên.
- Tạo event mà tiêu đề thiếu prefix `[Module]`, hoặc đoán module khi user chưa
  nói rõ.
- Định nghĩa lại calendar ID phòng họp ở đây thay vì tham chiếu
  `google-calendar` — dễ lệch khi phòng đổi ID.

## Red Flags

🚩 User nhắc "họp All" nhưng thực ra chỉ muốn một nhóm nhỏ — hỏi lại phạm vi
trước khi mời cả 11 người.
🚩 Sắp tạo event mà chưa xác định được module → prefix tiêu đề sẽ sai, dừng lại
hỏi trước khi gọi `google_calendar_create_event`.
