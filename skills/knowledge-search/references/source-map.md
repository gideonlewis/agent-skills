# Knowledge Source Map

## Agora

- Knowledge dài hạn → `ai-platform/ai-platform-agora`
- Project ID: `1499`
- URL: `https://git.teqnological.asia/ai-platform/ai-platform-agora`

### Canonical Route

- Vision tổng thể → đọc trực tiếp `docs/vision/world-model-vision.md`; trả lời,
  dừng. Không search hoặc đọc source khác.
- Member/core members/maintainers → `MAINTAINERS.md`.
- ADR/decision → `docs/decisions/`
- Architecture/design → `docs/design-docs/`
- Blog/setup guide → `docs/blog_posts/`
- Presentation artifact → `docs/presentation/`

Canonical source lỗi → báo file/project cụ thể, dừng. Không fallback sang
keyword search.

### Agora Search Strategy

- Chọn folder canonical từ `Folder Tree` trước khi search.
- Nếu folder có `INDEX.md`, đọc `INDEX.md` trước để chọn file/folder kế tiếp.
- Nếu chưa có `INDEX.md`, list file/folder trong scope đó trước.
- Ưu tiên match theo path/filename; search content/blobs chỉ trong scope hẹp.
- Fallback sang source khác/web chỉ khi folder/index/scoped search không đủ.

### Folder Tree

```text
.
├── docs
│   ├── blog_posts
│   │   └── assets
│   ├── decisions
│   ├── design-docs
│   │   ├── agent-platform
│   │   │   ├── ai-enterprise-strategy
│   │   │   ├── emerging-technology
│   │   │   ├── evaluation
│   │   │   └── skills
│   │   ├── ai-gateway
│   │   │   └── bifrost
│   │   │       └── rbac
│   │   │           └── 00-features
│   │   │               ├── 01-teams
│   │   │               ├── 02-users
│   │   │               └── 03-my-gateway
│   │   ├── data-platform
│   │   │   ├── cli
│   │   │   ├── emerging-technology
│   │   │   ├── mcp
│   │   │   │   ├── INDEX.md
│   │   │   │   ├── mcp-apps
│   │   │   │   ├── mcp-auth
│   │   │   │   │   ├── internal-hub-mcp
│   │   │   │   │   └── raw
│   │   │   └── vector-database
│   │   │       └── qdrant
│   │   ├── image
│   │   ├── infras
│   ├── presentation
│   └── vision
│       └── image
└── meeting-notes
```

## Google Drive

- Dùng khi có Drive link, user chỉ rõ Drive, hoặc Agora dẫn sang Drive.
- Không search song song với Agora.

## Mattermost

- Dùng cho thread/post, trao đổi, quyết định hoặc context gần đây.
- Chat mâu thuẫn tài liệu → nêu cả hai source và thời điểm.

## Backlog

- Chỉ dùng để tìm link artifact.
- Đọc artifact gốc; không giải thích knowledge từ ticket.
- Project members → chỉ dùng cho assignment/execution, không phải team source of truth.

## Google Calendar

- Chỉ dùng cho meeting context và thời điểm.
- Chỉ kết luận từ meeting note, attachment hoặc linked source.
