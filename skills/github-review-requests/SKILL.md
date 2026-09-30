---
name: github-review-requests
description: >
  Liệt kê pull request GitHub open ở các repo Finatext đang theo dõi (mặc định
  azuki, azuki-app, cred-proto; chỉ định được 1 repo duy nhất) thành một bảng
  Markdown cố định dán thẳng vào Mattermost, với đối tượng chọn được: PR của
  cả DEV team spc-collab, PR đang request review tới tôi, cả hai gộp lại, hoặc
  PR của một thành viên cụ thể (PR người đó được request review + PR người đó
  tạo). Bỏ qua PR draft. Mỗi PR có repo, người gửi, trạng thái (Awaiting review
  kèm reviewer đang chờ, Changes requested, Approved, tồn đọng) và thời điểm
  cập nhật. Dùng khi user hỏi "PR nào đang chờ tôi review", "danh sách PR
  assign tôi", "PR của team", "danh sách PR cần xem", "PR của
  Vĩ/Tiên/Định/Dũng", "PR bên cred-proto", "PR tồn đọng", "review queue", "team
  còn PR nào chưa merge", "report PR lên Mattermost", hoặc đầu ngày muốn nắm
  việc review. Không dùng để review nội dung một PR cụ thể (xem
  `azuki-review-console-rpc-to-core-proto` hoặc `review`), không dùng cho merge
  request GitLab (xem `ai-platform-gitlab`).
version: 0.6.0
author: TEQ AI Platform
license: Internal
metadata:
  hermes:
    tags: [github, pull-request, review, spc-collab, mattermost, report]
---

# GitHub Review Requests

Tổng hợp tình trạng PR trên GitHub thành **một bảng Markdown cố định** để dán
vào Mattermost. Chỉ đọc dữ liệu (`gh api graphql`), không approve, comment hay
merge gì cả.

Mọi trường hợp đều ra cùng một bảng, cùng 5 cột, không tiêu đề, không chia
nhóm — người đọc quen một format duy nhất, và report không dài ra theo số
nhóm. Phần dựng bảng nằm trong script `references/pr-table.sh` để output luôn
giống nhau giữa các lần chạy; agent chỉ chọn filter.

## Khi Nào Dùng

- Muốn biết PR nào đang chờ mình (hoặc một thành viên) review.
- Leader muốn nắm PR của team: cái nào chưa ai review, cái nào bị yêu cầu sửa,
  cái nào đã approve mà chưa merge, cái nào nằm im lâu.
- Cần một bảng gọn để dán vào Mattermost (daily/standup).

Review nội dung PR thì dùng skill review tương ứng; GitLab MR thì dùng
`ai-platform-gitlab`.

## Cấu Hình

| Mục | Giá trị |
|---|---|
| Tôi | `teq-quanhuynh` — tài khoản `gh` đang đăng nhập (`@me`) |
| Repo theo dõi | `azuki azuki-app cred-proto` (org Finatext) |
| Ngưỡng tồn đọng | 14 ngày không có cập nhật |
| PR draft | Bỏ qua (`draft:false`) |

Repo theo dõi là giá trị mặc định của biến `REPOS` trong
`references/pr-table.sh`. Muốn thêm/bớt repo lâu dài, sửa cả dòng trên và
default trong script. Repo ngoài danh sách (rakugan-cms-server,
zarame-server...) bị bỏ qua vì không thuộc phạm vi report hằng ngày.

### DEV team

| Tên gọi | GitHub login |
|---|---|
| Quân (tôi) | `teq-quanhuynh` |
| Vĩ (vitran) | `vitranteq` |
| Tiên (tienbui) | `teq-tienbui` |
| Định (dinhnguyen) | `teq-dinhnguyen` |
| Dũng (dungnguyen) | `teq-nguyenhuudung` |

DEV của spc-collab (xem `spc-collab-calendar`) trừ Giao và Nam theo yêu cầu
của leader. `dungnguyen@teqnological.asia` là `teq-nguyenhuudung`, không phải
`dungnguyen-teq`. Khi team thay đổi, chỉ sửa bảng này.

## Chọn Đối Tượng

Mỗi yêu cầu được dịch thành một hoặc nhiều **filter** GitHub search. Có 2 loại:

- **Được request review** của login `L`: `user-review-requested:L`. Chỉ tính
  request trực tiếp tới người đó, không tính request qua team
  (`d-cred-reviewer`...) — request qua team rất nhiều và không phải việc riêng
  của ai.
- **Đã tạo** bởi tập login: `author:L1 author:L2 ...` (nhiều `author:` là OR).

| # | User nói (ví dụ) | Filter |
|---|---|---|
| 1 | "PR của team", "team còn PR nào" | `author:` cả 5 người DEV team |
| 2 | "PR assign tôi", "PR chờ tôi review" | `user-review-requested:teq-quanhuynh` |
| 3 | "PR cần xem", "PR tôi cần quan tâm", hoặc gọi skill không nói gì | Filter 2 + filter 1 |
| 4 | "PR của Vĩ", "danh sách PR vitran" | `user-review-requested:vitranteq` + `author:vitranteq` |

Mở rộng tự nhiên, không cần hỏi lại:

- Nhiều người ("PR của Vĩ và Tiên") → gộp filter mục 4 của từng người vào
  cùng một lần chạy, vẫn ra một bảng.
