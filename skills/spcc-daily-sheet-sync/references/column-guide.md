# Column guide — cách ghi từng cột

Đọc file này ở Bước 5 (lập change plan), trước khi ghi. Mỗi cột có format
riêng do team quen dùng; ghi lệch format làm sheet khó đọc và làm filter view
của QC/PO hỏng.

Cột luôn được xác định **theo tên header ở dòng 2**, không theo chữ cái — tab
sprint cũ có 16–18 cột, tab mới có 20 cột, vị trí có thể đổi. Bảng dưới ghi
chữ cái theo `Sprint 57` chỉ để tham khảo.

## Cột không được ghi

| Header | Lý do |
|---|---|
| `STT`, `Priority`, `Priority(ToBe)` | Thứ tự và độ ưu tiên do PO quản lý |
| `Jira`, `ユーザーストーリー`, `Backlog`, `Description` | Định danh ticket — dùng để tìm dòng |
| `Assignee` | Phân công do PO/leader quyết định |
| `QC `, `DEV/QC` | Do QC quản lý |

Thread có nhắc đổi assignee/priority → ghi vào `Memo` và nêu trong reply để
người phụ trách tự sửa.

## Cột được ghi

### `Status` (H) — dropdown

- Chỉ dùng giá trị có trong `Statuses!B5:B16` (đọc lại mỗi lần chạy):
  `Open`, `Out Scope`, `QA`, `In Progress`, `JP PR Reviewing`, `QC Assigning`,
  `Bug あり`, `Unable to verify by TeqQC`, `QC Testing`, `TEQ Done`,
  `On Hold`, `JP Blockers`.
- Nhiều giá trị nối bằng `", "`, ví dụ `On Hold, JP Blockers`.
- Chỉ đổi khi thread **nói rõ** trạng thái mới (đã merge và chuyển QC, JP
  đang review PR, bị JP block...). Không tự suy `TEQ Done` từ "đã release" —
  `TEQ Done` cần QC/PO xác nhận.

### `FE` (I) / `BE` (J) — tiến độ hiện tại

- Viết trạng thái **hiện tại**, ngắn, tiếng Việt, giống văn phong đang có:
  `Dev done, PR merged`, `Deployed`, `Đang clean phía BE, kịp release 10/06`.
- Ghi **đè** nội dung cũ (cột này là "hiện tại", không phải lịch sử). Giá trị
  cũ đã có trong reply để khôi phục nếu cần.
- Giữ lại link PR/Slack có sẵn trong ô nếu vẫn còn đúng.
- Thread chỉ nói về BE thì chỉ sửa `BE`, không đụng `FE`.

### `Remark` (K) — tổng hợp FE/BE (+ QC)

Là **text thường** (không phải công thức; đã kiểm tra bản export 2026-10-01).
Format:

```
▶️ FE: <giá trị FE>
▶️ BE: <giá trị BE>

▶️ QC: ...   ← block do QC tự viết, có thể có hoặc không
```

Mỗi khi sửa `FE` hoặc `BE`, dựng lại đúng dòng `▶️ FE:` / `▶️ BE:` tương ứng
(bỏ dòng nếu cột trống), **giữ nguyên** mọi block khác (`▶️ QC:`, ghi chú tự
do). Nội dung nhiều dòng của FE/BE giữ nguyên xuống dòng sau tiền tố.

### `Memo` (L) — ghi chú quyết định

- Dùng cho quyết định không vừa cột nào khác: dời ưu tiên, chờ ai xác nhận,
  đổi scope, đổi assignee.
- **Thêm lên đầu** một dòng `MM/DD: <nội dung>` (ngày theo giờ VN của post
  chốt quyết định), giữ các dòng cũ bên dưới.
- Ví dụ: `10/01: PO chốt ưu tiên delete FF trước, chunk2 dời sang 13/10`.

### `Release SPC` (N) / `Release Anmitsu` (O) — ngày release

- Format `YYYY/MM/DD`, có thể kèm hậu tố `(FF = ON)` / `(FF = OFF)` hoặc dòng
  ghi chú như `(Dev support test ON)`. Nhiều mốc → mỗi mốc một block, **mốc
  mới nhất ở trên**, cách nhau 1 dòng trống.
- Ngày trong chat tiếng Việt là **ngày/tháng**: `6/10` = 6 tháng 10,
  `13/10` = 13 tháng 10. Năm = năm gần nhất không trước ngày của post.
