# Kinako `Icon` enum và cách ánh xạ tập mở → enum đóng

Đọc file này khi làm nhóm **D (enum đóng)** ở Bước 2/4D của `SKILL.md` — điển hình là
`MaterialIcon`, `IconOnlyButton`, `StatusIcon`, hay bất kỳ prop nào mà Vibes nhận giá trị tuỳ ý
còn Kinako chỉ nhận một tập cố định.

## Vì sao đây là một nhóm riêng

Vibes `MaterialIcon` nhận `IconComponent: React.ElementType` — một **tham chiếu React component**
(thường từ `react-icons/md`). Kinako `Icon` nhận `icon: IconType` — một **chuỗi** trong danh sách
cố định dưới đây. Không có phép biến đổi nào đi từ tham chiếu component sang tên enum lúc runtime:
tên biến bị minify khi build, và `Md*` không đảm bảo trùng tên Kinako.

Vì vậy giá trị phải do **caller cung cấp** qua một prop tương thích (xem 4D trong `SKILL.md`),
hoặc component fallback về Vibes khi không có giá trị phù hợp.

## Enum `IconType` của Kinako

Danh sách chụp từ `iconList` trong `src/components/lv1/Icon.tsx` tại tag **v0.14.0** (41 icon).
Luôn lấy lại từ source thay vì docs site trước khi dùng — docs site từng liệt kê thiếu
`closeCircle`, và enum sẽ dài thêm theo mỗi bản phát hành:

```bash
gh api "repos/Finatext/kinako-ui/contents/src/components/lv1/Icon.tsx?ref=v0.14.0" \
  --jq '.content' | base64 -d | sed -n '/export const iconList/,/as const/p'
```

```
chevronLeft   chevronRight  chevronUp     chevronDown   help
helpFilled    error         caution       mail          menu
minus         plus          openInNew     check         checkCircle
clock         close         closeCircle   home          user
pdf           bank          mobile        backup        creditCard
info          redo          dashboard     currencyYen   link
arrowForward  payments      history       dataUsage     face
postAdd       moreHoriz     fileUpload    logout        listCheck
calendarMonth
```

`Icon.tsx` cũng cho biết **mỗi tên enum ánh xạ tới component react-icons nào** (ví dụ `close` →
`MdClose`, `mobile` → `MdOutlinePhoneIphone`, `plus` → `MdAdd`). Đây là thông tin quyết định khi
đánh giá một ánh xạ là "khớp chính xác" hay chỉ "khớp gần đúng" — đọc hàm `component()` trong file
đó thay vì suy từ tên.

Prop khác của `Icon`:

| Prop | Giá trị | Default |
|---|---|---|
| `size` | `extra-small` (16px), `small` (20px), `medium` (24px), `large` (52px), `extra-large` (96px) | `medium` |
| `color` | `neutral`, `success`, `error`, `caution`, `surface`, `foreground`, `primary`, `onPrimary` | `foreground` |
| `ma`/`mt`/`mb`/`ml`/`mr` | `LayoutValue` | — |

Đối chiếu với Vibes `MaterialIcon`: `small?: boolean` (chỉ 2 mức) và `color` với **63 brand token**
(`P1`…`P10`, `S1`…`S10`, `RE*`, `OR*`, `YE*`, `YG*`, `GR*`, `BG*`, `PU*`, `GY*`, `inherit`,
`white`) cộng ba boolean `error`/`notice`/`success`. Ánh xạ màu vì thế là **lossy** — ưu tiên ba
boolean trạng thái (chúng có ngữ nghĩa rõ: `error` → `error`, `success` → `success`, `notice` →
`caution`) và chỉ map các token còn lại khi thật sự tương ứng; token không tương ứng thì bỏ và
ghi lại trong test, theo đúng nhóm `unsupported` trong `prop-mapping.md`.

## Phương pháp dựng bảng ánh xạ

Đừng đoán bằng cách so tên chuỗi — hãy lấy dữ liệu thật rồi quyết định:

```bash
# 1. Kiểm kê giá trị đang dùng thật, kèm tần suất
grep -rho 'IconComponent={[A-Za-z0-9_]*}' src --include='*.tsx' | sed 's/IconComponent={//;s/}//' | sort | uniq -c | sort -rn

# 2. Với mỗi giá trị, đối chiếu enum ở trên rồi xếp vào 1 trong 3 cột
```

Xếp mỗi giá trị vào một trong ba cột — chính tỷ lệ giữa chúng quyết định thiết kế prop:

| Cột | Nghĩa | Ví dụ minh hoạ |
|---|---|---|
| **Khớp chính xác** | Cùng biểu tượng, cùng ngữ nghĩa | `MdChevronLeft` → `chevronLeft`; `MdCheck` → `check`; `MdEmail` → `mail`; `MdPhoneIphone` → `mobile` |
| **Khớp gần đúng** | Biểu tượng khác chút nhưng truyền đạt cùng ý; cần mắt người duyệt | `MdArrowForwardIos` → `arrowForward`; nhóm refresh/reload → `redo` |
| **Không có** | Không icon nào trong enum diễn đạt được | `MdFileDownload` (Kinako chỉ có `fileUpload`), `MdAttachment`, `MdEdit`, `MdVerified` |

Cột "khớp gần đúng" phải được người review xác nhận bằng mắt, không tự quyết chỉ dựa vào tên —
tên giống nhau không đảm bảo hình giống nhau. Ví dụ thật: `MdPhoneIphone` → `mobile` ban đầu bị xếp
"gần đúng" chỉ vì đoán qua tên, nhưng dựng trang so sánh trực tiếp (`Icon` render thật của cả hai
lib, cạnh nhau) thì thấy trùng khớp gần như hoàn toàn — chuyển sang "khớp chính xác". Ngược lại
`MdArrowForwardIos` → `arrowForward` nhìn thật thì lệch rõ: Vibe là chevron `›` (icon "tiến tới"
kiểu iOS), Kinako là mũi tên ngang đầy đủ `→` — khác hẳn về hình dạng dù cùng ngữ nghĩa "forward".
Quyết định cuối: **vẫn giữ mapping này** (không bắt buộc phải khớp pixel-perfect, ngữ nghĩa đủ
dùng được) — nhưng quyết định đó do người xem trực tiếp đưa ra, không phải suy từ tên.

Cách dựng trang so sánh nhanh (không cần trang riêng lâu dài, xoá sau khi verify xong): tạo 1 view
local render cạnh nhau `<MaterialIcon IconComponent={X} />` (Vibe) và
`<Icon {...adaptMaterialIconPropsToKinako({ IconComponent: X, kinakoIcon: 'y' })} />` (Kinako, gọi
thẳng hàm adapter thật thay vì tự viết prop tay), thêm 1 route tạm trong `router.tsx` để xem qua
browser mà không cần đăng nhập. Xem `example-prs.md` mục compose để biết cách dựng.

### Quyết định prop bắt buộc hay tuỳ chọn

Đếm theo **số lần xuất hiện**, không phải số icon riêng biệt — vài icon dùng rất nhiều có sức
nặng hơn một danh sách dài icon dùng một lần.

- Cột "không có" chiếm phần nhỏ → để prop **bắt buộc**, TypeScript ép caller khai báo lúc migrate
  call site. Đây là trường hợp của `IconOnlyButton` trong PR #2780.
- Cột "không có" chiếm phần đáng kể → để prop **tuỳ chọn** và fallback về Vibes khi thiếu (kết
  hợp nhóm C). Ép caller điền một giá trị không tồn tại chỉ tạo ra ánh xạ sai âm thầm.

Với `MaterialIcon` ở azuki-app, khảo sát tại thời điểm viết cho thấy phần lớn lượt dùng rơi vào
cột "không có" (`MdFileDownload`, `MdAttachment`, `MdVerified`, `MdEdit`, `MdBadge`… đều không có
trong enum 40 icon) — nên tuỳ chọn + fallback là hướng phù hợp. Hãy chạy lại lệnh kiểm kê ở trên
để có số liệu hiện tại thay vì tin con số này.

## Bẫy thường gặp

- **Icon ngoài bộ Material.** Codebase có chỗ dùng `AiOutlineReload` (react-icons/ai) trong khi
  chính JSDoc của Vibes `MaterialIcon` yêu cầu chỉ dùng Material Design icons. Đừng im lặng map
  nó — hoặc fallback, hoặc nêu trong PR để team quyết.
- **Prop tương thích rò ra DOM.** Tách nó khỏi props trước khi render nhánh Vibes, nếu không React
  cảnh báo unknown prop và attribute lạ lọt vào HTML. `test-matrix.md` gọi case này là
  "Prop tương thích".
- **Ánh xạ bằng heuristic tên.** Kiểu `name.replace(/^Md/, '')` rồi lowercase đầu — chạy được với
  vài icon rồi sai âm thầm với phần còn lại, và không ai phát hiện tới khi lên staging.
