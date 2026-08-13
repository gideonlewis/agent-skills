# References — azuki-kinako-ui-adapter — Code mẫu từ 3 PR đã implement

Đọc file này khi cần code mẫu đầy đủ để copy cấu trúc, thay vì đoán lại từ mô tả trong
`SKILL.md`. 3 PR dưới đây đều nằm trong `Finatext/azuki-app`, xem trực tiếp bằng:

```bash
gh pr diff <so-PR> --repo Finatext/azuki-app
```

| PR | Ticket | Trạng thái | Nhóm minh hoạ | Component |
|---|---|---|---|---|
| [#2780](https://github.com/Finatext/azuki-app/pull/2780) | SPCC-3309 / CRES-19425 | **MERGED** | A, B, **D** | Button, IconOnlyButton, JumpButton, BackwardButton, ButtonGroup |
| [#2783](https://github.com/Finatext/azuki-app/pull/2783) | SPCC-3310 / CRES-19426 | open | A, B | Stack, HStack, VStack, WithSideContent, WithDescriptionContent |
| [#2786](https://github.com/Finatext/azuki-app/pull/2786) | SPCC-3311 / CRES-19428 | open | A, B | CardBase, ColumnBase, Container, ContentsBase, NegativeContentsBase |
| [#2788](https://github.com/Finatext/azuki-app/pull/2788) | SPCC-3312 / CRES-19432 | open | B, C | PageTitle, SectionTitle, SubSectionTitle, Paragraph, Text, HeadlineArea |

PR #2780 đã merge vào `master` nên là bản tham chiếu đáng tin nhất — nó đã qua review của team.
Các PR còn lại vẫn đang mở, dùng để tham khảo pattern chứ chưa phải bản chốt.

Nền tảng chung (`base.ts`, feature flag hook, `MarginBase` adapter) nằm ở branch
`feat/margin-base-adapter` — đây là điểm khởi đầu cho phần lớn công việc adapter hoá.

---

## 1. Feature flag hook — nền tảng bắt buộc

`src/hooks/useAdapterFeatureFlags/useGetComponentActive.ts`:

```ts
import type * as Vibes from '@freee_jp/vibes'
import { useSuspenseFeatureFlags } from '../useFeatureFlags'

export type VibesComponentsKey = keyof typeof Vibes

export const useGetComponentActive = (key: VibesComponentsKey): boolean => {
  const { kinakoEnabledComponents } = useSuspenseFeatureFlags()
  return (kinakoEnabledComponents as string).split(/[,\s]+/).includes(key)
}
```

Không cần đăng ký `key` ở đâu khác — `VibesComponentsKey` tự suy ra từ toàn bộ export của
`@freee_jp/vibes`, nên bất kỳ tên export Vibes nào cũng dùng được ngay làm key.

---

## 2. `base.ts` — bản đầy đủ sau PR #2786 (bao gồm legacy margin + padding helper)

```ts
import type { VibesComponentsKey } from '@/hooks/useAdapterFeatureFlags/useGetComponentActive'
import type {
  ButtonProps,
  DataAttributeProps as KinakoDataAttributeProps,
} from '@Finatext/kinako-ui'
import type { CommonProps } from '@freee_jp/vibes'
import { AriaAttributes } from 'react'

type KinakoMarginProps = Pick<ButtonProps, 'ma' | 'mt' | 'mb' | 'ml' | 'mr'>
type VibeMarginProps = Pick<CommonProps, 'ma' | 'mt' | 'mb' | 'ml' | 'mr'>
type VibeLegacyMarginProps = {
  marginTop?: boolean
  marginLeft?: boolean
  marginRight?: boolean
  marginBottom?: boolean
  marginSize?: 'xSmall' | 'small' | 'large' | 'xLarge' | 'xxLarge'
}

const toKinakoMarginValue = (
  value: VibeMarginProps['ma'],
): KinakoMarginProps['ma'] => (value === 'auto' ? undefined : value)

// Mirrors Vibe's own marginSizeToRem: legacy marginSize enum -> fixed rem value.
const marginSizeToRem = (
  marginSize: VibeLegacyMarginProps['marginSize'],
): NonNullable<VibeMarginProps['mt']> => {
  switch (marginSize) {
    case 'xSmall':
      return 0.25
    case 'small':
      return 0.5
    case 'large':
      return 1.5
    case 'xLarge':
      return 2
    case 'xxLarge':
      return 3
    default:
      return 1
  }
}

// Mirrors Vibe's own precedence: functional side value wins over legacy boolean + marginSize.
const resolveSideMargin = (
  functionalValue: VibeMarginProps['mt'],
  legacyEnabled: boolean | undefined,
  marginSize: VibeLegacyMarginProps['marginSize'],
): VibeMarginProps['mt'] =>
  functionalValue || (legacyEnabled ? marginSizeToRem(marginSize) : undefined)

const pickMarginProps = (props: VibeMarginProps): KinakoMarginProps => ({
  ma: toKinakoMarginValue(props.ma),
  mt: toKinakoMarginValue(props.mt),
  mb: toKinakoMarginValue(props.mb),
  ml: toKinakoMarginValue(props.ml),
  mr: toKinakoMarginValue(props.mr),
})

const pickMarginPropsWithLegacy = (
  props: VibeMarginProps & VibeLegacyMarginProps,
): KinakoMarginProps =>
  props.ma
    ? pickMarginProps({ ma: props.ma })
    : pickMarginProps({
        mt: resolveSideMargin(props.mt, props.marginTop, props.marginSize),
        mb: resolveSideMargin(props.mb, props.marginBottom, props.marginSize),
        ml: resolveSideMargin(props.ml, props.marginLeft, props.marginSize),
        mr: resolveSideMargin(props.mr, props.marginRight, props.marginSize),
      })

export type VibeDataAttributeProps = Pick<
  CommonProps,
  'data-test' | 'data-guide' | 'data-tracking' | 'data-masking'
>

const adaptDataAttributesToKinako = (
  props: VibeDataAttributeProps,
): KinakoDataAttributeProps => ({
  ...(props['data-test'] ? { dataTest: props['data-test'] } : {}),
  dataGuide: props['data-guide'],
  dataTracking: props['data-tracking'],
  dataMasking: props['data-masking'],
})

type DataTestAttributes = {
  'data-test': string
  dataTest: string
}
const dataTestAttributes = (
  componentName: VibesComponentsKey,
): DataTestAttributes => {
  return { 'data-test': componentName, dataTest: componentName }
}

type InteractiveAriaProps = Pick<
  AriaAttributes,
  | 'aria-atomic'
  | 'aria-controls'
  | 'aria-describedby'
  | 'aria-expanded'
  | 'aria-haspopup'
  | 'aria-owns'
  | 'aria-pressed'
>

const pickInteractiveAriaProps = (
  props: InteractiveAriaProps,
): InteractiveAriaProps => ({
  'aria-expanded': props['aria-expanded'],
  'aria-pressed': props['aria-pressed'],
  'aria-controls': props['aria-controls'],
  'aria-owns': props['aria-owns'],
  'aria-haspopup': props['aria-haspopup'],
  'aria-describedby': props['aria-describedby'],
  'aria-atomic': props['aria-atomic'],
})

const resolveKinakoPadding = (
  paddingSize?: 'small' | 'medium' | 'large' | 'zero',
  small?: boolean,
): number => {
  if (small || paddingSize === 'small') {
    return 1
  }
  if (paddingSize === 'large') {
    return 2
  }
  if (paddingSize === 'zero') {
    return 0
  }
  return 1.5
}

export {
  adaptDataAttributesToKinako,
  dataTestAttributes,
  pickInteractiveAriaProps,
  pickMarginProps,
  pickMarginPropsWithLegacy,
  resolveKinakoPadding,
}
export type { DataTestAttributes, VibeLegacyMarginProps, VibeMarginProps }
```

---

## 3. Nhóm A — Ánh xạ trực tiếp: `Stack`/`HStack`/`VStack` (PR #2783)

`src/components/shared/stack/stackAdapter.ts`:

```ts
import type {
  VibeDataAttributeProps,
  VibeMarginProps,
} from '@/components/shared/base'
import {
  adaptDataAttributesToKinako,
  pickMarginProps,
} from '@/components/shared/base'
import type { StackProps as KinakoStackProps } from '@Finatext/kinako-ui'
import type {
  HStack as VibeHStack,
  Stack as VibeStack,
  VStack as VibeVStack,
} from '@freee_jp/vibes'
import type { ComponentProps } from 'react'

export type VibeStackProps = ComponentProps<typeof VibeStack>
export type HStackProps = ComponentProps<typeof VibeHStack>
export type VStackProps = ComponentProps<typeof VibeVStack>

type StackDirection = NonNullable<VibeStackProps['direction']>

// Vibe defaults `alignItems` based on direction (`start` for vertical axes, `center` for horizontal
// ones); Kinako's Stack always defaults to `start`, so the effective default must be resolved explicitly.
const resolveAlignItems = (
  direction: StackDirection,
  alignItems?: VibeStackProps['alignItems'],
): KinakoStackProps['alignItems'] =>
  alignItems ??
  (direction === 'vertical' || direction === 'vertical-reverse'
    ? 'start'
    : 'center')

type StackBaseInput = {
  children?: VibeStackProps['children']
  justifyContent?: VibeStackProps['justifyContent']
  gap?: VibeStackProps['gap']
  inline?: boolean
  wrap?: VibeStackProps['wrap']
} & VibeMarginProps &
  VibeDataAttributeProps

const adaptStackBaseToKinako = (props: StackBaseInput) => ({
  children: props.children,
  justifyContent: props.justifyContent,
  gap: props.gap,
  inline: props.inline,
  wrap: !props.wrap || props.wrap === 'wrap',
  ...pickMarginProps(props),
  ...adaptDataAttributesToKinako(props),
})

export const adaptStackPropsToKinako = (
  props: VibeStackProps,
): KinakoStackProps => {
  const direction = props.direction ?? 'vertical'

  return {
    ...adaptStackBaseToKinako(props),
    direction,
    alignItems: resolveAlignItems(direction, props.alignItems),
  } as KinakoStackProps
}

export const adaptHStackPropsToKinako = (
  props: HStackProps,
): KinakoStackProps =>
  ({
    ...adaptStackBaseToKinako(props),
    direction: 'horizontal',
    alignItems: resolveAlignItems('horizontal', props.alignItems),
  }) as KinakoStackProps

export const adaptVStackPropsToKinako = (
  props: VStackProps,
): KinakoStackProps =>
  ({
    ...adaptStackBaseToKinako(props),
    direction: 'vertical',
    alignItems: resolveAlignItems('vertical', props.alignItems),
  }) as KinakoStackProps
```

`src/components/shared/stack/Stack.tsx` (wrapper — 3 component trong 1 file vì cùng chia sẻ
adapter base):

```tsx
import { useGetComponentActive } from '@/hooks/useAdapterFeatureFlags/useGetComponentActive'
import { Stack as KinakoStack } from '@Finatext/kinako-ui'
import {
  HStack as VibeHStack,
  Stack as VibeStack,
  VStack as VibeVStack,
} from '@freee_jp/vibes'
import { dataTestAttributes } from '../base'
import {
  adaptHStackPropsToKinako,
  adaptStackPropsToKinako,
  adaptVStackPropsToKinako,
  type HStackProps,
  type VStackProps,
  type VibeStackProps,
} from './stackAdapter'

export type StackProps = VibeStackProps
export type { HStackProps, VStackProps }

export const Stack = (props: StackProps) => {
  const isKinakoActive = useGetComponentActive('Stack')

  if (isKinakoActive) {
    return (
      <KinakoStack
        {...dataTestAttributes('Stack')}
        {...adaptStackPropsToKinako(props)}
      />
    )
  }

  return <VibeStack {...dataTestAttributes('Stack')} {...props} />
}

export const HStack = (props: HStackProps) => {
  const isKinakoActive = useGetComponentActive('HStack')

  if (isKinakoActive) {
    return (
      <KinakoStack
        {...dataTestAttributes('HStack')}
        {...adaptHStackPropsToKinako(props)}
      />
    )
  }

  return <VibeHStack {...dataTestAttributes('HStack')} {...props} />
}

export const VStack = (props: VStackProps) => {
  const isKinakoActive = useGetComponentActive('VStack')

  if (isKinakoActive) {
    return (
      <KinakoStack
        {...dataTestAttributes('VStack')}
        {...adaptVStackPropsToKinako(props)}
      />
    )
  }

  return <VibeVStack {...dataTestAttributes('VStack')} {...props} />
}
```

Test mẫu (`stackAdapter.test.ts`) — pattern chuẩn: một `describe` mỗi hàm adapt, cover default
resolution + pass-through + data-attr + margin:

```ts
import { describe, expect, it } from 'vitest'
import {
  adaptHStackPropsToKinako,
  adaptStackPropsToKinako,
  adaptVStackPropsToKinako,
} from './stackAdapter'

describe('adaptStackPropsToKinako', () => {
  it('direction未指定時はverticalとして扱いalignItemsをstartにする（Vibeのデフォルトに合わせる）', () => {
    const result = adaptStackPropsToKinako({})
    expect(result.direction).toBe('vertical')
    expect(result.alignItems).toBe('start')
  })

  it('directionがhorizontalの場合、alignItems未指定時はcenterにする（Vibeのデフォルトに合わせる）', () => {
    const result = adaptStackPropsToKinako({ direction: 'horizontal' })
    expect(result.alignItems).toBe('center')
  })

  it('data-*属性をKinakoのcamelCaseな属性名へ変換する', () => {
    const result = adaptStackPropsToKinako({
      'data-test': 'stack-test',
      'data-guide': 'guide-1',
    })
    expect(result.dataTest).toBe('stack-test')
    expect(result.dataGuide).toBe('guide-1')
  })

  it('Kinakoに対応しないwrapはfalseに変換する', () => {
    const result = adaptStackPropsToKinako({ wrap: 'nowrap' })
    expect(result.wrap).toBe(false)
  })
})
```

`Stack.test.tsx` — pattern chuẩn cho wrapper test (mock hook, assert class theo flag,
assert data-test override):

```tsx
import { useGetComponentActive } from '@/hooks/useAdapterFeatureFlags/useGetComponentActive'
import { render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { HStack, Stack, VStack } from './Stack'

vi.mock('@/hooks/useAdapterFeatureFlags/useGetComponentActive.ts', () => ({
  useGetComponentActive: vi.fn(),
}))

const mockUseGetComponentActive = vi.mocked(useGetComponentActive)

describe('shared stack wrappers', () => {
  it('呼び出し元のdata-testを優先する', () => {
    mockUseGetComponentActive.mockReturnValue(true)
    render(
      <Stack wrap="nowrap" data-test="stack-test">
        子要素
      </Stack>,
    )
    expect(screen.getByText('子要素')).toHaveAttribute('data-test', 'stack-test')
  })

  it('wrap="nowrap"かつKinako有効時はKinako側で表示する', () => {
    mockUseGetComponentActive.mockReturnValue(true)
    render(
      <Stack wrap="nowrap" data-test="stack-kinako">
        子要素
      </Stack>,
    )
    expect(screen.getByText('子要素')).toHaveClass('kinako-stack-root')
  })

  it('Kinako無効時はVibeで表示する', () => {
    mockUseGetComponentActive.mockReturnValue(false)
    render(
      <HStack wrap="nowrap" data-test="hstack-test">
        子要素
      </HStack>,
    )
    expect(screen.getByText('子要素')).toHaveClass('vb-stack')
  })
})
```

---

## 4. Nhóm B — Compose từ primitive Kinako: `WithSideContent`/`WithDescriptionContent` (PR #2783)

Kinako không có component tương đương — dựng lại bằng `Stack` với 2 `div` con giữ đúng
`flex-grow`/`flex-shrink` như Vibe gốc.

`src/components/shared/withSideContent/withSideContentAdapter.ts`:

```ts
import type { VibeDataAttributeProps } from '@/components/shared/base'
import { adaptDataAttributesToKinako } from '@/components/shared/base'
import type { StackProps as KinakoStackProps } from '@Finatext/kinako-ui'
import type { WithSideContent as VibeWithSideContent } from '@freee_jp/vibes'
import type { ComponentProps } from 'react'

export type WithSideContentProps = ComponentProps<typeof VibeWithSideContent>

// Vibe defaults to the browser's initial `align-items: stretch` when `verticalAlign` is unset.
const resolveAlignItems = (
  verticalAlign?: WithSideContentProps['verticalAlign'],
): KinakoStackProps['alignItems'] => {
  switch (verticalAlign) {
    case 'top':
      return 'start'
    case 'middle':
      return 'center'
    case 'bottom':
      return 'end'
    default:
      return 'stretch'
  }
}

// Kinako has no WithSideContent equivalent; compose it from Kinako's Stack laid out horizontally
// with the two children distributed to the edges. Vibe gives the main content `flex-grow: 1` and
// the side content `flex-shrink: 0`.
export const adaptWithSideContentPropsToKinako = (
  props: Pick<WithSideContentProps, 'verticalAlign'> & VibeDataAttributeProps,
): Omit<KinakoStackProps, 'children'> =>
  ({
    direction: 'horizontal',
    alignItems: resolveAlignItems(props.verticalAlign),
    gap: 0,
    ...adaptDataAttributesToKinako(props),
  }) as Omit<KinakoStackProps, 'children'>
```

`src/components/shared/withSideContent/WithSideContent.tsx` (children đặt tay vào từng
`div`/`Stack` con, KHÔNG spread `props.children` thẳng vào root):

```tsx
import { useGetComponentActive } from '@/hooks/useAdapterFeatureFlags/useGetComponentActive'
import { Stack as KinakoStack } from '@Finatext/kinako-ui'
import { WithSideContent as VibeWithSideContent } from '@freee_jp/vibes'
import { useId } from 'react'
import { dataTestAttributes } from '../base'
import {
  adaptWithSideContentPropsToKinako,
  type WithSideContentProps,
} from './withSideContentAdapter'

export type { WithSideContentProps }

export const WithSideContent = (props: WithSideContentProps) => {
  const isKinakoActive = useGetComponentActive('WithSideContent')
  const contentId = useId()
  if (isKinakoActive) {
    return (
      <KinakoStack
        {...dataTestAttributes('WithSideContent')}
        {...adaptWithSideContentPropsToKinako(props)}
      >
        <div css={{ flexGrow: 1 }} id={contentId}>
          {props.children}
        </div>
        <KinakoStack>{props.sideContent}</KinakoStack>
      </KinakoStack>
    )
  }

  return (
    <VibeWithSideContent
      {...dataTestAttributes('WithSideContent')}
      {...props}
    />
  )
}
```

`NegativeContentsBase` (PR #2786) là ví dụ compose phức tạp hơn — bọc thêm 1 `div` ngoài
`KinakoStack` để áp margin âm bằng CSS-in-JS (`css={{ marginLeft, marginRight, '&:last-child':
{ marginBottom } }}`), vì Kinako Stack không có prop margin âm trực tiếp:

```tsx
export const NegativeContentsBase = (props: NegativeContentsBaseProps) => {
  const isKinakoActive = useGetComponentActive('NegativeContentsBase')

  if (isKinakoActive) {
    const style = resolveNegativeContentsBaseStyle(props.contentsBasePaddingSize)

    return (
      <div
        css={{
          marginLeft: style.marginLeft,
          marginRight: style.marginRight,
          '&:last-child': { marginBottom: style.lastChildMarginBottom },
        }}
      >
        <KinakoStack
          {...dataTestAttributes('NegativeContentsBase')}
          {...adaptNegativeContentsBasePropsToKinako(props)}
        >
          {props.children}
        </KinakoStack>
      </div>
    )
  }

  return (
    <VibeNegativeContentsBase
      {...dataTestAttributes('NegativeContentsBase')}
      {...props}
    />
  )
}
```

---

## 5. Nhóm C — Ánh xạ giá trị + fallback guard: `Typography` / `MarginBase` (PR #2788, base)

`typographyAdapter.ts` — bảng tra cứu màu với `as const satisfies Partial<Record<...>>` để
TypeScript bắt lỗi khi thiếu case, và hàm resolve variant trả `undefined` khi size không map
được (caller phải tự quyết định fallback value, ví dụ `?? 'text'`):

```ts
const textColorMap = {
  black: 'foreground',
  burnt: 'gray',
  link: 'primary',
  alert: 'error',
  white: 'onPrimary',
  GY7: 'foreground',
  S9: 'gray',
  P7: 'primary',
  P5: 'primary',
  RE5: 'error',
} as const satisfies Partial<
  Record<
    NonNullable<TextProps['color']>,
    NonNullable<KinakoTypographyProps['color']>
  >
>

const resolveKinakoTextVariant = (
  size?: TextProps['size'],
): Extract<KinakoTypographyProps['variant'], 'label' | 'text'> | undefined => {
  switch (size) {
    case undefined:
    case 0.875:
      return 'text'
    case 0.75:
      return 'label'
    default:
      return undefined
  }
}

export const adaptTextPropsToKinako = (
  props: TextProps,
): KinakoTypographyProps => ({
  children: props.children,
  variant: resolveKinakoTextVariant(props.size) ?? 'text',
  bold: props.weight === 'bold',
  color: props.color ? textColorMap[props.color as keyof typeof textColorMap] : undefined,
  truncate: props.ellipsis,
  overflowWrap: props.overflowWrap,
  ...pickMarginProps(props),
  ...adaptDataAttributesToKinako(props),
})
```

`canRenderKinakoHeadlineArea` — guard cho props không hỗ trợ được, **được export nhưng KHÔNG
được gọi trong `HeadlineArea.tsx` của PR #2788** (thiếu sót cần tránh lặp lại, xem Red Flags
trong `SKILL.md`):

```ts
export const canRenderKinakoHeadlineArea = (
  props: HeadlineAreaProps,
): boolean =>
  !props.loading &&
  props.statusIconType === undefined &&
  props.statusIconText === undefined &&
  props.relatedMenus === undefined
```

Cách làm **đúng** — `MarginBase` (branch nền `feat/margin-base-adapter`) wire guard vào wrapper
đúng cách, dùng làm chuẩn tham chiếu khi component của bạn cần fallback guard:

`src/components/shared/marginBase/marginBaseAdapter.ts`:

```ts
// Vibe has no equivalent to `fitContent` (`max-width: fit-content`); when set, Kinako cannot
// represent the legacy-visible layout safely.
export const canRenderKinakoMarginBase = (
  props: Pick<MarginBaseProps, 'fitContent'>,
): boolean => !props.fitContent
```

`src/components/shared/marginBase/MarginBase.tsx`:

```tsx
export const MarginBase = (props: MarginBaseProps) => {
  const isKinakoActive = useGetComponentActive('MarginBase')

  if (isKinakoActive && canRenderKinakoMarginBase(props)) {
    return (
      <KinakoStack
        {...dataTestAttributes('MarginBase')}
        {...adaptMarginBasePropsToKinako(props)}
      />
    )
  }

  return <VibeMarginBase {...dataTestAttributes('MarginBase')} {...props} />
}
```

Lưu ý điều kiện `isKinakoActive && canRenderKinakoMarginBase(props)` — cả hai điều kiện đều cần
`true` mới render Kinako. Đây là pattern chuẩn cần copy khi component có guard.

---

## 6. Nhóm D — Enum đóng: prop tương thích `kinakoIcon` (PR #2780, đã merged)

Đây là tiền lệ duy nhất đã qua review cho tình huống Vibes nhận tập mở còn Kinako nhận enum cố
định. Xem đầy đủ: `git show origin/master:src/components/shared/button/buttonAdapter.ts`.

```ts
import type { IconProps, ButtonProps as KinakoButtonProps } from '@Finatext/kinako-ui'
import type { IconOnlyButton as VibeIconOnlyButton } from '@freee_jp/vibes'

// Kinako's icon set is a fixed enum, unlike Vibe's arbitrary IconComponent, so callers must supply
// the closest matching Kinako icon name explicitly via `kinakoIcon`.
export type IconOnlyButtonProps = ComponentProps<typeof VibeIconOnlyButton> & {
  kinakoIcon: IconProps['icon']
}
```

Ba chi tiết đáng chú ý trong PR này:

**1. Prop tương thích là phần mở rộng của type Vibes**, không thay thế nó — call site cũ vẫn
type-check được với mọi prop Vibes sẵn có, chỉ thêm đúng một field. Đây là mức xâm lấn nhỏ nhất
có thể.

**2. Prop không dùng được thì bị bỏ có chủ đích, và ghi rõ trong comment** thay vì im lặng:

```ts
// Vibe -> Kinako is the only supported direction; props with no Kinako equivalent
// (danger, legacy primary, IconComponent/iconPosition, large, hasMinWidth) are dropped.
export const adaptButtonPropsToKinako = (props: VibeButtonProps): KinakoButtonProps => {
```

**3. Phân nhánh theo mode thay vì đổ hết prop vào một object** — `href` quyết định component là
link hay button, và mỗi nhánh chỉ mang prop hợp lệ của nó. Nhờ vậy prop điều hướng không rò sang
nhánh button, đúng guardrail "không âm thầm biến link thành button":

```ts
const shared = {
  ...adaptButtonBaseToKinako(props),
  ...pickInteractiveAriaProps(props),
  width: width as KinakoButtonProps['width'],
}

if (href) {
  return { ...shared, to: href, target, rel, download, onSelfWindowNavigation } as KinakoButtonProps
}

return { ...shared, type, onClick, onKeyDown, onFocus, onBlur } as KinakoButtonProps
```

**4. Wrapper kết hợp nhóm D với nhóm C.** Đây là bản đã merged, chép nguyên văn từ
`git show origin/master:src/components/shared/button/Button.tsx`:

```tsx
const hasLinkProps = (props: IconOnlyButtonProps) => Boolean(props.href)

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
    <VibeIconOnlyButton
      {...dataTestAttributes('IconOnlyButton')}
      {...vibeProps}
    />
  )
}
```

Hai chi tiết dễ làm sai nếu tự nghĩ ra thay vì đọc code thật:

- **Destructuring nằm ngay trước lệnh return nhánh Vibes, không nằm ở signature.** Nếu tách ở
  signature thì nhánh Kinako lại phải ghép props về như cũ để truyền cho adapter — thừa và dễ
  sót. Tên được đổi thành `_kinakoIcon` để lint không báo biến không dùng.
- **Guard `hasLinkProps` đi kèm.** Kinako `IconButton` không render được link, nên khi có `href`
  thì rơi về Vibes dù flag đang bật. Nhóm D hiếm khi đứng một mình — một component nhận tập mở
  thường cũng có mode mà Kinako không biểu diễn nổi, nên hãy kiểm tra xem có cần guard nhóm C
  không trước khi coi là xong.

Xem `kinako-icon-enum.md` để biết enum `IconType` hiện có và cách quyết định prop nên bắt buộc
hay tuỳ chọn.

---

## 7. Test Container với `data-test` làm test id (khi component không forward `role` rõ ràng)

`Container.test.tsx` (PR #2786) — khi component Kinako không có `role` semantic rõ để query,
cấu hình `testing-library` dùng `data-test` làm test id thay vì thêm `data-testid` riêng:

```tsx
import { configure, render, screen } from '@testing-library/react'

configure({ testIdAttribute: 'data-test' })

it('Kinako有効時はmain配下にKinako Containerを描画する', () => {
  mockUseGetComponentActive.mockReturnValue(true)
  render(<Container>子要素</Container>)
  expect(screen.getByTestId('Container')).toHaveClass('kinako-container-root')
})
```
