---
name: create-skill
description: >
  Hướng dẫn tạo skill mới, sửa hoặc chuẩn hóa skill hiện có trong repo
  agent-skills — cấu trúc thư mục bắt buộc (SKILL.md, agents/openai.yaml,
  references/), quy ước viết tiếng Việt, cách viết description để skill kích
  hoạt đúng lúc, và cách validate/cài đặt. Dùng skill này bất cứ khi nào người
  dùng muốn thêm skill mới, đổi tên hoặc tái cấu trúc skill đang có, hỏi vì sao
  `./validate-skills.sh` báo lỗi, hoặc chỉ nói "tạo cho tôi một skill" mà chưa
  nói rõ chi tiết — hãy chủ động hỏi thêm thay vì đoán.
---

# Create Skill

Skill để tạo skill khác — dùng khi làm việc bên trong repo `agent-skills` này.

## Khi Nào Dùng

- Thêm một skill mới vào `skills/`.
- Sửa, đổi tên, hoặc tái cấu trúc một skill đã có.
- `./validate-skills.sh` báo lỗi và cần biết cách sửa.
- Cần viết lại `description` cho một skill để nó kích hoạt đúng lúc hơn.

Không dùng cho skill sống ở nơi khác ngoài repo này (plugin marketplace,
Claude Desktop skill riêng...) — quy ước ở đây (tiếng Việt bắt buộc,
`agents/openai.yaml`, `references/`) là đặc thù của repo `agent-skills`, không
phải chuẩn chung của mọi hệ thống skill.

## Skill Là Gì

Một skill là tập hướng dẫn đóng gói cho một loại công việc lặp lại: quy trình
deploy, checklist review, workflow riêng của một hệ thống. Khi skill được kích
hoạt, nội dung `SKILL.md` được nạp vào lượt làm việc và thay thế cách tiếp cận
mặc định của agent.

Skill khác với "lời khuyên chung": phải lặp lại được, có bước cụ thể, và có
tiêu chí rõ để biết khi nào áp dụng. Nếu nội dung chỉ là "hãy cẩn thận với X",
đó chưa phải một skill.

## Cấu Trúc Bắt Buộc

Mỗi skill là một thư mục trong `skills/`, tên thư mục **phải trùng** field
`name` trong frontmatter:

```
skills/my-skill/
├── SKILL.md              # Bắt buộc — nội dung skill + frontmatter
├── agents/
│   └── openai.yaml       # Bắt buộc — cấu hình interface cho Codex runtime
└── references/
    └── README.md         # Bắt buộc — index; để TPD nếu chưa có reference
```

Ba thành phần trên là bắt buộc để `./validate-skills.sh` pass. Đây là biến thể
riêng của repo này: thay vì thư mục `scripts/`/`assets/` như một số hệ thống
skill khác, ở đây `agents/` chỉ chứa cấu hình interface cho Codex runtime.

### Vì sao tách `references/` ra khỏi `SKILL.md`

`SKILL.md` được nạp vào context **mỗi lần skill kích hoạt** — càng dài càng
tốn context và càng khó đọc. `references/` chỉ được đọc **khi cần**, theo chỉ
dẫn từ `SKILL.md`. Nguyên tắc: giữ `SKILL.md` là phần "quy trình cốt lõi" luôn
cần thiết; đẩy bảng tra cứu dài, snapshot metadata, hay chi tiết chỉ áp dụng
trong một số tình huống ra `references/`. Chỉ tách khi nội dung vượt khoảng
100 dòng hoặc chỉ cần đọc trong một số tình huống — nội dung ngắn nên giữ
thẳng trong `SKILL.md`.

## Ngôn Ngữ

Toàn bộ văn xuôi trong `SKILL.md` — kể cả field `description` — viết bằng
**tiếng Việt**. Chỉ giữ nguyên tiếng Anh cho:

- Keyword kỹ thuật: `merge request`, `pipeline`, `feature flag`, `frontmatter`.
- Tên riêng và tên sản phẩm: GitLab, Backlog, Mattermost, TEQ AI Gateway.
- Định danh trong code: tên file, tên field, tên tool, lệnh shell.
- Template bắt buộc theo quy định bên ngoài (ví dụ mục `参考リンク` tiếng Nhật
  trong PR template của Finatext).

