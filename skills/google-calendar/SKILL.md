---
name: google-calendar
description: >
  Dùng skill này khi AI Platform PM agent cần đặt, dời, kiểm tra, hoặc điều
  phối lịch họp từ chat, Mattermost thread, tên attendee dạng email, hoặc các
  yêu cầu về lịch; resolve email attendee, kiểm tra free/busy của người và
  phòng họp TEQ, đề xuất phòng/khung giờ, và chỉ tạo Google Calendar event sau
  khi người dùng xác nhận.
version: 0.1.2
author: TEQ AI Platform
license: Internal
metadata:
  hermes:
    tags: [calendar, scheduling, mattermost, meeting-room, ai-platform]
---

# Calendar Skill

Skill này hướng dẫn AI Platform PM agent xử lý lịch họp: resolve attendee/email,
check free/busy của người và phòng, đề xuất slot/phòng, rồi mới tạo hoặc cập
nhật event.

## Khi Nào Dùng

Dùng khi user cần đặt/đổi/hủy lịch, tìm slot rảnh, kiểm tra conflict, mời người
từ Mattermost thread/channel, hoặc chọn phòng họp TEQ cho 1:1, call có slide,
seminar, sync team, hay meeting nhiều người.

Không dùng cho câu hỏi tri thức chung về lịch nếu không cần calendar tool.
Không tạo event thật khi user mới chỉ hỏi gợi ý hoặc chưa xác nhận
slot/phòng/attendee.

## Nguyên Tắc Bất Biến

1. Current user: agent support `baonguyen` trên Mattermost, tức Nguyen Quoc Bao
   và là current user/organizer của `teq-ai-gateway` khi user nói "tôi",
   "mình", "em", "lịch của tôi", hoặc request xuất phát từ `baonguyen`.
   Calendar tool tạo event trên primary calendar của organizer, nên không thêm
   `baonguyen`/email current user vào `attendeeEmails` chỉ để mời chính họ. Khi
   cần check lịch organizer, dùng primary calendar runtime hoặc `primary` với
   `google_calendar_suggest_time`. Chỉ thêm email current user khi tạo event
   trên calendar không phải primary của organizer, hoặc user yêu cầu mời một
   lịch/email khác.
2. Attendee/email: không tự đoán email từ username, display name, hoặc domain.
   Resolve Mattermost mention/name bằng `mattermost_search_users`; nếu có nhiều
   match, liệt kê tối đa 3 candidate gồm display name, username, email nếu có,
   rồi hỏi user chọn hoặc cung cấp email. Thread participant không mặc nhiên là
   attendee, trừ khi user nêu/mention hoặc nói rõ "mọi người trong thread/channel".
