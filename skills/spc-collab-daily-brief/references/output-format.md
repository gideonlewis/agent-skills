# Output Format — spc-collab-daily-brief

Format cố định cho mọi lần gọi skill. Đọc file này **trước khi viết brief** và
bám đúng từng điểm dưới đây — brief được so sánh giữa các ngày, nên chỉ cần
lệch heading, thứ tự hay cách ghi tên là người đọc phải dò lại.

## Khung Bắt Buộc

Đúng 1 heading cấp 1 và 4 heading cấp 2, theo đúng thứ tự, đúng chữ, không
thêm heading, không thêm đoạn mở đầu hay kết luận, không có đường kẻ `---`:

```markdown
# Daily brief SPCC — <label>

## Key Highlights
- **<Chủ đề>:** <nội dung> (<owner>)

## Needs Confirmation
- <nội dung> (<owner>)

## Blockers & Risks
- <nội dung> (<owner>)

## Status Changes — JP User Story
| Ticket | From → To | Owner |
|---|---|---|
| [SPCC-xxxx](https://teq-dev.backlog.com/view/SPCC-xxxx) <tên rút gọn> | Open → In Progress | <owner> |
```

- `<label>` lấy nguyên từ `window.py` (`2026-09-28` hoặc
  `2026-09-25 → 2026-09-27`). Project khác thì thay `SPCC` bằng project key.
- Heading và tiêu đề bảng luôn tiếng Anh như trên; nội dung bullet tiếng Việt.

## Quy Tắc Từng Mục

| Mục | Số bullet | Dạng bullet |
|---|---|---|
| Key Highlights | 1–6 | Mở đầu bằng **chủ đề in đậm + dấu hai chấm**, rồi kết luận/trạng thái |
| Needs Confirmation | 0–5 | Việc gì + đang chờ ai/bên nào quyết định; không in đậm |
| Blockers & Risks | 0–5 | Việc gì + bị chặn bởi gì / rủi ro gì; không in đậm |
| Status Changes | mỗi ticket 1 dòng | Chỉ JP User Story; nhiều lần đổi trong khung → `A → B → C` |

- Mỗi bullet **một dòng**. Chỉ được kéo dài tới 2 dòng khi mục đó ảnh hưởng
  release hoặc có nhiều bên liên quan.
- Sắp theo mức độ quan trọng giảm dần: release/deploy → quyết định với JP →
  nghiệm thu/phân công → phần còn lại.
- Mục trống: ghi đúng một dòng `None` (bảng trống: `No User Story status changes.`).
- Một ticket/chủ đề chỉ xuất hiện ở **một** trong 3 mục bullet; bảng Status
  Changes được phép lặp lại ticket đã nhắc ở trên.

## Owner

- Ghi ở **cuối bullet, trong ngoặc tròn, không có `@`**:
  `(vitran)`, `(oanhtran, thaohuynh)`. Cột `Owner` của bảng ghi username trần.
- Dùng username Mattermost trong `members.json`. Người ngoài danh sách: giữ tên
  như trong nguồn (ví dụ `(JP)`).
- Không rõ ai phụ trách → bỏ phần ngoặc, không đoán.

## Link và Ký Hiệu

- Ticket Backlog: lần nhắc đầu tiên trong bullet dùng link
  `[SPCC-3599](https://teq-dev.backlog.com/view/SPCC-3599)`; các ticket liệt
  kê liền sau có thể rút gọn `[3587](https://teq-dev.backlog.com/view/SPCC-3587)`.
- Issue/PR GitHub: link `[azuki-agora#1022](https://github.com/Finatext/azuki-agora/issues/1022)`.
- Ticket Jira JP (CRES-xxxxx), tên feature flag, tên API: để trong backtick
  hoặc text thường, không tự tạo link.
- Ngày viết `dd/mm` (ví dụ `29/09`). Không dùng emoji.

## Ví Dụ Chuẩn

Brief thật ngày 2026-09-28 — dùng làm mẫu về độ dài và giọng văn:

```markdown
# Daily brief SPCC — 2026-09-28

## Key Highlights
- **Release 29/09:** JP đã lên list PR dự kiến release, nhờ team check PR của mình trong sheet Azuki / Azuki-app (dungnguyen)
- **QC nghiệm thu OK 4 ticket clean-up FF → Waiting For Release:** [SPCC-3594](https://teq-dev.backlog.com/view/SPCC-3594), [3587](https://teq-dev.backlog.com/view/SPCC-3587), [3589](https://teq-dev.backlog.com/view/SPCC-3589), [3600](https://teq-dev.backlog.com/view/SPCC-3600) (oanhtran, thaohuynh)
- **Core API (BE):** chia ~40 ticket cho dungnguyenhuu (19) và dinhnguyen (~21), due 29/09–26/10; 4 ticket chunk giao giaoquynh (quanhuynh). Thêm 3 ticket FE chunk_8 (giaoquynh)
- **[SPCC-3586](https://teq-dev.backlog.com/view/SPCC-3586) mở lại để test:** scope 5h + 1h buffer, bỏ TC-03/04, giữ TC-05; xong 2 môi trường trước trưa 29/09 (vitran)
- **[SPCC-3584](https://teq-dev.backlog.com/view/SPCC-3584):** đã chia case test trong team, chốt verify trên SPC là đủ; cuối ngày chuyển Ready For Test (dinhnguyen, oanhtran)

## Needs Confirmation
- JP fix bug FF `enable_console_engagement_history_view` và nhờ TEQ verify — sớm nhất sáng 29/09, chỉ happy case; cần chốt với JP có tự nghiệm thu để kịp release không (thaohuynh, ngocnguyen)
- [SPCC-3607](https://teq-dev.backlog.com/view/SPCC-3607): bổ sung case override khi FF = OFF (lyhoanam)

## Blockers & Risks
- Anmitsu không adjust repayment được ([azuki-agora#1022](https://github.com/Finatext/azuki-agora/issues/1022)), ảnh hưởng test phía Anmitsu (dungnguyenhuu)
- Bug CRES-20869 liên quan upgrade `protobuf` (phát hiện khi test SPCC-3599), chờ JP (thaohuynh)
- [SPCC-3629](https://teq-dev.backlog.com/view/SPCC-3629) / [3634](https://teq-dev.backlog.com/view/SPCC-3634) / [3635](https://teq-dev.backlog.com/view/SPCC-3635) chờ chunk_2 + chunk_36/37 xong, ETA 01/10 (giaoquynh)
- QC tạm dừng test Kinako BORROWER_FORM DETAIL để ưu tiên nghiệm thu Clear FF (thaohuynh)

## Status Changes — JP User Story
| Ticket | From → To | Owner |
|---|---|---|
| [SPCC-3699](https://teq-dev.backlog.com/view/SPCC-3699) JPKI xoá text loại giấy tờ | Open → In Progress | lyhoanam |
| [SPCC-3366](https://teq-dev.backlog.com/view/SPCC-3366) Kinako BORROWER_FORM DETAIL | On Hold → Testing | thaohuynh |
```

## Checklist Trước Khi Trả

- [ ] Đúng 4 heading cấp 2, đúng chữ, đúng thứ tự.
- [ ] Không có `@` nào; mọi owner nằm trong ngoặc cuối bullet.
- [ ] Không có sự kiện nào ngoài khung thời gian.
- [ ] Bullet Key Highlights đều mở đầu bằng chủ đề in đậm.
- [ ] Mục trống ghi `None`, không bị bỏ.
- [ ] Không có đoạn văn nào ngoài 4 mục (không lời chào, không ghi chú nguồn).