## Quy Trình

### Bước 1 — Tạo khung thư mục

```bash
mkdir -p skills/my-skill/{agents,references}
```

### Bước 2 — Viết SKILL.md

```markdown
---
name: my-skill
description: >
  Mô tả skill làm gì và dùng khi nào. Đây là thông tin duy nhất agent thấy khi
  quyết định có kích hoạt skill hay không, nên phải nêu rõ tình huống kích hoạt
  chứ không chỉ nêu chức năng.
# Các field dưới đây tuỳ chọn:
# version: 0.1.0
# author: TEQ AI Platform
# license: Internal
# argument-hint: "<flag_name> CRES-XXXX"
# metadata:
#   hermes:
#     tags: [tag-mot, tag-hai]
---

# Tên Skill

## Khi Nào Dùng

Tình huống cụ thể skill này áp dụng, và tình huống nên dùng skill khác.

## Quy Trình

Các bước hoặc phase cụ thể, đánh số.

## Anti-patterns

Cách làm sai cần tránh.

## Red Flags

🚩 Dấu hiệu đang đi sai hướng.
```

#### Viết `description` cho đúng

`description` là thông tin **duy nhất** agent thấy khi quyết định có kích hoạt
skill hay không — toàn bộ "khi nào dùng" phải nằm ở đây, không phải chỉ trong
thân bài. Nêu **tình huống**, không chỉ nêu chức năng:

| | |
|---|---|
| ❌ | `Skill review code.` |
| ✅ | `Dùng skill này khi review MR/PR, diff, commit trên AI Platform GitLab trong group ai-platform, đặc biệt khi Mattermost thread yêu cầu findings và rủi ro blocker.` |

Xu hướng chung là agent **bỏ sót** việc dùng skill dù đáng ra nên dùng. Để hạn
chế, hãy viết description hơi "chủ động thúc" một chút — liệt kê cả những cách
người dùng có thể diễn đạt mà không gọi thẳng tên skill, thay vì chỉ mô tả
chức năng khô khan. Nếu có skill lân cận dễ nhầm, nói rõ ranh giới ngay trong
`description` — ví dụ `knowledge-search` ghi rõ "Không dùng cho tiến độ ticket,
trạng thái MR".

### Bước 3 — Viết agents/openai.yaml

Copy template rồi sửa 3 dòng đầu. YAML dùng ký tự `#` để comment (không phải
`//`); giữ nguyên các dòng comment để biết còn thuộc tính nào có thể bật.

```yaml
interface:
  display_name: "My Skill"        # Tên hiển thị trên UI
  short_description: "Mô tả ngắn" # Mô tả ngắn, một dòng
  default_prompt: "Dùng $my-skill để ..."  # Prompt gợi ý khi người dùng chọn skill
policy:
  allow_implicit_invocation: false  # true = cho phép agent tự kích hoạt khi thấy phù hợp
```

Bảng đầy đủ thuộc tính (icon, brand_color, dependencies.tools...) nằm ở
`references/openai-yaml-properties.md` — đọc khi cần khai báo dependency hoặc
icon, việc hiếm gặp nên không để thẳng trong `SKILL.md`.

> `allow_implicit_invocation` mặc định để `false` trong repo này. Bật lên
> `true` khi muốn agent tự kích hoạt skill dựa trên `description` mà không cần
> gọi tên.

### Bước 4 — Viết references/README.md

Khi chưa có reference nào, để placeholder TPD:

```markdown
# References — my-skill

TPD — chưa có reference nào cho skill `my-skill`.

Thư mục này chứa checklist, fixture, snapshot metadata, hoặc tài liệu tham
chiếu mà `SKILL.md` trỏ tới. Thêm file `.md` vào đây rồi tham chiếu từ
`SKILL.md` bằng đường dẫn tương đối, ví dụ `references/checklist.md`.
```

Khi đã có reference, đổi thành bảng index (`| File | Nội dung |`). Trong
`SKILL.md`, luôn tham chiếu bằng đường dẫn tương đối và nói rõ khi nào nên đọc
file đó — ví dụ "Đọc `references/checklist.md` trước khi mở PR", không chỉ
nhắc tên file suông.