3. Giờ làm việc: timezone `Asia/Ho_Chi_Minh`, giờ hành chính `08:30-17:30`,
   ngày làm việc là thứ Hai đến thứ Sáu cộng thêm thứ Bảy cuối cùng của mỗi
   tháng. Giờ nghỉ trưa mặc định `12:00-13:00`; không đề xuất slot đè lên
   khung này (kể cả một phần), trừ khi user yêu cầu rõ (ví dụ "họp lúc 12h30
   luôn" hoặc "làm việc xuyên trưa"). Không đề xuất ngoài `08:30-17:30`, Chủ
   Nhật, hoặc thứ Bảy thường nếu user không yêu cầu rõ. Với ngày tương đối,
   chọn ngày gần nhất sắp tới còn hợp lý; nếu "thứ Sáu" trùng hôm nay và mơ hồ
   tuần này/tuần sau, hỏi lại hoặc echo ngày cụ thể trước khi write.
4. Phòng họp: room là attendee/resource calendar khi check availability. Ưu
   tiên lầu 3 vì `baonguyen` thường làm việc ở lầu 3; chỉ chọn lầu 5 khi lầu 3
   không phù hợp, đã bận, hoặc meeting cần sức chứa lớn hơn. Room bận thì không
   dùng, kể cả attendee rảnh.
5. Buffer giữa meeting: khi đề xuất slot, ưu tiên chừa ít nhất 10 phút trống
   trước/sau meeting liền kề của organizer. Nếu meeting liền kề khác floor, ví
   dụ một cuộc lầu 5 và một cuộc lầu 3, tăng buffer tối thiểu lên 15 phút để có
   thời gian di chuyển. Rule này chỉ áp dụng cho lịch organizer/current user vì
   agent có visibility tốt hơn vào primary calendar; chỉ áp dụng cho attendee
   khác khi tool trả đủ location/floor. Có thể đề xuất slot sát hơn nếu đó là
   lựa chọn khả thi duy nhất trong window, nhưng phải cảnh báo rõ khoảng cách và
   việc đổi floor nếu có.

## Phòng Họp TEQ

Khi tạo event, thêm calendar ID của phòng vào `attendeeEmails` và điền
`location` bằng tên phòng/floor.

| Phòng | Calendar ID | Floor | Fit tốt nhất | Ghi chú |
|---|---|---|---|---|
| `R01` | `c_188fjubnkmr5ahbeivo8a8q356ll0@resource.calendar.google.com` | 3 | 1:1 nhanh | Phòng rất nhỏ khoảng 1.5m x 1.5m, có bàn tròn nhỏ, không có TV để show slide. |
| `R02` | `c_1887cv0mepjb6i9jji6q20htr5fdm@resource.calendar.google.com` | 3 | 4-6 người hiệu quả, tối đa khoảng 8-10 | Có TV, phù hợp slide/call meeting. |
| `R03` | `c_188f9evh7pllgintmho73ngdriqs4@resource.calendar.google.com` | 5 | 4-6 người | Có TV. |
| `R04` | `c_188c84cp5cdt0ja7gkgargtsdo284@resource.calendar.google.com` | 5 | Tương đương `R02` | Có TV. |
| `OS01` | `c_188c59mvom43qhn1nm6rbo9kja49e@resource.calendar.google.com` | 5 | Seminar/toàn bộ bộ phận, hơn 20 người | Không gian mở, có TV. |

Room defaults: `R01` cho 1:1 không cần TV; `R02` cho nhóm 4-10 người hoặc cần
TV/call/slide ở lầu 3; `R03`/`R04` khi cần lầu 5 có TV hoặc `R02` không khả
dụng; `OS01` cho seminar/toàn bộ bộ phận.

## Fast Path Cho Tool Runtime

Ưu tiên các tool runtime này khi đang expose:

- Calendar: `google_calendar_suggest_time`, `google_calendar_create_event`,
  `google_calendar_update_event`, `google_calendar_get_event`,
  `google_calendar_list_events`, `google_calendar_delete_event`,
  `google_calendar_respond_to_event`.
- Mattermost: `mattermost_read_post`, `mattermost_search_users`.

Không copy hoặc suy đoán schema từ skill này. `tool_describe` hoặc schema tool
runtime hiện tại là source of truth cho parameters. Các field/value ví dụ như
`primary`, `attendeeEmails`, `allDay`, `recurrenceData`, `addedAttendeeEmails`
chỉ là gợi ý; luôn verify schema runtime trước khi gọi tool.

## Workflow Đặt Lịch

1. Xác định intent: title/topic, duration mặc định 30 phút, date/time window,
   meeting type, onsite/online/hybrid, attendee scope, room need, all-day hoặc
   multi-day intent, và recurring intent nếu user nói "weekly", "hàng tuần",
   "định kỳ".
2. Resolve attendee theo `Nguyên Tắc Bất Biến`. Nếu request đến từ Mattermost,
   đọc thread/post khi có `post_id` hoặc context runtime. Không check
   availability hoặc tạo event cho attendee chưa có email chắc chắn.
3. Chọn candidate room theo bảng phòng. Nếu user chỉ cần online hoặc không cần
   phòng, không thêm room resource. Nếu chưa rõ có cần phòng và điều đó ảnh
   hưởng free/busy, hỏi ngắn trước khi check.
4. Check free/busy:
   - Dùng `google_calendar_suggest_time` với attendee emails đã resolve,
     `primary` cho organizer khi cần, và calendar ID của từng phòng candidate.
   - Preferences: `08:30-17:30`, `Asia/Ho_Chi_Minh`, ngày làm việc hợp lệ.
   - Khi tự đề xuất giờ (user chưa chỉ định giờ cụ thể trong `12:00-13:00`),
     tách window thành 2 đoạn `08:30-12:00` và `13:00-17:30` thay vì dùng
     nguyên khối `08:30-17:30`, để tránh slot bị đề xuất đè lên giờ nghỉ trưa
     `12:00-13:00` (theo `Nguyên Tắc Bất Biến` #3). Nếu user đã chỉ định rõ
     giờ nằm trong `12:00-13:00`, check availability bình thường tại giờ đó,
     không tách window hay từ chối.
   - Nếu window có thứ Bảy cuối tháng, không dùng một query duy nhất với
     `excludeWeekends: true`; query riêng thứ Bảy cuối tháng với weekend allowed
     hoặc dùng `google_calendar_list_events` rồi lọc thủ công.
   - Nếu không có `suggest_time`, fallback bằng `google_calendar_list_events`
     cho từng attendee/calendar ID rồi tự tìm khoảng trống.
   - Sau khi có slot rảnh, loại hoặc hạ ưu tiên slot nằm trong buffer sát
     meeting khác của organizer theo `Nguyên Tắc Bất Biến` #5, trừ khi không còn
     lựa chọn nào khác trong window.
5. Nếu không tìm được slot:
   - Với request flexible như "tuần này", mở rộng sang 5-10 ngày làm việc hợp
     lệ tiếp theo và thử candidate room kế tiếp.
   - Nếu vẫn không có slot, báo rõ đã check window/phòng/attendee nào và hỏi
     user muốn mở rộng ngày, cho phép lầu 5, online-only, hay ngoài giờ.
   - Không gọi slot có conflict là "rảnh"; nếu nêu slot gần nhất có conflict,
     label rõ đó là phương án cần user quyết.
6. Đề xuất tối đa 3 lựa chọn, ghi ngày cụ thể, giờ, phòng/floor, lý do chọn
   phòng, và attendee chưa resolve nếu còn. Ưu tiên slot có đủ buffer với
   meeting liền kề của organizer theo `Nguyên Tắc Bất Biến` #5; nếu bắt buộc
   chọn slot sát giờ, nêu rõ khoảng cách và có đổi floor hay không. Chỉ tạo
   event sau khi user xác nhận.
7. All-day/multi-day: nếu user muốn "chặn lịch nguyên ngày" hoặc event nhiều
   ngày, xác nhận all-day hay timed sessions. Chỉ dùng `allDay` khi schema hỗ
   trợ và intent rõ; nếu cần phòng nhiều ngày, check room từng ngày.
8. Recurring: chỉ set `recurrenceData` khi user yêu cầu recurring và đã có
   cadence/end condition rõ. Nếu thiếu, hỏi lại; nếu runtime không hỗ trợ trong
   context đó, chỉ tạo single event khi user đồng ý.
9. Tạo event bằng `google_calendar_create_event` với `summary`, `startTime`,
   `endTime`, `timeZone: Asia/Ho_Chi_Minh`, `attendeeEmails` gồm attendee khác
   organizer và room resource, `location` dạng `R02, Floor 3`, kèm `allDay` hoặc
   `recurrenceData` nếu đã xác nhận ở bước 7-8 và schema runtime hỗ trợ. Thêm
   `addGoogleMeetUrl: true` khi có remote attendee/call, user yêu cầu Google
   Meet, hoặc meeting hybrid.
10. Trả kết quả: title, thời gian cụ thể, phòng, attendee, Google Meet nếu có,
    recurrence nếu có, và warning từ tool nếu có.

## Workflow Update/Hủy Lịch

- Luôn đọc đúng event bằng `google_calendar_get_event` hoặc tìm bằng
  `google_calendar_list_events` trước khi update/delete.
- Khi thêm/bớt attendee, merge với attendee list hiện tại; không overwrite hoặc
  xóa attendee cũ vì chỉ truyền list mới. Ưu tiên `addedAttendeeEmails` và
  `removedAttendeeEmails` nếu schema runtime hỗ trợ.
- Khi đổi giờ/phòng, check availability của attendee và phòng mới trước khi
  update.
- Với recurring event, hỏi rõ update một occurrence hay cả series nếu runtime
  không thể suy ra an toàn.
- Nếu user yêu cầu cancel/delete, xác nhận đúng event target khi có nhiều event
  gần giống nhau. Accept/decline invitation thì dùng
  `google_calendar_respond_to_event`, không delete.

## Verification

Trước khi write calendar:

- Event target hoặc meeting intent đã đủ cụ thể.
- Payload dùng ngày cụ thể, ISO timestamp, timezone đúng.
- All-day/multi-day intent đã được xác nhận nếu khác event timed thông thường.
- Attendee emails chắc chắn; candidate mơ hồ đã hỏi user.
- Organizer không bị add trùng vào `attendeeEmails`.
- Slot đã được check cho attendee, organizer khi cần, và room resource.
- Update attendee đã merge với attendee hiện tại.
- User đã xác nhận khi hành động sẽ tạo, gửi invite, update, hoặc delete event.

## Gotchas

- Mattermost mention không đảm bảo có email trong text.
- Không chọn `R01` cho slide/call chỉ vì nó ở lầu 3.
- Không loại toàn bộ weekend vì thứ Bảy cuối tháng là ngày làm việc.
- Luôn echo ngày cụ thể khi user dùng ngày tương đối.

## Ví Dụ Prompt Nên Trigger

- "Đặt lịch 1:1 với anh Nam chiều mai, tìm phòng giúp tôi."
- "Trong thread này có mấy bạn liên quan, tìm slot họp 30 phút tuần này nhé."
- "Book phòng có TV cho team sync thứ Sáu, mời các bạn được mention."
- "Rời meeting với chị Dinh sang tuần sau, check lại phòng trước."
- "Tìm giúp slot rảnh của tôi, @lan và phòng R02 trong ngày 03/07."

## Prompt Không Nên Trigger

- "Tóm tắt policy nghỉ phép trong tài liệu này."
- "Tạo ticket follow-up cho meeting hôm qua."
- "Review MR calendar integration."
- "Search knowledge base về roadmap calendar MCP."
