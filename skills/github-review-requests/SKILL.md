---
name: github-review-requests
description: >
  Liệt kê pull request GitHub open ở các repo Finatext đang theo dõi (mặc định
  azuki, azuki-app, cred-proto; chỉ định được 1 repo duy nhất) rồi xuất bảng
  Markdown dán thẳng vào Mattermost, với đối tượng chọn được: PR của cả DEV team
  spc-collab, PR đang request review tới tôi, cả hai gộp lại, hoặc PR của một
  thành viên cụ thể (PR người đó được request review + PR người đó tạo). Bỏ
  qua PR draft. Mỗi PR có người gửi, trạng thái (chờ review, cần sửa, approved
  chờ merge, tồn đọng), reviewer đang chờ và CI. Dùng khi user hỏi "PR nào đang chờ tôi
  review", "danh sách PR assign tôi", "PR của team", "danh sách PR cần xem",
  "PR của Vĩ/Tiến/Định/Dũng", "PR bên cred-proto", "review queue", "team còn PR nào chưa merge",
  "report PR lên Mattermost", hoặc đầu ngày muốn nắm việc review. Không dùng
  để review nội dung một PR cụ thể (xem `azuki-review-console-rpc-to-core-proto`
  hoặc `review`), không dùng cho merge request GitLab (xem `ai-platform-gitlab`).
version: 0.4.0
author: TEQ AI Platform
license: Internal
metadata:
  hermes:
    tags: [github, pull-request, review, spc-collab, mattermost, report]
---

# GitHub Review Requests

Tổng hợp nhanh tình trạng PR trên GitHub để báo cáo lên Mattermost. Chỉ đọc
dữ liệu (`gh api graphql`), không approve, comment hay merge gì cả.

PR draft bị loại ngay từ query: draft là việc tác giả chưa làm xong, chưa cần
ai review hay theo dõi, đưa vào chỉ làm report dài và loãng. Chỉ lấy draft khi
user hỏi thẳng (ví dụ "có draft nào của Định không") — lúc đó bỏ `draft:false`
khỏi query cho riêng yêu cầu đó.

## Khi Nào Dùng

- Muốn biết PR nào đang chờ mình (hoặc một thành viên) review.
- Leader muốn nắm PR của team: cái nào chưa ai review, cái nào bị yêu cầu sửa,
  cái nào đã approve mà chưa merge, cái nào nằm im lâu.
- Cần một đoạn Markdown gọn để dán vào Mattermost (daily/standup).

Review nội dung PR thì dùng skill review tương ứng; GitLab MR thì dùng
`ai-platform-gitlab`.

## Cấu Hình

| Mục | Giá trị |
|---|---|
| Tôi | `teq-quanhuynh` — tài khoản `gh` đang đăng nhập (`@me`) |
| Ngưỡng tồn đọng | 14 ngày không có cập nhật |
| PR draft | Bỏ qua hoàn toàn (`draft:false` trong query) |

### Repo theo dõi

| Repo | Qualifier |
|---|---|
| azuki | `repo:Finatext/azuki` |
| azuki-app | `repo:Finatext/azuki-app` |
| cred-proto | `repo:Finatext/cred-proto` |

Mọi query đều gắn đủ các qualifier trên (nhiều `repo:` là phép OR), gọi là
`<REPOS>` ở Bước 2. Muốn theo dõi thêm hoặc bớt repo, chỉ sửa bảng này. Repo
ngoài bảng (rakugan-cms-server, zarame-server...) bị bỏ qua vì không thuộc
phạm vi report hằng ngày.

### DEV team

| Tên gọi | GitHub login |
|---|---|
| Quân (tôi) | `teq-quanhuynh` |
| Vĩ (vitran) | `vitranteq` |
| Tiến (tienbui) | `teq-tienbui` |
| Định (dinhnguyen) | `teq-dinhnguyen` |
| Dũng (dungnguyen) | `teq-nguyenhuudung` |

DEV của spc-collab (xem `spc-collab-calendar`) trừ Giao và Nam theo yêu cầu
của leader. `dungnguyen@teqnological.asia` là `teq-nguyenhuudung`, không phải
`dungnguyen-teq`. Khi team thay đổi, chỉ sửa bảng này — đây là nguồn duy nhất.

## Chế Độ (Chọn Đối Tượng)

Report gồm một hoặc nhiều **section**, mỗi section là một query. Có 2 loại
section:

- **Được request review** của login `L`: `user-review-requested:L`. Chỉ tính
  request trực tiếp tới người đó, không tính request qua team
  (`@d-cred-reviewer`...) — request qua team rất nhiều và không phải việc riêng
  của ai.
