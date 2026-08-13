---
name: azuki-kinako-ui-adapter
description: >
  Triển khai adapter cho MỘT component Vibe UI (@freee_jp/vibes) sang Kinako UI
  (@Finatext/kinako-ui) trong repo azuki-app, sau feature flag kinako_enabled_components. Đây là
  hướng dẫn tự chứa, không cần đọc skill nào khác. Dùng bất cứ khi nào người dùng nói "làm
  adapter cho <component>", "chuyển <component> sang Kinako", "tạo wrapper feature-flag cho
  Icon/Link/Tag/Modal/Avatar...", hoặc đưa một ticket "KinakoUI migration_Adapter creation"
  (series SPCC-3309…SPCC-3346, CRES-194xx) — với ticket nhiều component thì chạy skill này lặp
  lại, mỗi lần một component. Đặc biệt cần khi Kinako không có component tương đương, hoặc khi
  prop Vibes là tập mở còn Kinako là enum đóng. Không dùng cho việc thay import Vibe trong
  view/page sang wrapper đã có (đó là bước migration sau), cũng không dùng cho feature flag phía
  backend (xem azuki-feature-flag-implementation).
argument-hint: "<tên component Vibes, vd MaterialIcon> [Kinako equivalent] [CRES-XXXX]"
---

# Kinako UI Adapter — một component mỗi lần

Console FE của azuki-app đang migrate từ `@freee_jp/vibes` sang `@Finatext/kinako-ui`. Cách làm:
giữ nguyên API Vibes ở call site, coi Kinako là implementation nội bộ bật/tắt bằng feature flag
`kinako_enabled_components`. Nhờ vậy migration diễn ra dần và rollback được bằng cách tắt flag.

## Phạm vi

Skill này làm **đúng một component family**, từ nghiên cứu tới commit. Cố ý giữ hẹp: mỗi component
có ràng buộc rất khác nhau, gộp nhiều component vào một lượt thì quyết định của component sau bị
kéo theo quán tính của component trước.

- Ticket nhiều component (ví dụ SPCC-3337 có `MaterialIcon`, `Avatar`, `NoDataIllust`) → chạy
  skill này ba lần, mỗi lần một component, mỗi lần một commit riêng.
- Ngoài phạm vi: đọc/phân tích ticket để quyết định làm những component nào, và mở PR. Đó là việc
  ở mức ticket, làm một lần sau khi mọi component đã xong.

Nếu người dùng đưa cả ticket, hãy nêu danh sách component rút ra được, rồi làm lần lượt từng
component theo skill này — đừng trộn chúng vào chung một lượt phân tích.

## Bước 1 — Nghiên cứu trước khi viết dòng nào

Sai lầm tốn kém nhất ở đây là đoán prop. Vibes và Kinako có default khác nhau ở nhiều chỗ, và
những khác biệt đó không suy ra được từ tên prop.

### Kinako — theo thứ tự tin cậy giảm dần

```bash
# 1. Source thật tại tag mới nhất — chính xác nhất, cho literal type nguyên vẹn
gh api repos/Finatext/kinako-ui/tags --jq '.[0].name'          # tag mới nhất
gh api "repos/Finatext/kinako-ui/git/trees/<tag>?recursive=true" --jq '.tree[].path'
gh api "repos/Finatext/kinako-ui/contents/src/components/lv1/Icon.tsx?ref=<tag>" \
  --jq '.content' | base64 -d

# 2. Docs site — tiện để nắm nhanh, nhưng là văn xuôi nên có thể thiếu/lệch so với source
curl -s https://kinako-ui.azuki-devtool.net/llms.txt          # danh sách component
curl -s https://kinako-ui.azuki-devtool.net/llms-full.txt     # API đầy đủ, prop + default

# 3. node_modules — chỉ có sau `pnpm install`, là bản build nên khó đọc hơn source
ls node_modules/@Finatext/kinako-ui/dist
```

Khi cần **danh sách giá trị chính xác** của một union type, luôn lấy từ source GitHub. Docs site
từng liệt kê thiếu một giá trị so với source — đủ để một bảng ánh xạ trông có vẻ đầy đủ nhưng lại
bỏ sót lựa chọn đúng.

kinako-ui phát hành rất nhanh, nên **đọc bản mới nhất** thay vì bản `package.json` đang ghim: mục
tiêu migration là bắt kịp Kinako. Nếu bản mới có thứ mà version đang ghim chưa có, nêu trong PR để
team quyết bump hay chờ.

### Vibes