### Bước 5 — Validate

```bash
./validate-skills.sh
```

Kiểm tra: `SKILL.md` có frontmatter parse được với `name`/`description`,
`name` khớp tên thư mục, `agents/openai.yaml` hợp lệ, và `references/` tồn
tại. Lỗi thường gặp nằm ở `references/troubleshooting.md`.

### Bước 6 — Cài đặt và kiểm tra

```bash
./sync.sh && ./status.sh
```

`sync.sh` tạo symlink từ `skills/<name>/` sang `~/.claude/skills/<name>`. Nếu
máy đã chọn cài một tập skill tùy chỉnh qua `./install.sh <tên> ...`, `sync.sh`
sẽ chỉ đồng bộ đúng tập đó — chạy `./install.sh <tên-skill-mới>` hoặc
`./install.sh --all` nếu muốn thêm skill mới vào tập đang cài.

### Bước 7 — Commit

```bash
git add skills/my-skill/ && git commit -m "Add skill: my-skill"
```

## Quy Ước Đặt Tên

- Tên thư mục `kebab-case`, trùng field `name`.
- Đặt tên theo **hệ thống hoặc miền công việc**, không theo tên nội bộ mơ hồ:
  `nulab-backlog` rõ hơn `backlog`, `google-calendar` rõ hơn `calendar-skill`.
- Skill gắn với một repo cụ thể thì đưa tên repo vào:
  `azuki-feature-flag-implementation`.
- Tránh trùng tên với skill global đã có sẵn (kiểm tra danh sách skill hiện
  tại trước khi đặt tên) — trùng tên gây nhầm lẫn không biết bản nào đang được
  kích hoạt.

## Nguyên Tắc Viết

Giải thích **vì sao** thay vì ra lệnh khô khan. Nếu thấy mình đang viết LUÔN
LUÔN/KHÔNG BAO GIỜ viết hoa toàn bộ hoặc dựng cấu trúc quá cứng nhắc, đó là dấu
hiệu nên dừng lại và giải thích lý do đằng sau — agent đọc skill hiểu ngữ cảnh
tốt hơn nhiều khi biết *tại sao* một điều gì đó quan trọng, so với việc chỉ
được lệnh phải làm. Cách này cũng giúp skill tổng quát hơn, không bị bó cứng
vào một ví dụ cụ thể.

Một skill không nên khiến người đọc bất ngờ về mục đích thật sự của nó khi mô
tả lại nội dung skill cho họ nghe. Không tạo skill nhằm che giấu hành vi thật,
hỗ trợ truy cập trái phép, hay làm rò rỉ dữ liệu.

## Anti-patterns

- Lời khuyên mơ hồ kiểu "hãy cân nhắc kỹ..." — không có bước cụ thể để làm
  theo, không phải một skill thật sự.
- Lặp nội dung đã có ở skill khác thay vì tham chiếu — sửa một chỗ, quên chỗ
  còn lại, hai skill lệch nhau dần theo thời gian.
- Gộp nhiều workflow không liên quan vào một skill vì "tiện đặt chung" — làm
  `description` mơ hồ và khó biết khi nào nên kích hoạt.
- `description` chỉ nêu chức năng ("Skill quản lý ticket") mà không nêu tình
  huống kích hoạt cụ thể — agent sẽ khó biết khi nào nên dùng.
- Đặt toàn bộ nội dung "khi nào dùng" trong thân bài thay vì `description` —
  agent chỉ đọc thân bài **sau khi** đã quyết định kích hoạt, nên thông tin đó
  tới quá trễ để giúp quyết định.

## Red Flags

🚩 Không viết được mục "Khi Nào Dùng" cụ thể — dấu hiệu ý tưởng skill còn quá
mơ hồ, cần làm rõ với người dùng trước khi viết tiếp.
🚩 `SKILL.md` vượt 500 dòng mà chưa tách gì ra `references/`.
🚩 Tên thư mục và field `name` trong frontmatter lệch nhau — luôn xảy ra sau
khi đổi tên thư mục mà quên sửa frontmatter; `./validate-skills.sh` bắt được
lỗi này.
🚩 Đặt tên trùng với một skill global đã có sẵn.