- Chỉ một vế ("PR Vĩ tạo") → chỉ filter tương ứng.
- Chỉ định 1 repo ("PR team bên cred-proto") → `REPOS=cred-proto`. Repo ngoài
  danh sách theo dõi vẫn dùng được cho riêng yêu cầu đó (`REPOS=zarame-server`).
  Tên mơ hồ ("app", "proto") thì map sang repo theo dõi nếu chỉ khớp một, còn
  không thì hỏi lại.
- "PR tồn đọng" → chạy filter như bình thường rồi chỉ giữ header và các dòng
  có `💤`.
- User hỏi thẳng về draft → thêm `INCLUDE_DRAFT=1`.

Tên không có trong bảng DEV team: nếu user đưa thẳng GitHub login thì dùng
luôn; nếu chỉ đưa tên, tra team `Finatext/c-teq-cred`
(`gh api orgs/Finatext/teams/c-teq-cred/members --jq '.[].login'`) và hỏi lại
khi có nhiều hơn một ứng viên — đoán sai login thì bảng rỗng hoặc ra PR của
người khác mà trông vẫn hợp lệ.

## Quy Trình

### Bước 1 — Kiểm tra `gh`

```bash
gh auth status
```

Chưa đăng nhập thì dừng, nhờ user tự chạy `gh auth login` (không tự nhập
token).

### Bước 2 — Chạy script

Truyền mỗi filter là một argument; script gộp kết quả, bỏ PR trùng (ví dụ PR
của Định request tôi review xuất hiện ở cả 2 filter), rồi in bảng.

```bash
~/.claude/skills/github-review-requests/references/pr-table.sh \
  "user-review-requested:teq-quanhuynh" \
  "author:teq-quanhuynh author:vitranteq author:teq-tienbui author:teq-dinhnguyen author:teq-nguyenhuudung"
```

```bash
REPOS=cred-proto ~/.claude/skills/github-review-requests/references/pr-table.sh "user-review-requested:vitranteq" "author:vitranteq"
```

Script in `WARN` ra stderr nếu một filter có hơn 100 PR (bị cắt) — khi đó báo
user và đề nghị chỉ định 1 repo.

### Bước 3 — Trả bảng

Trả nguyên output của script, không thêm tiêu đề, không chia nhóm, không đổi
cột. Format cố định:

```markdown
| Repo | PR | Người gửi | Trạng thái | Cập nhật |
|---|---|---|---|---|
| cred-proto | [#2359 [CRES-20678] Add GetGuaranteeExecutions to Core API](url) | teq-dinhnguyen | ⏳ Awaiting review: teq-quanhuynh, d-cred-reviewer | 09-29 17:54 |
| cred-proto | [#2358 [CRES-20678] Add GetGuaranteeAssessmentResultDecisions…](url) | teq-dinhnguyen | ✅ Approved | 09-29 17:50 |
| azuki | [#14468 [CRES-20550] JPKI: Send borrower info on ekyc submitted](url) | teq-nguyenhuudung | 💤 ✅ Approved | 09-15 09:11 |
```

Quy ước của cột **Trạng thái** (script tự tính):

| Giá trị | Khi nào |
|---|---|
| `⏳ Awaiting review: <reviewer đang chờ>` | Chưa đủ approve |
| `🔁 Changes requested: <người yêu cầu>` | Có reviewer yêu cầu sửa |
| `✅ Approved` | Đủ approve, chưa merge — không ghi tên người approve vì không cần cho việc tiếp theo (merge) |
| tiền tố `💤` | Không cập nhật quá 14 ngày |

Thứ tự dòng: Awaiting → Changes requested → Approved → các PR `💤`; trong mỗi
nhóm, mới cập nhật trước. `Cập nhật` là giờ máy local (`MM-DD HH:MM`, +07).
Login không kèm `@` để khỏi ping nhầm trên Mattermost. Bot (Copilot,
github-actions) không được tính là reviewer.

Bảng rỗng thì script in "Không có PR nào." — trả đúng dòng đó.

### Bước 4 — Gửi Mattermost (chỉ khi user yêu cầu)

Mặc định chỉ trả bảng trong chat để user tự dán. Nếu user bảo gửi, hỏi
kênh/thread cụ thể và cho xem nội dung cuối trước, chỉ gọi
`mattermost-create_post` sau khi user xác nhận — post lên kênh là hành động
công khai, khó rút lại.

## Anti-patterns

- Thêm tiêu đề, chia nhóm, hay thêm/bớt cột theo từng trường hợp — phá tính
  đồng nhất của report. Muốn đổi format thì sửa `pr-rows.jq`/`pr-table.sh`, áp
  dụng cho mọi trường hợp.
- Tự format bảng bằng tay thay vì chạy script.
- Dùng `review-requested:L` thay vì `user-review-requested:L` — kéo theo mọi
  PR request qua team.
- Đoán GitHub login từ tên gọi khi không có trong bảng DEV team.
- Gọi `gh pr view` từng PR — chậm và tốn rate limit.
- Tự post lên Mattermost khi user chỉ nói "report".

## Red Flags

🚩 Bảng có PR ngoài repo đã chọn hoặc của người ngoài tập login đã chọn —
filter sai.
🚩 Bảng có `📝 Draft` khi user không hỏi về draft — lỡ bật `INCLUDE_DRAFT`.
🚩 Script in `WARN` về 100 PR — bảng bị thiếu, phải báo user.
🚩 `gh` trả lỗi `SAML`/`403` — token chưa authorize SSO cho org Finatext, nhờ
user tự authorize, không thử token khác.