- **Đã tạo** bởi tập login `S`: `author:L1 author:L2 ...` (nhiều `author:` là
  phép OR). Section này nhóm theo trạng thái (xem Bước 3).

Map yêu cầu của user sang section như sau:

| # | User nói (ví dụ) | Section |
|---|---|---|
| 1 | "PR của team", "team còn PR nào" | Đã tạo bởi cả 5 người DEV team |
| 2 | "PR assign tôi", "PR chờ tôi review" | Được request review của `teq-quanhuynh` |
| 3 | "PR cần xem", "tổng hợp PR", hoặc chỉ gọi skill không nói gì | Mục 2 + mục 1 |
| 4 | "PR của Vĩ", "danh sách PR vitran" | Được request review của người đó + Đã tạo bởi người đó |

Mở rộng tự nhiên từ bảng trên, không cần hỏi lại:

- Nhiều người ("PR của Vĩ và Tiến") → áp dụng mục 4 cho từng người, mỗi người
  một khối riêng.
- Chỉ một vế ("PR Vĩ tạo", "Vĩ đang được request review gì") → chỉ section
  tương ứng.
- Chỉ định 1 repo ("PR team bên cred-proto", "PR chờ tôi review ở azuki") →
  `<REPOS>` chỉ còn đúng qualifier của repo đó, cho mọi section. Tiêu đề report
  ghi rõ tên repo, ví dụ `### 👥 PR open của team — cred-proto (12)`.
- User nêu repo ngoài bảng theo dõi (ví dụ "PR bên zarame-server") → dùng
  `repo:Finatext/<tên>` cho riêng yêu cầu đó, không cần sửa bảng. Tên repo mơ
  hồ ("app", "proto") thì map sang repo trong bảng nếu chỉ khớp một, còn không
  thì hỏi lại.

Tên không có trong bảng DEV team: nếu user đưa thẳng GitHub login thì dùng
luôn; nếu chỉ đưa tên, tra team `Finatext/c-teq-cred`
(`gh api orgs/Finatext/teams/c-teq-cred/members --jq '.[].login'`) và hỏi lại
user khi có nhiều hơn một ứng viên — đoán sai login thì report rỗng hoặc ra PR
của người khác mà trông vẫn hợp lệ.

## Quy Trình

### Bước 1 — Kiểm tra `gh`

```bash
gh auth status
```

Chưa đăng nhập thì dừng, nhờ user tự chạy `gh auth login` (không tự nhập
token).

### Bước 2 — Lấy dữ liệu

Chạy mỗi section một lệnh (các section chạy song song được). Thay `<REPOS>`
theo mục "Repo theo dõi" (hoặc 1 repo user chỉ định) và `<FILTER>` theo
section:

```bash
SKILL_DIR=~/.claude/skills/github-review-requests
gh api graphql -F query=@$SKILL_DIR/references/pr-search.graphql \
  -F q='is:pr is:open draft:false archived:false <REPOS> <FILTER> sort:updated-desc' \
  | jq -r --arg now "$(date -u +%s)" --argjson stale_days 14 -f $SKILL_DIR/references/pr-rows.jq
```

`<REPOS>` mặc định: `repo:Finatext/azuki repo:Finatext/azuki-app repo:Finatext/cred-proto`.

Ví dụ `<FILTER>`:

- Mục 1: `author:teq-quanhuynh author:vitranteq author:teq-tienbui author:teq-dinhnguyen author:teq-nguyenhuudung`
- Mục 2: `user-review-requested:teq-quanhuynh`
- Mục 4 (Vĩ): `user-review-requested:vitranteq` và `author:vitranteq` (2 lệnh)

Query GraphQL ở `references/pr-search.graphql`, bộ chuyển sang TSV ở
`references/pr-rows.jq` (cột: repo, number, url, title, author, status, ci,
pending_reviewers, approvers, changes_requested_by, updated, stale).

Ghi chú:

- Query lấy tối đa 100 PR. Nếu `issueCount` > 100 thì báo user và đề nghị thu
  hẹp (ví dụ chỉ định 1 repo).
- Bot (`copilot-pull-request-reviewer`, `github-actions`, `*[bot]`) đã được
  loại khỏi danh sách review trong jq; `COMMENTED`/`DISMISSED` không tính là
  approve.

### Bước 3 — Phân loại

Cột `status` đã được tính theo thứ tự ưu tiên: `CHANGES_REQUESTED` →
`APPROVED` → `REVIEW_REQUIRED`. (`pr-rows.jq` vẫn trả `DRAFT` nếu query có
draft — chỉ xảy ra khi user hỏi thẳng về draft.)