```bash
# Type + JSDoc tiếng Nhật mô tả hành vi thật (default size, điều kiện fallback...)
cat node_modules/@freee_jp/vibes/dist/lv1/icons/MaterialIcon.d.ts
# Class CSS component render ra — cần cho assert trong test wrapper
grep -o 'vb-[a-zA-Z]*' node_modules/@freee_jp/vibes/dist/lv1/icons/MaterialIcon.js | sort -u
```

Storybook chính thức: <https://vibes.freee.co.jp> — dùng khi cần thấy component **trông như thế
nào**, thứ `.d.ts` không cho biết. Nhưng storybook chỉ cho thấy Vibes một mình — không trả lời
được "cái này có giống bản Kinako không?".

Khi cần quyết một ánh xạ "gần đúng" (nhóm D, hoặc bất kỳ chỗ nào default hai bên có thể lệch), tên
gọi giống nhau **không đảm bảo** trông giống nhau — dựng nhanh 1 trang test render **cả hai cạnh
nhau**, xem bằng browser thật, đừng đoán từ tên:

1. Tạo `src/views/<TenTamThoi>.tsx` render `<Vibe... />` và `<Kinako... />` (hoặc gọi thẳng hàm
   `adapt<X>PropsToKinako` thật, không tự viết prop tay) cho từng cặp cần so sánh.
2. Thêm 1 route tạm trong `router.tsx`, đặt cạnh `/signin` (không cần đăng nhập) để xem được ngay.
3. Mở bằng browser, so sánh trực tiếp.
4. Xoá cả file và route trước khi commit — đây là công cụ nghiên cứu, không phải sản phẩm.

Ca thật đã gặp: `MdPhoneIphone → mobile` đoán "gần đúng" qua tên, dựng trang xem thì trùng khớp
gần như hoàn toàn → chuyển thành "khớp chính xác". Ngược lại `MdArrowForwardIos → arrowForward`
tên nghe hợp lý nhưng nhìn thật thì lệch rõ (chevron `›` vs mũi tên đầy đủ `→`). Không dựng trang
so sánh thì không phát hiện được cả hai.

### Call site thật trong repo

Con số này quyết định nhiều lựa chọn ở Bước 2 — đặc biệt là nhóm D:

```bash
grep -rl '\bMaterialIcon\b' src --include='*.tsx' | wc -l
grep -rn '<MaterialIcon' src --include='*.tsx' -A3 | head -40
```

### Tài liệu của team

Backlog document <https://teq-dev.backlog.com/document/SPCC/019f1bd7abc77701b20b03bece43daed>:

