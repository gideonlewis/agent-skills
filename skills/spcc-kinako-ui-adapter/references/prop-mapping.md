# Bảng prop mapping

Lập bảng này ở Bước 2, **trước khi** viết code. Mục đích không phải làm tài liệu mà là ép trả lời
từng prop sẽ đi đâu — nếu để tới lúc viết test mới phát hiện một prop không xử lý được, thường
phải đổi cả cách tiếp cận.

## Mẫu

| Vibes input | Kinako output | Nhóm | Default / quy tắc | Hành vi khi không hỗ trợ | Test |
|---|---|---|---|---|---|
| `children` | `children` | direct | giữ nguyên | — | giá trị được giữ |
| `appearance` | `variant` | renamed | khớp default nhìn thấy được của Vibes | — | cả giá trị chỉ định và bỏ trống |
| `href` | `to` | transformed | chỉ ở link mode | fallback nếu Kinako không render link | nhánh link và nhánh button |

## Bảy nhóm prop

| Nhóm | Nghĩa |
|---|---|
| **direct** | Giữ nguyên giá trị, không đổi ngữ nghĩa |
| **renamed** | Giữ nguyên giá trị nhưng đổi tên prop |
| **transformed** | Đổi giá trị, hoặc phân biệt mode của Kinako |
| **defaulted** | Cấp giá trị để giữ đúng hành vi nhìn thấy được của bản cũ |
| **composed** | Dựng lại bằng primitive Kinako với cấu hình cố định |
| **unsupported** | Bỏ có chủ đích, và test khẳng định nó vắng mặt |
| **fallback-only** | Render Vibe khi mode prop hiện tại không biểu diễn an toàn được |

Phân biệt **defaulted** với **direct** là chỗ hay sai nhất. Một prop bỏ trống ở cả hai bên vẫn có
thể ra kết quả khác nhau nếu default hai thư viện khác nhau — lúc đó nó là `defaulted`, phải resolve
tường minh, chứ không phải `direct`.

## Đừng bỏ sót các nhóm prop này

Duyệt qua danh sách khi lập bảng: event handler, điều hướng (`href`/`target`/`rel`/`download`),
icon, size, variant, trạng thái disabled, width, margin (cả functional `mt` lẫn legacy
`marginTop` + `marginSize`), data attribute, thuộc tính ARIA, hành vi responsive, và các alias
deprecated.

**Nhưng "có trong danh sách" không tự động nghĩa là "phải hỗ trợ".** Type của Vibes khai báo một
prop (kể cả alias deprecated) không chứng minh nó *được dùng thật*. Trước khi xếp một prop vào
nhóm `transformed`/`composed` (tức là bỏ công viết logic chuyển đổi cho nó), grep xác nhận có call
site thật dùng:

```bash
grep -rn '<X' src --include='*.tsx' -A5 | grep -E 'marginTop|marginSize|<prop-nghi-ngo>'
```

Không có kết quả thật → xếp `unsupported`, không viết code xử lý, chỉ ghi JSDoc note cho dev biết
prop đó tồn tại trên type nhưng không được adapter hỗ trợ (xem mẫu JSDoc trong
`typography/Typography.tsx` của repo). Viết sẵn logic cho một nhánh không ai gọi tới là dead code —
tốn công bảo trì, và làm bảng prop mapping trông "đầy đủ" hơn thực tế.

## Ví dụ đã làm thật — `MaterialIcon`

| Vibes input | Kinako output | Nhóm | Quy tắc | Test |
|---|---|---|---|---|
| `IconComponent` | — | unsupported | tham chiếu react-icons, không map được sang enum | không xuất hiện trong output |
| *(prop mới)* `kinakoIcon` | `icon` | transformed | caller tự chỉ định; thiếu thì fallback Vibe | truyền đúng vào `icon` |
| `small` | `size` | transformed | `small` → `'small'`, còn lại `'medium'` | cả hai nhánh |
| `error`/`notice`/`success` | `color` | transformed | ưu tiên hơn `color`; `notice` → `caution` | từng boolean |
| `color` (63 token) | `color` (8 giá trị) | transformed | chỉ map token khớp chắc chắn, còn lại bỏ | token khớp và token không khớp |
| `pointerEvents` | — | unsupported | Kinako không có | không xuất hiện |
| `label` | — | composed | Kinako `Icon` không có slot aria-label; bọc `<span role="img">` | có accessible name |
| `ma`/`mt`/`mb`/`ml`/`mr` | `ma`/`mt`/... | direct | dùng `pickMarginProps` | giá trị được giữ |
| `marginTop`/`marginSize`/... (legacy) | — | **unsupported** | type cho phép nhưng grep call site thật ra 0 kết quả — không hỗ trợ, chỉ ghi JSDoc note | không xuất hiện trong output |
| `data-*` | `dataTest`/`dataGuide`/... | renamed | dùng `adaptDataAttributesToKinako` | caller ghi đè được mặc định |

Điểm đáng học từ bảng này: `color` có 63 giá trị bên Vibes nhưng chỉ 8 bên Kinako. Cám dỗ là map
hết bằng cách tìm màu "gần giống". Cách đúng là chỉ map những token có tương ứng chắc chắn, còn
lại trả `undefined` để Kinako dùng default của nó — sai màu âm thầm khó phát hiện hơn nhiều so với
màu về mặc định.

**Sửa lại từ một sai lầm thật:** bản đầu của bảng này từng xếp margin legacy vào `transformed` và
gọi `pickMarginPropsWithLegacy`, vì `MaterialIcon.d.ts` có khai `& MarginClassProps`. Bị reviewer
bắt lỗi: không call site `MaterialIcon` nào trong repo thật sự dùng `marginTop`/`marginSize` —
grep xác nhận 0 kết quả. Hỗ trợ nó chỉ vì type cho phép là suy diễn từ type, không phải từ usage
thật — đúng lỗi mà mục "Nhưng 'có trong danh sách'..." phía trên cảnh báo. Bài học: **kiểm tra
usage thật cho từng prop riêng lẻ**, đừng chỉ kiểm tra usage của toàn bộ component rồi giả định mọi
prop trong type đều cần hỗ trợ như nhau.