- **Section "Được request review"**: một bảng, sắp theo `updated` mới nhất.
- **Section "Đã tạo"**: nhóm theo `status`. PR có `stale = true` gom riêng vào
  nhóm **Tồn đọng** thay vì trộn vào nhóm chính — PR nằm im lâu thường là PR
  bị bỏ quên, cần thấy riêng để quyết định đóng hay đẩy tiếp.
- Một PR xuất hiện ở cả 2 section (ví dụ PR của Định request tôi review) vẫn
  giữ ở cả hai, vì mỗi section trả lời một câu hỏi khác nhau.

CI: `SUCCESS` → ✅, `FAILURE`/`ERROR` → ❌, `PENDING`/`EXPECTED` → ⏳,
`NONE` → `-`.

### Bước 4 — Xuất Markdown

Xuất trong chat, đúng format dưới (Mattermost render được bảng và link).
Title dài quá ~60 ký tự thì cắt và thêm `…`. Tên người dùng login GitHub, không
thêm `@` để khỏi ping nhầm trên Mattermost. Nhóm hoặc section nào rỗng thì
ghi một dòng "Không có PR nào" cho section, bỏ hẳn nhóm con rỗng.

Tiêu đề section theo đối tượng: `🔍 PR chờ tôi review`, `🔍 PR chờ vitranteq
review`, `👥 PR open của team`, `👤 PR vitranteq tạo`. Khi report nhiều người
(mục 4), mỗi người là một khối `## <Tên> (<login>)` chứa 2 section của người
đó.

```markdown
### 🔍 PR chờ tôi review — 29/09 (2)

| Repo | PR | Người gửi | Trạng thái | CI | Cập nhật |
|---|---|---|---|---|---|
| cred-proto | [#2357 [CRES-20678] Add SubmitBorrower…](url) | teq-nguyenhuudung | ⏳ Chờ review | ✅ | 09-29 |
| azuki | [#14457 [CRES-20550] JPKI: Add liquid…](url) | teq-nguyenhuudung | ⏳ Chờ review | ✅ | 09-29 |

### 👥 PR open của team (24)

**⏳ Chờ review (12)**

| Repo | PR | Người gửi | Đang chờ | Đã approve | CI | Cập nhật |
|---|---|---|---|---|---|---|

**🔁 Cần sửa (n)** — cột `Yêu cầu sửa` thay cho `Đang chờ`

**✅ Approved, chờ merge (n)** — không có cột `Đang chờ`

**💤 Tồn đọng >14 ngày (n)** — một dòng mỗi PR:
- azuki [#14468](url) · teq-nguyenhuudung · Approved · 09-15
```

Section "Đã tạo" của một người (mục 4) dùng cùng format nhóm nhưng bỏ cột
`Người gửi` (luôn là người đó).

Cuối report thêm 1–3 dòng **Cần chú ý** nếu có, ví dụ: PR approved nhưng CI
❌, PR chờ review > 3 ngày, người có nhiều PR đang chờ nhất. Chỉ nêu điều thấy
trong dữ liệu, không suy đoán lý do.

### Bước 5 — Gửi Mattermost (chỉ khi user yêu cầu)

Mặc định chỉ xuất Markdown trong chat để user tự dán. Nếu user bảo gửi, hỏi
kênh/thread cụ thể và cho xem nội dung cuối trước, chỉ gọi
`mattermost-create_post` sau khi user xác nhận — post lên kênh là hành động
công khai, khó rút lại.

## Anti-patterns

- Quên `draft:false` trong query rồi lọc draft bằng tay — dễ sót, và số
  `issueCount` không còn khớp với số PR hiển thị.
- Dùng `review-requested:L` thay vì `user-review-requested:L` — kéo theo mọi
  PR request qua team, section bị loãng.
- Đoán GitHub login từ tên gọi khi không có trong bảng DEV team.
- Tính comment của Copilot/github-actions là "đã review".
- Gọi `gh pr view` từng PR — chậm và tốn rate limit; một query GraphQL mỗi
  section đã đủ.
- Tự thêm cột (diff size, ticket link...) khi user chưa yêu cầu — report cho
  Mattermost cần gọn; bổ sung khi được yêu cầu.
- Tự post lên Mattermost khi user chỉ nói "report".

## Red Flags

🚩 Report có PR ngoài các repo đã chọn hoặc của người ngoài tập login đã
chọn — query thiếu `<REPOS>` hoặc sai filter.
🚩 Report có PR draft khi user không hỏi về draft — query thiếu `draft:false`.
🚩 `issueCount` lớn hơn số dòng in ra — bị cắt ở 100, phải báo user.
🚩 `gh` trả lỗi `SAML`/`403` — token chưa authorize SSO cho org Finatext, nhờ
user tự authorize, không thử token khác.