| Nguồn | Dùng để |
|---|---|
| [Official sheet](https://docs.google.com/spreadsheets/d/1l49izoyEjeKHL62lzo-wJoXIL_LMuFe6vVFaESU2zUQ) | Danh sách đầy đủ adapter của dự án — xem component liên quan đã ai làm chưa |
| [Feature flags draft](https://docs.google.com/spreadsheets/d/14rxJyhPJTvcYM1QlwH8ZEocSH2GGS1W1VmujJgbuN5w) | Kế hoạch bật/tắt qua `kinako_enabled_components` — đối chiếu tên component dùng làm key |

## Bước 2 — Phân loại rồi lập bảng prop mapping

Xếp component vào một nhóm. Chọn sai nhóm thì viết lại gần như từ đầu, nên làm bước này trước khi
gõ dòng code nào.

| Nhóm | Dấu hiệu nhận biết | Cách làm |
|---|---|---|
| **A. Ánh xạ trực tiếp** | Kinako có component tương đương, mọi prop đang dùng đều map được | adapter thuần, map prop-by-prop |
| **B. Compose từ primitive** | Không có tương đương 1:1 nhưng dựng lại được bằng `Stack`/`Card` Kinako | wrapper tự đặt children vào cây primitive |
| **C. Guard fallback** | Đa số prop map được, nhưng có *mode* không biểu diễn nổi | thêm `canRenderKinako<X>(props)`, wrapper fallback về Vibes |
| **D. Enum đóng** | Vibes nhận **tập mở**, Kinako chỉ nhận **enum cố định** | thêm prop tương thích nhỏ nhất cho caller |
| **E. Không có tương đương** | Kinako không có gì cùng vai trò | dựng lại từ primitive + phần tử HTML bọc ngoài, hoặc giữ Vibes nếu không dựng nổi |

Một component thường rơi vào nhiều nhóm cho từng prop khác nhau — lấy nhóm "nặng" nhất làm cách
tiếp cận chính. Ví dụ `MaterialIcon` là D (icon enum đóng) **cộng** C (không có icon phù hợp thì
fallback), và điều đó là bình thường: nhóm D hiếm khi đứng một mình.

Sau khi chọn nhóm, lập bảng prop mapping theo `references/prop-mapping.md` — bảng này buộc phải
trả lời từng prop sẽ đi đâu, thay vì phát hiện thiếu sót lúc đang viết test.

Rồi đọc code mẫu tương ứng với nhóm đã chọn:

- **Nhóm A/B/C** — `references/example-prs.md` có code thật đã review cho cả ba, kèm `base.ts` đầy
  đủ và test mẫu. Copy cấu trúc từ đó thay vì dựng lại từ mô tả.
- **Nhóm D/E** — `references/hard-cases.md`, hai nhóm dễ sai nhất nên có hướng dẫn riêng.

## Bước 3 — File layout

Mỗi component family một thư mục dưới `src/components/shared/<tenComponent>/` (thư mục camelCase,
file component PascalCase):

| File | Vai trò |
|---|---|
| `<X>.tsx` | Wrapper feature-flag: đọc `useGetComponentActive('<X>')`, chọn Kinako hay Vibe |
| `<x>Adapter.ts` | Hàm **thuần** `adapt<X>PropsToKinako(props)` + type; thêm `canRenderKinako<X>` nếu cần guard |
| `<X>.test.tsx` | Test wrapper (render thật) |
| `<x>Adapter.test.ts` | Test adapter (không render) |
| `index.ts` | Barrel export component + prop type |

Helper dùng chung nằm ở `src/components/shared/base.ts`, **không** nhân bản vào từng thư mục
component. Đọc file đó trước khi viết bất kỳ hàm chuyển đổi nào — nhiều thứ đã có sẵn:
`pickMarginProps`, `pickMarginPropsWithLegacy`, `adaptDataAttributesToKinako`,
`dataTestAttributes`, `pickInteractiveAriaProps`. Nếu cần một hàm chuyển đổi dùng được cho nhiều
component, đặt nó vào `base.ts` chứ đừng để trong thư mục component.

Số file có thể ít hơn 5 nếu có lý do thật (ví dụ component luôn fallback về Vibe thì không có gì
để adapter làm) — nhưng phải ghi rõ lý do trong comment, đừng tạo file rỗng cho đủ bộ.

## Bước 4 — Adapter thuần

```ts
export type <X>Props = ComponentProps<typeof Vibe<X>>

export const adapt<X>PropsToKinako = (props: <X>Props): Kinako<X>Props => ({ ... })
```

Nguyên tắc:

- **Chọn field một cách tường minh**, không spread cả props Vibes vào Kinako — prop legacy lọt
  sang sẽ thành attribute lạ trên DOM.
- **Không hook, không render, không đọc feature flag** trong adapter. Giữ thuần thì mới unit-test
  được mà không cần dựng DOM.
- **Mọi giá trị px/hex/CSS cứng phải tra token Kinako trước, không viết tay.** Grep file CSS build
  ra của Kinako (`node_modules/@Finatext/kinako-ui/dist/kinako-ui.css`) tìm `--color-*`,
  `--radius-*`, `--spacing` khớp trước khi gõ một con số hay mã màu. Đây là ca thật đã lọt qua
  review: viết `borderRadius: '9999px'` và size bằng số px cứng thay vì `var(--radius-lg)` và
  `calc(var(--spacing) * x)` — nguyên tắc "ưu tiên token" đã biết, chỉ là không tra trước khi viết.
  Chi tiết + lệnh grep cụ thể ở `references/hard-cases.md`.
- **Chỉ hỗ trợ (nhóm `transformed`/`composed`) một prop khi grep xác nhận có call site thật dùng
  nó — không suy từ việc type cho phép.** Type Vibes khai một prop (kể cả legacy/deprecated)
  không chứng minh nó được dùng. Ca thật: `MaterialIcon.d.ts` khai `& MarginClassProps` (legacy
  margin), viết hẳn logic hỗ trợ, nhưng grep call site thật ra 0 kết quả — dead code, bị review bắt.
  Prop không ai dùng thì xếp `unsupported`, chỉ ghi JSDoc note.
- **Giải thích bằng comment khi default hai bên khác nhau — nhưng ngắn gọn.** Không mô tả lại code,
  mà nói vì sao phải resolve thủ công, trong 1 dòng nếu được. Ví dụ Vibes `Stack` đổi default
  `alignItems` theo `direction`, còn Kinako luôn mặc định `start` — không viết ra thì người sau
  tưởng là thừa và xoá đi. Nhưng comment dài dòng, giải thích lại thứ code đã tự nói rõ, cũng bị
  review coi là nhiễu — nếu một dòng đủ nói hết lý do, đừng viết thành đoạn văn.
- **Prop không map được thì bỏ có chủ đích và ghi lại**, kèm test khẳng định nó không lọt sang.
- Giữ nguyên event handler, thuộc tính accessibility, data attribute, margin và ngữ nghĩa điều
  hướng ở những chỗ Kinako hỗ trợ.

## Bước 5 — Wrapper feature-flag

```tsx
export const <X> = (props: <X>Props) => {
  const isKinakoActive = useGetComponentActive('<X>')

  if (isKinakoActive /* && canRenderKinako<X>(props) nếu có guard */) {
    return (
      <Kinako<X>
        {...dataTestAttributes('<X>')}
        {...adapt<X>PropsToKinako(props)}
      />
    )
  }

  return <Vibe<X> {...dataTestAttributes('<X>')} {...props} />
}
```

- Key của `useGetComponentActive` phải là **đúng tên export của `@freee_jp/vibes`**
  (`VibesComponentsKey = keyof typeof Vibes`), vì flag là danh sách tên phân tách bằng dấu phẩy.
- `dataTestAttributes(...)` spread **trước** props để giá trị `data-test` do caller truyền ghi đè
  được mặc định. Đảo thứ tự là mặc định thắng caller — sai và test rất dễ bỏ sót.
- Type props công khai vẫn là type của Vibes. Đây là hợp đồng ổn định với call site; Kinako chỉ là
  chi tiết bên trong.
- Nếu có `canRenderKinako<X>`, **phải gọi nó ở điều kiện** chứ không chỉ export. Export mà không
  wire là lỗi đã xảy ra thật trong repo.

## Bước 6 — Test

Chọn case theo `references/test-matrix.md`. Bốn case tối thiểu cho mọi wrapper:

1. `data-test` của caller thắng giá trị mặc định
2. Flag bật → render Kinako
3. Flag tắt → render Vibe
4. Có guard → props kích hoạt guard vẫn ra Vibe dù flag bật

```tsx
vi.mock('@/hooks/useAdapterFeatureFlags/useGetComponentActive.ts', () => ({
  useGetComponentActive: vi.fn(),
}))
const mockUseGetComponentActive = vi.mocked(useGetComponentActive)
```

Trước khi viết assert về class, **đọc phần `return` của component Kinako** để biết nó render ra
cây DOM nào. Không phải component nào cũng đặt class và `data-test` cùng một node: `Stack`/`Card`
đặt cả hai trên cùng `<div>`, nhưng `Icon` đặt `data-test` trên `<span>` ngoài còn class
`kinako-icon-root` xuống `<svg>` bên trong.

## Bước 7 — Verify và commit

```bash
pnpm test:unit:ci -- src/components/shared/<tenComponent>
pnpm tsc
pnpm lint
pnpm exec prettier --check src/components/shared/<tenComponent>
```

Chạy cả bộ test một lần nếu có sửa `base.ts` — file đó dùng chung với các component đã merge.
`prettier` bắt được thứ `lint:eslint` bỏ qua, nên đừng bỏ bước này.

Commit **một component một commit**, theo conventional commit; mã ticket `CRES-XXXX` chỉ nằm ở
tiêu đề PR chứ không ở commit message:

```bash
git commit -m "feat: add MaterialIcon component with Kinako adaptation"
```

Nếu có sửa `base.ts`, tách thành commit riêng **đứng trước** commit component, vì nó ảnh hưởng cả
component đã merge trước đó và reviewer cần thấy tách bạch. Là fix cho hành vi sẵn có thì dùng
`fix:` chứ không phải `feat:`.

## Guardrails

- **Không áp CSS tuỳ ý (`css`, `className`, inline `style`) trực tiếp lên component Kinako.** Đó
  là chọc vào nội bộ Kinako và sẽ vỡ khi Kinako đổi implementation. Cần CSS thì đặt lên phần tử
  HTML bọc ngoài, hoặc dùng chính prop của Kinako (`size`, `pa`, `gap`, `variant`).
- **Không âm thầm biến link thành button** hay bỏ hành vi điều hướng. Nếu Kinako không render được
  link ở mode đó, fallback về Vibe.
- **Không để `data-test` mặc định ghi đè giá trị của caller.**
- **Không nhân bản một hàm chuyển đổi dùng chung** vào trong adapter của component.
- **Không lộ chi tiết Kinako ra API công khai**, trừ đúng input tương thích không thể tránh (nhóm
  D). Mỗi prop thêm vào là một prop call site phải biết tới.
- Forwarding accessibility phải tường minh; mở rộng allowlist chỉ sau khi kiểm tra Kinako có hỗ
  trợ thật.

## Checklist

- [ ] Đã tra Kinako bằng **source GitHub tại tag**, không chỉ docs site
- [ ] Đã đọc `.d.ts` + JSDoc của Vibes, không đoán default từ tên prop
- [ ] Đã xếp nhóm A–E và lập bảng prop mapping trước khi code
- [ ] Đã đọc `base.ts` và tái dùng helper sẵn có thay vì viết lại
- [ ] Đã grep `kinako-ui.css` tìm token cho mọi giá trị px/hex/CSS cứng — chưa viết số tay
- [ ] Mỗi prop được hỗ trợ (không phải `unsupported`) có grep xác nhận call site thật dùng, không
      suy từ type
- [ ] Adapter thuần: không hook, không render, không đọc flag
- [ ] Wrapper: `dataTestAttributes` spread trước props; guard (nếu có) được gọi chứ không chỉ export
- [ ] Test đủ 4 case cơ bản, assert class đúng node DOM
- [ ] `pnpm tsc`, `pnpm lint`, `prettier --check`, `pnpm test:unit:ci` pass
- [ ] Commit riêng cho component này; sửa `base.ts` tách thành commit riêng đứng trước

## Anti-patterns

- Tin cột "Kinako Equivalent" trong ticket mà không tra docs — bảng đó lập lúc planning, thực tế
  prop hay lệch; có ca ghi tên component nhưng dùng không được, có ca ghi "None" nhưng ghép được
  từ primitive.
- Chép logic margin/padding/data-attribute vào từng adapter thay vì dùng `base.ts` — đã phải dọn
  một lần khi `marginBaseAdapter.ts` trùng với `base.ts`.
- Ép ánh xạ enum đóng bằng heuristic tên chuỗi (`name.replace(/^Md/, '')`) — sai âm thầm, không ai
  phát hiện tới khi lên staging.
- Thêm guard `canRenderKinako<X>` cho component mà mọi prop đều map được — guard thừa khiến flag
  bật mà vẫn chạy Vibe, migration đứng im mà không ai biết.
- Tạo đủ 5 file cho có, kể cả file adapter rỗng cho component luôn fallback về Vibe — dead code,
  người sau tưởng là thiếu sót rồi đi "sửa".
- Viết giá trị px/hex/border-radius cứng "cho nhanh" rồi định tối ưu sau — thường không quay lại
  tối ưu, và reviewer phải bắt lại đúng thứ nguyên tắc đã ghi sẵn trong skill.
- Hỗ trợ một prop (kể cả legacy/deprecated) chỉ vì nó nằm trong type Vibes, chưa grep xem có ai
  dùng thật không — dead code trông như tính năng đầy đủ.
- Viết comment nhiều dòng cho một dòng logic đơn giản — comment nên giải thích lý do (why) ngắn
  gọn, không diễn giải lại code hay viết thành đoạn văn.

## Red Flags

🚩 Đang sửa file view/page để đổi sang wrapper mới — sai phạm vi, skill này chỉ tạo adapter.
🚩 Đang làm nhiều component trong cùng một lượt — quay lại Bước "Phạm vi", làm lần lượt.
🚩 Adapter có `useState`/`useEffect`/`useGetComponentActive` — logic đó thuộc wrapper.
🚩 Export `canRenderKinako<X>` nhưng wrapper không gọi — component sẽ render sai khi flag bật thay
vì fallback an toàn.
🚩 Adapter không có comment lý giải khi default Vibes và Kinako khác nhau — dấu hiệu đang đoán.
🚩 Viết assert class Kinako mà chưa xem component đó render ra DOM nào.
🚩 Sắp gõ một số px, mã hex, hay `'9999px'`/`'50%'` vào style — dừng lại, grep `kinako-ui.css` tìm
token trước. Biết nguyên tắc "ưu tiên token" mà không tra là cách sai lầm này đã lọt qua thật.
🚩 Đang viết `pickMarginPropsWithLegacy` hay bất kỳ nhánh hỗ trợ legacy prop nào mà chưa grep call
site thật — hỏi "có ai dùng cái này không?" trước khi hỏi "làm sao hỗ trợ nó?".
🚩 Comment trong adapter dài hơn 2-3 dòng cho một biểu thức đơn giản — cân nhắc rút gọn còn 1 dòng
hoặc để code tự nói, trước khi review chỉ ra điều đó.