- Dời lịch (mốc cũ chưa từng release) → **thay** mốc trên cùng bằng mốc mới.
  Mốc cũ đã release thật → **giữ** và thêm mốc mới lên trên. Cách phân biệt:
  mốc cũ `YYYY/MM/DD` đã release nếu `releasePRs` có dòng bắt đầu bằng
  `YYYYMMDD_`; không có thì coi là kế hoạch.
- Thread không nói rõ môi trường/sản phẩm → mặc định `Release SPC`.

### `Teq Deadline` (P) — ngày

- Format `M/D/YYYY` (ví dụ `10/6/2026`), đúng định dạng date của cột.
- Chỉ sửa khi thread nói rõ deadline nội bộ TEQ đổi, không suy từ ngày
  release.

### `FeatureFlag` (S)

- Format mỗi flag một dòng: `<flag_name>: Dev:🟢 Stg:⚪️ Prod:⚪️`.
  🟢 = ON toàn bộ, ⚪️ = OFF, 🟡 `<licensee>` = ON một phần (ví dụ `🟡 spc`).
- Chỉ sửa môi trường được nhắc rõ; giữ các flag/môi trường khác.

### `releasePRs` (T)

- Mỗi release một dòng `YYYYMMDD_<repo> v<version>`, ví dụ
  `20260929_azuki v1.103.5`. **Thêm xuống cuối**, không xoá dòng cũ.
- Chỉ thêm khi release đã xảy ra và thread có repo + version; kế hoạch
  release thì ghi vào `Release SPC`, không ghi vào đây.

## Ví dụ chuẩn

Thread (2026-09-30 → 2026-10-01):

> **quanhuynh**: @ngocnguyen [Cleanup FF] Team đã kéo timeline lại rồi nha
> chị. Sẽ done kịp release tuần tới: SPCC-3549, SPCC-3551. Ngoài ra, sẽ test
> thêm các FF đã merged ở SPCC-3550. Chunk_2 có kịp đợt release tuần tới
> không thì mai em sẽ chốt lại ạ (tạm thời đã chốt không kịp)
>
> **ngocnguyen**: Vậy nhờ e note report sơ lên sheet daily nha e.
> @dungnguyen chốt lại như bên dưới nha a: Release kịp thứ 3 tuần sau (6/10)
> SPCC-3549 SPCC-3551. Dời release sang tuần đầu sprint 59: 13/10 SPCC-3550,
> chunk-2. @quanhuynh cứ ưu tiên delete FF, chunk2 có thể tuần sau vẫn đc nha

Tìm dòng: `SPCC-3549` → `CRES-20736`, `SPCC-3551` → `CRES-20739`,
`SPCC-3550` → `CRES-20737` (khớp trong `ユーザーストーリー`/`Description`, cột
`Backlog` trống). `chunk-2` → `CRES-20669` (`…migrate_chunk_2【SPCC-3617】`;
khớp `chunk_2` chính xác, không khớp `chunk_20`…`chunk_29`).

Change plan:

| Ticket | Cột | Cũ | Mới |
|---|---|---|---|
| SPCC-3549 | Release SPC | `2026/09/29` | `2026/10/06` |
| SPCC-3549 | BE | `Đang thực hiện clean phía BE` | `Đang clean phía BE, kịp release 10/06` |
| SPCC-3549 | Remark | `▶️ FE: Deployed`↵`▶️ BE: Đang thực hiện clean phía BE` | `▶️ FE: Deployed`↵`▶️ BE: Đang clean phía BE, kịp release 10/06` |
| SPCC-3551 | (giống SPCC-3549) | | |
| SPCC-3550 | Release SPC | `2026/09/29` | `2026/10/13` |
| SPCC-3550 | BE | `Đang thực hiện clean phía BE` | `Đang clean phía BE + test thêm các FF đã merged, dời release 13/10` |
| SPCC-3550 | Remark | (dựng lại dòng BE) | |
| SPCC-3617 | Release SPC | (trống) | `2026/10/13` |
| SPCC-3617 | Memo | (trống) | `10/01: PO chốt ưu tiên delete FF trước, chunk2 dời sang 13/10` |

Không đổi `Status` (vẫn `In Progress`, thread không nói trạng thái mới).
`2026/09/29` bị **thay** vì `releasePRs` của các dòng này trống, tức 9/29 chỉ
là kế hoạch.
