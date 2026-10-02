---
name: spcc-report
description: >
  Tổng hợp thông tin và viết report/summary cho công việc trong dự án
  spc-collab (azuki, azuki-app, ohagi-app, cred-proto, cred-devtools, và các
  project vệ tinh khác trong workspace này) — một task vừa hoàn thành, hoặc
  một investigation vừa điều tra xong — theo 1 format đồng nhất, xuất ra
  Markdown dán thẳng vào Mattermost, Slack, hoặc Jira. Dùng skill này khi
  người dùng nói "viết báo cáo", "tóm tắt lại", "summary cho team", "viết
  update gửi lên Mattermost/thread", "note lại investigation này", hoặc ngay
  sau khi vừa hoàn thành 1 task/feature/điều tra trong bất kỳ project nào của
  workspace này và cần trình bày lại cho người khác đọc — kể cả khi họ không
  gọi thẳng tên "report". Không dùng để tạo/cập nhật ticket Backlog (xem
  `nulab-backlog`), và không dùng để liệt kê finding review MR/PR (xem
  `code-review`) — skill này chỉ lo phần trình bày/tường thuật cuối cùng,
  không tự điều tra hay tự thao tác ticket.
version: 0.1.0
author: TEQ AI Platform
license: Internal
metadata:
  hermes:
    tags: [reporting, spc-collab, mattermost, slack, jira, summary, communication]
---

# SPC-Collab Report

Viết report/summary tổng hợp cho một task đã hoàn thành hoặc một investigation
đã điều tra xong **trong phạm vi workspace `spc-collab`** (azuki và các
project vệ tinh xung quanh nó), theo một format đồng nhất giữa các lần viết,
xuất ra Markdown dán thẳng vào Mattermost, Slack, hoặc Jira comment.

## Khi Nào Dùng

- Vừa hoàn thành 1 task/feature/investigation và cần viết lại cho người khác
  đọc (Mattermost thread, Slack channel, comment trong Jira ticket).
- Người dùng yêu cầu "tóm tắt", "viết report", "summary", "note lại", "viết
  update cho team" mà không chỉ định format cụ thể — mặc định dùng khung ở
  skill này thay vì tự bịa cấu trúc mới mỗi lần.

Ranh giới với các skill lân cận:

- Tạo/sửa/cập nhật status ticket Backlog → dùng `nulab-backlog`, không dùng
  skill này.
- Liệt kê finding khi review MR/PR (bug, rủi ro, severity) → dùng `code-review`,
  skill đó đã có format riêng cho việc đó.
- Skill này là bước **trình bày cuối** — có thể trích dẫn kết quả từ
  `nulab-backlog`/`code-review`/investigation đã làm, nhưng không thay thế
  chúng và không tự đi điều tra thêm.

## Chọn Template

Đọc nội dung cần tường thuật rồi chọn khung phù hợp bên dưới. Nếu một việc vừa
có phần "đã làm gì" vừa có phần "điều tra ra nguyên nhân", có thể ghép cả hai
khung — ưu tiên giữ mạch đọc rõ ràng hơn là ép cứng đúng một khuôn:

- **Template A — Task/Status Completion Summary**: báo cáo một việc đã hoàn
  thành, hoặc cập nhật tiến độ đang làm ("đã làm gì, kết quả ra sao, còn gì
  cần làm tiếp").
- **Template B — Investigation/Root-Cause Report**: tường thuật quá trình điều
  tra một vấn đề/bug/câu hỏi ("hiện tượng gì, vì sao xảy ra, giải pháp nào").

## Nguyên Tắc Chung (áp dụng cho cả hai template)

Đây là phần giữ cho report "đồng nhất giữa các lần viết" — áp dụng bất kể chọn
template nào:

1. **Markdown thuần, không phụ thuộc cú pháp riêng của một nền tảng.**
   Mattermost và Slack đọc GitHub-flavored Markdown gần như giống hệt nhau
   (heading, bold, list, table, code block đều hiển thị đúng). Nếu đích là
   Jira: bản Jira Cloud với trình soạn thảo mới chấp nhận cú pháp tương tự khi
   dán trực tiếp; Jira wiki cũ (`h1.`, `*bold*`, `||header||`) thì khác hẳn —
   nếu không chắc bản Jira đích dùng cú pháp nào, hỏi lại người dùng trước khi
   convert, đừng đoán.

2. **Lược bớt mục không có nội dung, đừng giữ khung rỗng.** Ví dụ Template A
   có mục "Blocker" nhưng task không có blocker nào thì bỏ hẳn mục đó, không
   viết "Không có"/"N/A". "1 format đồng nhất" nghĩa là giữ đúng thứ tự và tên
   các mục *khi chúng thực sự có nội dung*, không phải ép mọi report dài như
   nhau bất kể nội dung.

3. **Dùng table khi cần so sánh nhiều dòng cùng thuộc tính** — ví dụ danh sách
   nhiều file thay đổi kèm lý do, nhiều rủi ro kèm mức độ, nhiều phương án kèm
   trade-off. Đừng table hóa nội dung tường thuật tuyến tính (một chuỗi
   nguyên nhân → hệ quả, một câu chuyện diễn ra theo trình tự) — table hóa thứ
   vốn tuyến tính làm khó đọc hơn chứ không trực quan hơn.

4. **Ưu tiên thông tin hành động được hơn tường thuật đầy đủ theo thời gian.**
   Người đọc trên Mattermost/Slack thường lướt nhanh, nên phần tóm tắt ở đầu
   phải đứng được một mình — không bắt buộc đọc hết report mới hiểu chuyện gì
   đã xảy ra hoặc cần làm gì tiếp theo.

5. **Giữ ngôn ngữ người dùng đang dùng trong hội thoại** (thường là tiếng
   Việt), chỉ giữ tiếng Anh cho thuật ngữ kỹ thuật, tên field/file/branch, và
   tên riêng (Mattermost, Jira, azuki, tên repo...).

## Template A — Task/Status Completion Summary

```markdown
## [Tên task/feature]

**Tóm tắt:** 1-2 câu — việc gì vừa xong, ảnh hưởng gì tới ai/hệ thống nào.

**Đã làm:**
- ...
- ...

**Kết quả / Trạng thái:** ...

**Việc tiếp theo:** (bỏ mục này nếu không còn gì)
- ...

**Blocker:** (bỏ mục này nếu không có)
- ...
```

## Template B — Investigation/Root-Cause Report

```markdown
## [Tên vấn đề]

**Hiện tượng:** ...

**Điều tra:**
- ...
- ...

**Nguyên nhân:** ...

**Giải pháp / Khuyến nghị:** ...

**Rủi ro & follow-up:** (bỏ mục này nếu không có)
- ...
```

## Ví dụ

**Ví dụ Template A** (task hoàn thành):

```markdown
## Dọn dẹp workspace spc-collab

**Tóm tắt:** Đã gom các file rời ở root vào đúng chỗ và thêm README bản đồ
repo — không thay đổi gì trong các git repo con.

**Đã làm:**
- Thêm `README.md` ở root: bản đồ 11 project + quan hệ giữa chúng.
- Chuyển `db-tunnel.sh` vào `scripts/`, `DD.md` vào `azuki/docs/design-docs/`.
- Đổi tên `json local ff` → `local-fixtures/feature-flags`, `assisstants` →
  `assistants`.

**Việc tiếp theo:**
- Rà soát `sql-dump/` (2.1GB) — quyết định giữ hay xóa.
- Xử lý AWS secret key đang nằm plain-text trong `setup.txt`.
```

**Ví dụ Template B** (investigation):

```markdown
## Feature flag `kinako_enabled_components` không tắt được trên staging

**Hiện tượng:** Toggle flag về `false` qua Console nhưng UI staging vẫn hiển
thị Kinako UI sau khi refresh.

**Điều tra:**
- Console ghi override vào `feature_flag_overrides` (core DB) — xác nhận đúng
  bằng query trực tiếp, giá trị đã là `false`.
- Response `GetFeatureFlags` từ `cred-proto` vẫn trả `true` — nghi ngờ cache.

**Nguyên nhân:** azuki-app cache kết quả `GetFeatureFlags` trong `localStorage`
5 phút, không invalidate khi override thay đổi.

**Giải pháp / Khuyến nghị:** Thêm invalidate cache khi Console ghi nhận
override mới; trước mắt hướng dẫn QA hard refresh (Cmd+Shift+R) để test.

**Rủi ro & follow-up:** Nếu không sửa cache, mọi lần toggle flag trên
Console đều cần đợi tối đa 5 phút mới thấy hiệu lực trên staging — cần theo
dõi thêm ticket sửa cache.
```

## Anti-patterns

- Giữ nguyên khung đầy đủ dù mục không có nội dung, viết "N/A"/"Không có"
  thay vì lược bỏ hẳn mục đó.
- Table hóa toàn bộ report kể cả phần tường thuật tuyến tính (chuỗi nguyên
  nhân → hệ quả), khiến report vụn thành hàng chục dòng bảng khó theo dõi.
- Dán nguyên log/trace/output kỹ thuật vào report — report là bản tóm tắt cho
  người đọc, không phải nơi lưu log; trích dẫn ngắn nếu cần minh họa.
- Dùng format finding-severity của `code-review` hoặc field ticket của
  `nulab-backlog` cho report task/investigation thông thường — hai mục đích
  khác nhau, mỗi skill có khung riêng phù hợp với mục đích của nó.

## Red Flags

🚩 Report dài hơn cả nội dung gốc (task/investigation) — dấu hiệu đang tường
thuật lại toàn bộ quá trình thay vì tóm tắt.
🚩 Phần tóm tắt đầu bài không đứng được một mình — phải đọc hết report mới
hiểu kết luận hoặc việc cần làm tiếp theo là gì.
🚩 Không chắc đích là Mattermost/Slack hay Jira wiki markup cũ mà vẫn xuất
Markdown mặc định — hỏi lại thay vì đoán khi có dấu hiệu đích là Jira cũ.
