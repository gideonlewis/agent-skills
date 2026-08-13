# Nhóm D và E — hai ca dễ sai nhất

Nhóm A/B/C có nhiều tiền lệ trong repo, cứ theo `example-prs.md`. Hai nhóm dưới đây thì không, và
sai ở đây thường chỉ lộ ra khi lên staging.

---

## Nhóm D — Enum đóng

### Dấu hiệu

Vibes nhận **tập mở**, Kinako nhận **enum cố định**. Điển hình: `MaterialIcon` nhận
`IconComponent: React.ElementType` (bất kỳ component nào từ react-icons), còn Kinako `Icon` nhận
`icon: IconType` — một chuỗi trong danh sách ~41 tên.

### Vì sao không tự động hoá được

Không có phép biến đổi nào đi từ tham chiếu component sang tên enum lúc runtime: tên biến bị
minify khi build, và `Md*` không đảm bảo trùng tên Kinako. Mọi mưu mẹo kiểu
`name.replace(/^Md/, '')` rồi lowercase đều chạy được với vài icon rồi sai âm thầm với phần còn
lại.

### Cách giải: prop tương thích nhỏ nhất

Mở rộng public prop bằng đúng một field để caller tự chỉ định. Tiền lệ đã merge (PR #2780):

```ts
// Kinako's icon set is a fixed enum, unlike Vibe's arbitrary IconComponent, so callers must
// supply the closest matching Kinako icon name explicitly via `kinakoIcon`.
export type IconOnlyButtonProps = ComponentProps<typeof VibeIconOnlyButton> & {
  kinakoIcon: IconProps['icon']
}
```

### Bắt buộc hay tuỳ chọn?

Đối chiếu giá trị **đang dùng thật** với enum Kinako, đếm theo **số lượt xuất hiện** chứ không
phải số giá trị riêng biệt — vài icon dùng rất nhiều có sức nặng hơn danh sách dài icon dùng một
lần.

| Tình huống | Quyết định |
|---|---|
| Hầu hết call site map được | **Bắt buộc** — TypeScript ép caller khai báo lúc migrate. Đây là `IconOnlyButton`. |
| Phần đáng kể không map được | **Tuỳ chọn** + fallback về Vibe khi thiếu (kết hợp nhóm C). Đây là `MaterialIcon`. |

Ép bắt buộc trong tình huống thứ hai nghĩa là bắt mọi call site điền một giá trị không tồn tại —
đi ngược mục tiêu giữ nguyên API Vibes.

```ts
export const canRenderKinakoMaterialIcon = (
  props: Pick<MaterialIconProps, 'kinakoIcon'>,
): boolean => props.kinakoIcon !== undefined
```

### Prop tương thích phải bị loại trước khi render Vibe

Nó không phải prop Vibes hợp lệ; để lọt xuống thì React cảnh báo unknown prop và DOM lộ attribute
lạ. Destructuring đặt **ngay trước lệnh return nhánh Vibe**, không đặt ở signature — để ở signature
thì nhánh Kinako lại phải ghép props về như cũ:

```tsx
export const IconOnlyButton = (props: IconOnlyButtonProps) => {
  const isKinakoActive = useGetComponentActive('IconOnlyButton')

  if (isKinakoActive && !hasLinkProps(props)) {
    return (
      <KinakoIconButton
        {...dataTestAttributes('IconOnlyButton')}
        {...adaptIconOnlyButtonPropsToKinako(props)}
      />
    )
  }

  const { kinakoIcon: _kinakoIcon, ...vibeProps } = props
  return (
    <VibeIconOnlyButton {...dataTestAttributes('IconOnlyButton')} {...vibeProps} />
  )
}
```

Đổi tên thành `_kinakoIcon` để lint không báo biến không dùng.

Chú ý điều kiện `isKinakoActive && !hasLinkProps(props)`: **nhóm D hiếm khi đứng một mình**. Một
component nhận tập mở thường cũng có mode mà Kinako không biểu diễn nổi, nên hãy kiểm tra xem có
cần guard nhóm C không trước khi coi là xong.

Xem `kinako-icon-enum.md` để biết enum hiện có và cách dựng bảng ánh xạ.

---

## Nhóm E — Kinako không có tương đương

### Trước hết: xác minh là thật sự không có

Cột "Kinako Equivalent = None" trong ticket là phỏng đoán lúc planning. Duyệt danh sách component
thật trước khi tin:

```bash
gh api "repos/Finatext/kinako-ui/git/trees/<tag>?recursive=true" --jq '.tree[].path' \
  | grep '^src/components/lv1/'
```

Cẩn thận với thứ *trông giống* mà không phải: Kinako có `SkeletonCircle` mô tả là "avatar", nhưng
đó là placeholder lúc loading chứ không phải avatar thật.

### Có hai kết cục hợp lệ

**1. Dựng lại được từ primitive** — dùng `Stack`/`Card`/`Icon` của Kinako, cộng phần tử HTML
thường cho những gì primitive không diễn đạt được.

Ràng buộc then chốt: *không áp CSS tuỳ ý trực tiếp lên component Kinako*. Đặt CSS lên phần tử HTML
bọc ngoài. Ví dụ `Avatar` — Kinako không có, dựng lại bằng `Icon` (fallback người) + `Stack`
(margin/data-test) + một `<span>` tròn tự vẽ:

```tsx
<KinakoStack {...dataTestAttributes('Avatar')} {...adaptAvatarWrapperPropsToKinako(props)}>
  <span
    css={{
      width: `calc(var(--spacing) * ${sizeUnit})`,
      height: `calc(var(--spacing) * ${sizeUnit})`,
      borderRadius: 'var(--radius-lg)',
      overflow: 'hidden',
    }}
  >
    {showImage ? <img src={props.imageUrl} alt="avatar" onError={() => setHasError(true)} /> : (
      <KinakoIcon icon="user" size={resolveAvatarFallbackIconSize(props.size)} color="neutral" />
    )}
  </span>
</KinakoStack>
```

(`sizeUnit` ở đây là con số x đã tra được từ bước grep token phía trên — không phải px cứng.)

Nguyên tắc giúp bản dựng lại không lệch:

- **Ưu tiên prop và design token của Kinako hơn giá trị px/hex cứng — và đây là một bước tra cứu
  bắt buộc, không phải khẩu hiệu để nhớ suông.** Trước khi viết bất kỳ số px, mã hex, hay giá trị
  CSS cứng nào, grep file CSS build ra của Kinako tìm token khớp:

  ```bash
  grep -o -- '--[a-z-]*:[^;]*' node_modules/@Finatext/kinako-ui/dist/kinako-ui.css | sort -u \
    | grep -i 'radius\|spacing\|color'
  ```

  Ca thật đã lọt qua review vì bỏ bước này: `Avatar` viết `resolveAvatarSizePx` trả về số px cứng
  (24/32/48/96) và `borderRadius: '9999px'`, trong khi Kinako có sẵn spacing token dạng
  `calc(var(--spacing) * x)` (đối chiếu bảng size ở `src/components/lv1/Icon.tsx`:
  `w-4`→x=4, `w-5`→x=5, `w-13`→x=13, `w-24`→x=24, `w-6`→x=6) và `--radius-lg`. Biết nguyên tắc mà
  không tra token thật thì vẫn viết sai — đọc xong bullet này phải chạy lệnh trên, không phải chỉ
  ghi nhớ.
- Hành vi có state — như `Avatar` prefetch ảnh rồi fallback khi lỗi — thuộc về **wrapper**, không
  phải adapter. Adapter phải giữ thuần mới unit-test được. Nhưng cũng đừng tự thêm state phức tạp
  hơn mức component thật sự cần: nếu component hiếm khi được dùng và Console không đặt nặng hiển
  thị hình ảnh, một `onError` đơn giản (ẩn ảnh lỗi) có thể đủ — không nhất thiết phải tái tạo toàn
  bộ cơ chế fallback của Vibe. Việc này cần hỏi người review nếu không chắc mức độ ưu tiên thật của
  component, vì đó là quyết định nghiệp vụ, không suy được từ code.
- Đọc JSDoc của Vibes để lấy đúng hành vi gốc (kích thước thật của từng `size`, điều kiện fallback)
  rồi tái hiện, thay vì phỏng đoán từ tên prop.
- Phần tử HTML tự dựng (thay cho việc Kinako không có primitive) vẫn cần thuộc tính accessibility
  cơ bản như component gốc — ví dụ `<img>` cần `alt` mô tả thật, không phải `alt=""` cho có. Đây là
  markup do mình tự viết, không phải wrapper của một component Kinako đã tự lo accessibility, nên
  không được bỏ qua.

**2. Không dựng nổi thì giữ Vibe.** Khi Kinako không có gì để ghép — ví dụ `NoDataIllust` là một
illustration mà Kinako không có bất kỳ primitive artwork nào — wrapper cứ render Vibe, kèm comment
nói rõ vì sao và khi nào nên xem lại:

```tsx
/**
 * Kinako has no illustration/artwork primitive of any kind (confirmed against the full component
 * list) — there is nothing to compose an equivalent from, unlike Avatar's `Icon` fallback. This
 * wrapper always renders Vibe; it exists so call sites import from the same shared path as every
 * other adapted component, and so the default `data-test` is applied consistently.
 */
```

Trường hợp này **không tạo file adapter rỗng** — không có gì để chuyển đổi thì file đó là dead
code, người sau tưởng là thiếu sót rồi đi "sửa". Ba file (`<X>.tsx`, `<X>.test.tsx`, `index.ts`)
là đủ.

### Đừng tự vẽ thay thế gần đúng

Nếu dựng lại mà mất một hành vi không thể thay thế, hoặc phải tự vẽ SVG thay cho illustration của
designer, đó là tín hiệu chọn kết cục 2 chứ không phải cố cho bằng được. Một phiên bản "gần giống"
lọt lên staging khó phát hiện hơn nhiều so với việc thành thật giữ Vibe.
