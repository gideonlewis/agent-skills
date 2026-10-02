# Preview format — spc-collab-daily-sheet-sync

Đọc file này ở Bước 6, trước khi viết preview. Preview là thứ user duyệt để
quyết định ghi hay không, nên mỗi ticket phải tự đứng được: nhìn vào là biết
dòng nào trên sheet, căn cứ là gì, ô nào đổi từ gì sang gì.

## Khung

````markdown
**Daily sheet preview · <sprint_tab> · <label>** · [Sheet](<spreadsheet_url>)
<N> ticket có thay đổi đề xuất, <M> mục cần xác nhận.

#### 1. [SPCC-3549](https://teq-dev.backlog.com/view/SPCC-3549) <title rút gọn ≤ 50 ký tự> · JP User Story · dòng 12
_Task con: 18 (15 Waiting For Release, 1 Ready For Test, 2 On Hold)_
- 09:40 MM (Ngọc): chốt release kịp 06/10
- 09:09–13:46 Backlog (Tiên): [3555](https://teq-dev.backlog.com/view/SPCC-3555), [3562](https://teq-dev.backlog.com/view/SPCC-3562) BE Task → Waiting For Release; [3560](https://teq-dev.backlog.com/view/SPCC-3560) → Ready For Test

| Cột | Cũ → Mới |
|---|---|
| Release SPC | 2026/09/29 → 2026/10/06 |
| BE | → Clean BE xong, chờ review |
| Memo | + 10/02: PO chốt release 06/10 |

#### 2. ...

#### Cần xác nhận
- ⚠️ [SPCC-3700](https://teq-dev.backlog.com/view/SPCC-3700): Backlog Ready For Test — Status sheet nên là `QC Assigning`?
- ⚠️ `chunk_5`: thread nhắc dời release nhưng không rõ ngày

#### Không đưa lên sheet
- [SPCC-3710](https://teq-dev.backlog.com/view/SPCC-3710) Bug: không có trong Sprint 57
- [SPCC-3711](https://teq-dev.backlog.com/view/SPCC-3711) JP User Story: chỉ đổi due date, không ảnh hưởng cột nào
- Bỏ qua 2 task không có ticket cha: [3720](https://teq-dev.backlog.com/view/SPCC-3720), [3721](https://teq-dev.backlog.com/view/SPCC-3721)

Trả lời `ok` để ghi tất cả, `ok 1,3` để ghi một phần, `bỏ 2`, hoặc sửa trực tiếp
(ví dụ `2: BE = Đang review PR`).
````

## Quy tắc

- **Đánh số ticket** liên tục từ 1, để user chọn bằng số. Mục "Cần xác nhận"
  không đánh số và không bao giờ được ghi, kể cả khi user nói `ok`.
- **Một item = một ticket report** (JP User Story, Bug, JP Bug, JP Request, JP Feedback)
  = một dòng sheet. Không bao giờ có item cho Task / BE / FE / QC Task.
- **Tiêu đề ticket**: mã ticket report (link Backlog), title rút gọn, loại
  ticket, số dòng trên sheet.
- **Dòng task con** (in nghiêng, ngay dưới tiêu đề): tổng số task con và đếm
  theo status từ `children_status`. Ticket không có task con → bỏ dòng này.
- **Căn cứ**: 1–4 bullet, mỗi bullet `HH:MM <nguồn> (<nickname>): <nội dung>`.
  - Nguồn là `MM` (Mattermost) hoặc `Backlog`.
  - Activity của task con / Bug con → ghi mã rút gọn (link) kèm loại, để
    user biết thay đổi đến từ đâu.
  - Nhiều activity cùng người, cùng ý → một bullet với khoảng giờ
    `HH:MM–HH:MM`.
  - Gộp nhiều activity cùng ý thành một bullet (ví dụ 5 lần đổi assignee).
  - Không có `@` trước tên người.
- **Bảng Cũ → Mới**: theo đúng quy ước của `spc-collab-daily-sheet` (Bước 7):
  - Ngày, `Status`, giá trị ngắn: `cũ → mới`, ô trống ghi `–`. Ngày giữ đúng
    format sẽ ghi vào sheet (`YYYY/MM/DD` cho Release, `M/D/YYYY` cho Teq
    Deadline) để user thấy chính xác giá trị.
  - `FE`/`BE`: `→ <mới>` (giá trị đầy đủ, không rút gọn — đây là preview).
  - `Memo`, `releasePRs`: `+ <dòng thêm>`.
  - Không đưa `Remark` vào bảng — nó được dựng lại tự động từ FE/BE khi ghi.
- **Không đưa lên sheet**: ticket report có hoạt động nhưng không sinh thay
  đổi (không có dòng trên sheet, hoặc chỉ là việc vặt), kèm loại ticket. Dòng
  cuối gộp `skipped` (task không có ticket cha) thành một dòng "Bỏ qua N
  task…". Tối đa 8 dòng; nhiều hơn thì gộp `+ N ticket khác`.
- Không có ticket nào có thay đổi → in dòng đầu, rồi `Không có thay đổi nào
  cần ghi lên sheet.` kèm mục "Không đưa lên sheet" nếu có.

## Map status Backlog → cột `Status` trên sheet

Backlog SPCC và sheet dùng hai bộ status khác nhau. Chỉ map tự động các cặp
dưới đây; mọi trường hợp khác đưa vào "Cần xác nhận", vì nhầm status trên
sheet làm filter view của PO/QC sai.

| Backlog (ticket report) | Sheet `Status` | Ghi chú |
|---|---|---|
| `Open` | `Open` | |
| `In Progress` | `In Progress` | |
| `On Hold` | `On Hold` | Giữ thêm `JP Blockers` nếu ô cũ đang có |
| `Testing` | `QC Testing` | |
| `Ready For Test` | — | Hỏi: thường là `QC Assigning` |
| `Reopen` | — | Hỏi: có thể là `Bug あり` hoặc `In Progress` |
| `Resolved`, `Waiting For Release`, `Ready For Deployment`, `Closed` | — | Không tự đổi; `TEQ Done` cần QC/PO xác nhận |

Status của **task con** (Task, BE/FE/QC Task, Bug con) không map sang
`Status` của dòng — chỉ dùng làm căn cứ cho `FE`/`BE` (ví dụ BE Task Resolved
→ `BE: Dev done`). Map này áp dụng cho status của chính ticket report (cả
Bug / JP Bug / JP Request / JP Feedback đứng riêng có dòng trên sheet).
