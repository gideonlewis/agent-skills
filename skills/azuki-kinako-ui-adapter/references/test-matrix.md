# Test matrix

Chọn mọi dòng liên quan tới component đang làm. Ưu tiên assert nhỏ và cụ thể hơn snapshot lớn:
snapshot sẽ pass lại sau khi bạn vô tình đổi hành vi, còn assert cụ thể thì không.

Chia hai tầng: test **adapter** không render (thuần hàm, nhanh), test **wrapper** chỉ kiểm tra
việc chọn nhánh và thứ tự ưu tiên.

| Khu vực | Bằng chứng cần có |
|---|---|
| Default | Bỏ trống prop vẫn ra đúng variant/size/layout của bản cũ |
| Ánh xạ trực tiếp | children, trạng thái disabled, event được giữ |
| Đổi tên | Mỗi prop đổi tên tới đúng prop Kinako |
| Prop legacy | Alias cũ được hỗ trợ vẫn giữ nguyên hành vi |
| Link mode | Đích đến, target, rel, download, callback điều hướng được giữ |
| Button mode | type, click, key, focus, blur được giữ; không rò prop của link |
| Prop không hỗ trợ | Output Kinako **không** chứa field legacy không hỗ trợ |
| Composition | Icon/direction/alignment/gap cố định khớp bản thay thế dự định |
| ARIA | Thuộc tính ARIA tương tác được giữ; accessible name vẫn đúng |
| Data attribute | Vibe dùng `data-test`, Kinako dùng `dataTest`; **giá trị caller ghi đè mặc định** |
| Margin | Margin hỗ trợ chuyển đúng; giá trị không hỗ trợ theo quy tắc đã ghi |
| Feature flag | Đúng tên component thì bật; khớp một phần thì không |
| Wrapper tắt | Vibe render với ngữ nghĩa nguyên bản |
| Wrapper bật | Kinako render với props đã chuyển đổi |
| Fallback | Mode Kinako không hỗ trợ vẫn tiếp tục render Vibe |
| Prop tương thích | Tới được Kinako, và **bị loại trước khi** render Vibe |

## Bốn case tối thiểu cho mọi wrapper

```tsx
import { useGetComponentActive } from '@/hooks/useAdapterFeatureFlags/useGetComponentActive'
import { configure, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'

vi.mock('@/hooks/useAdapterFeatureFlags/useGetComponentActive.ts', () => ({
  useGetComponentActive: vi.fn(),
}))
configure({ testIdAttribute: 'data-test' })

const mockUseGetComponentActive = vi.mocked(useGetComponentActive)

describe('shared <X> wrapper', () => {
  it('呼び出し元のdata-testを優先する', () => {
    mockUseGetComponentActive.mockReturnValue(true)
    render(<X data-test="caller-value" />)
    expect(screen.getByTestId('caller-value')).toBeInTheDocument()
  })

  it('Kinako有効時はKinako側で表示する', () => {
    mockUseGetComponentActive.mockReturnValue(true)
    render(<X data-test="kinako" />)
    expect(screen.getByTestId('kinako')).toHaveClass('kinako-<...>-root')
  })

  it('Kinako無効時はVibeで表示する', () => {
    mockUseGetComponentActive.mockReturnValue(false)
    render(<X data-test="vibe" />)
    expect(screen.getByTestId('vibe')).toHaveClass('vb-<...>')
  })

  // Chỉ khi có guard
  it('<điều kiện guard>の場合はKinako有効時でもVibeで表示する', () => {
    mockUseGetComponentActive.mockReturnValue(true)
    render(<X someUnsupportedMode data-test="fallback" />)
    expect(screen.getByTestId('fallback')).toHaveClass('vb-<...>')
  })
})
```

Test viết tiếng Nhật để khớp phần còn lại của repo.

## Ba cái bẫy

**Class và `data-test` có thể ở hai node khác nhau.** `Stack`/`Card` đặt cả hai trên cùng `<div>`,
nhưng `Icon` đặt `data-test` trên `<span>` ngoài còn `kinako-icon-root` xuống `<svg>` bên trong
qua `IconContext`. Đọc phần `return` của component Kinako trước khi viết assert:

```tsx
const svg = screen.getByTestId('kinako-icon').querySelector('svg')
expect(svg).toHaveClass('kinako-icon-root')
```

**`configure({ testIdAttribute: 'data-test' })`** cần thiết khi component không có `role` semantic
để query — repo dùng `data-test` chứ không phải `data-testid` mặc định của testing-library.

**Tìm class Vibe từ bundle, đừng đoán:**

```bash
grep -o 'vb-[a-zA-Z]*' node_modules/@freee_jp/vibes/dist/lv1/icons/MaterialIcon.js | sort -u
```

Tên không phải lúc nào cũng theo tên component: `NoDataIllust` render ra `vb-swallow`.
