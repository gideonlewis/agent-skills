# Bảng Đầy Đủ Thuộc Tính agents/openai.yaml

Đọc file này khi cần khai báo icon, brand color, giới hạn runtime, hoặc
dependency (CLI/MCP) cho một skill — những thuộc tính hiếm khi cần tới nên
không để thẳng trong `SKILL.md`.

| Thuộc tính | Bắt buộc | Ý nghĩa |
|---|---|---|
| `interface.display_name` | ✅ | Tên hiển thị trên UI |
| `interface.short_description` | ✅ | Mô tả ngắn một dòng |
| `interface.default_prompt` | — | Prompt gợi ý sẵn khi người dùng chọn skill |
| `interface.icon_small` | — | Icon nhỏ, thường `.svg`, đường dẫn tương đối tới thư mục skill |
| `interface.icon_large` | — | Icon lớn, `.png` hoặc `.svg` |
| `interface.brand_color` | — | Màu thương hiệu dạng hex, ví dụ `#0F62FE` |
| `policy.allow_implicit_invocation` | — | `true` cho phép agent tự kích hoạt; mặc định `false` |
| `policy.products` | — | Giới hạn runtime được phép dùng skill, ví dụ `CODEX` |
| `dependencies.tools[].type` | — | `cli` cho lệnh shell, `mcp` cho MCP server |
| `dependencies.tools[].value` | — | Tên lệnh CLI hoặc tên MCP server |
| `dependencies.tools[].description` | — | Vì sao skill cần công cụ này |
| `dependencies.tools[].transport` | — | Chỉ dùng với `type: mcp`, ví dụ `streamable_http` |
| `dependencies.tools[].url` | — | Chỉ dùng với `type: mcp` |

## Ví dụ đầy đủ

```yaml
interface:
  display_name: "My Skill"
  short_description: "Mô tả ngắn"
  default_prompt: "Dùng $my-skill để ..."
  icon_small: "./assets/my-skill-small.svg"
  icon_large: "./assets/my-skill.png"
  brand_color: "#0F62FE"

policy:
  allow_implicit_invocation: false
  products:
    - CODEX

dependencies:
  tools:
    - type: "cli"
      value: "gh"
      description: "Mở PR sau khi tạo branch"
    - type: "mcp"
      value: "teq-ai-gateway"
      description: "MCP server nội bộ cho search/backlog/calendar"
      transport: "streamable_http"
      url: "https://example.internal/mcp"
```
