---
name: spcc-core-api-migration-pr
description: >
  Tạo PR cho công việc migrate Console API → Core API: soạn title và description
  tiếng Anh từ migration report (bảng field từng RPC, field deprecated và entity phụ bị bỏ,
  validate bổ sung kèm kiểm chứng, RPC bị bỏ qua hoặc mở rộng, điểm cần JP
  confirm), chạy `gh pr create` với đúng base branch (master hoặc nhánh PR gốc
  khi là PR follow-up), gắn label semver, và cập nhật description của PR đã mở.
  Dùng khi đã có proto migrate trên branch đã push và cần "tạo PR", "mở PR",
  "viết PR description", "cập nhật description PR #...", kể cả PR handler bên
  azuki. Không viết proto (skill `spcc-migrate-console-rpc-to-core-proto`),
  không tạo branch/commit/push (skill `cred-proto-git`).
---

# Tạo PR cho Core API migration

## Khi Nào Dùng

Branch chứa proto migrate đã được push, và cần mở PR (hoặc sửa description của PR đã mở). Skill tự làm trọn phần PR: title, body, `gh pr create`, label. Không cần skill tạo PR nào khác.

Mục đích của description: để reviewer xác nhận Core proto khớp Console **có chủ ý**, field theo field, và mọi khác biệt đều nằm trong các quyết định đã chốt với JP (bảng "Quyết định đã chốt" của skill `spcc-migrate-console-rpc-to-core-proto`). Bảng field là phần bắt buộc, quan trọng nhất.

## Đầu Vào / Đầu Ra

**Đầu vào:**

| Thứ | Lấy từ đâu |
|---|---|
| Migration report | Đầu ra của skill `spcc-migrate-console-rpc-to-core-proto` (format ở `references/migration-report.md` của skill đó). Không có report → user phải cung cấp đủ các mục tương đương; thiếu bảng field thì dừng, không tự chế |
| Branch (đã push) và base branch | Đầu ra của skill `cred-proto-git` |
| Ticket `CRES-#####` | User / report |
| Loại PR | `Mode` trong report: `new`, `extend`, `followup`; hoặc PR handler azuki |

**Đầu ra:** link PR, số PR, label đã gắn.

**Không mở PR khi:** `Result: stopped` hoặc mục `## Stopped` của report khác `None`; còn điểm chưa hỏi user; lint/format chưa pass (xem `## Verification` của report).

## Người Đọc Và Độ Dài

Reviewer là member phía JP. Description phải **ngắn gọn nhưng đủ để review**:

- Không đưa link/thông tin nội bộ của TEQ: Backlog (`SPCC-...`), Mattermost nội bộ, ghi chú tiếng Việt, tên file report.
- Không lặp lại bảng từng field khi field giống hệt Console. Chỉ liệt kê **chỗ khác Console** (`### Differences from Console`), rồi một câu khẳng định phần còn lại giống Console. Bảng `### Field mapping` đầy đủ chỉ dùng khi RPC có field bị bỏ (entity phụ), đánh số lại, hoặc mở rộng theo Hướng A.
- Không kể lịch sử làm việc (review cũ, PR follow-up đã merge) trừ khi reviewer cần nó để hiểu diff.
- `## 参考リンク`: chỉ Jira và design doc (và PR liên quan nếu reviewer cần).

## Ngôn Ngữ

- Title và body **tiếng Anh**.
- Giữ nguyên 2 heading của `.github/pull_request_template.md`: `## 概要`, `## 参考リンク`. Mọi thứ bên dưới viết tiếng Anh.
- Tên RPC, message, field, entity giữ nguyên.
- Comment trong proto vẫn tiếng Nhật — quy ước riêng của proto, không liên quan ngôn ngữ PR.

## Quy Trình

1. **Kiểm tra điều kiện.** Đọc report: `Result`, `## Stopped`, `## Verification`. Có vấn đề → dừng, báo user.
2. **Kiểm tra branch đã push:**

   ```bash
   git -C <repo> rev-parse --abbrev-ref HEAD
   git -C <repo> ls-remote --exit-code --heads origin <branch>
   gh pr list --head <branch> --state open --json number,url   # đã có PR chưa
   ```

   Đã có PR mở cho branch này → sang bước 7 (cập nhật), không tạo PR thứ hai.
3. **Chọn template** trong `references/templates.md` theo `Mode`: `new` → §1, `extend` → §2, `followup` → §3, handler azuki → §4.
4. **Soạn title** (bảng dưới). Phải khớp regex CI `(hotfix[ ]*:?[ ]*)?.*CRES-[0-9]+`, dưới 70 ký tự, không prefix `feat:`.

   | Loại | Title |
   |---|---|
   | `new` | `[CRES-#####] Add <RpcName> to Core API` — mỗi PR 1 RPC nên dùng tên RPC, không phải tên nhóm; chỉ dùng `<RPC group>` khi user chủ động yêu cầu gộp nhiều RPC vào 1 PR |
   | `extend` | `[CRES-#####] Extend Core <RpcName> for Console migration` |
   | `followup` | `[CRES-#####] Align <RpcName> with Console types (chunk_1)` |
   | azuki handler | `[CRES-#####] Implement Core <RPC group> handlers` |
   | batch đăng ký `CoreService` | `[CRES-#####] Register <RPC group> in CoreService` |

5. **Soạn body** vào file (ngoài repo), theo template, lấy nội dung từ report:

   | Mục PR | Lấy từ report |
   |---|---|
   | `### Target RPCs` | `## Target RPCs` (bỏ cột entity count nếu không cần; giữ `Status`) |
   | `### Added definitions` | `## Files changed`, kèm 1 dòng ngắn gọn ngay dưới: đăng ký vào `CoreService` sẽ làm theo lô ở PR khác |
   | `### Field mapping` | `## Field mapping` — chép nguyên bảng |
   | `### Deprecated fields` | `## Deprecated fields` |
   | `### Validation added on top of Console` | `## Validation added on top of Console` |
   | `### Required in Console, optional in Core` | `## Required in Console, optional in Core` (chỉ `extend`) |
   | `### Changes` (followup) | `## Follow-up context` |

   PR description **không còn** các mục `Not included in this PR`, `Verified`, `Points to confirm`, `Skipped RPCs` — các mục này vẫn ghi đầy đủ trong migration report (nội bộ, phục vụ audit/bước review lại), chỉ không đưa vào body PR nữa.

   Quy tắc từng mục: `references/section-rules.md`.
6. **Tạo PR:**

   ```bash
   gh pr create --repo Finatext/cred-proto --base <base> --head <branch> \
     --title "<title>" --body-file <body.md>
   gh pr edit <number> --add-label "release:minor"
   ```

   - `--body-file`, không `--body` inline (bảng markdown dễ vỡ).
   - `--base`: `master`, hoặc nhánh PR gốc khi `followup`.
   - Label semver (cred-proto bắt buộc đúng 1): xem `references/ci-and-labels.md`. Mặc định `release:minor`.
   - PR bên azuki không có label semver.
7. **Cập nhật PR đã mở** (khi cần):

   ```bash
   gh pr edit <number> --title "<title>" --body-file <body.md>
   ```

   Giữ nội dung reviewer đã thêm vào `## 参考リンク`.
8. **Kiểm tra lại:**

   ```bash
   gh pr view <number> --json url,baseRefName,labels,title -q '.url+" | "+.baseRefName+" | "+([.labels[].name]|join(","))+" | "+.title'
   ```

   Báo link PR, base, label. Nhắc CI `preview-core-api-docs.yml` chạy khoảng 45 phút với PR đụng `proto/core/**`.

## Checklist Trước Khi Tạo

- [ ] Title khớp regex, chứa `CRES-#####`, đúng bảng format
- [ ] Body tiếng Anh; chỉ `## 概要` / `## 参考リンク` là tiếng Nhật
- [ ] Không có link/thông tin nội bộ TEQ (Backlog, ghi chú tiếng Việt)
- [ ] Field giống hệt Console không bị liệt kê từng dòng; chỉ có `### Differences from Console`
- [ ] `### Target RPCs` liệt kê mọi RPC trong PR (thường chỉ 1 RPC)
- [ ] RPC có field bị bỏ / đánh số lại / Hướng A có bảng `### Field mapping`
- [ ] `### Deprecated fields` có mặt (hoặc `None`)
- [ ] `### Validation added on top of Console` có mặt (hoặc `None`), mọi rule có `Verification`
- [ ] PR `extend`: có `### Required in Console, optional in Core` kèm câu hỏi về response trả cho minazuki
- [ ] `### Added definitions` có 1 dòng ngắn ghi đăng ký `CoreService` làm theo lô ở PR khác (trừ PR `extend` — RPC đã đăng ký sẵn, và trừ PR batch đăng ký ở Bước 8 của workflow)
- [ ] PR `new` / `followup`: diff **không có** `proto/core/rpc/core_service.proto` (đăng ký dồn vào PR batch riêng)
- [ ] Body **không có** heading `Not included in this PR`, `Verified`, `Points to confirm`, `Skipped RPCs`
- [ ] Link Jira đầy đủ `https://finatexthd.atlassian.net/browse/CRES-#####`
- [ ] Đúng 1 label semver (cred-proto)

## Anti-patterns

- Sinh body từ `git diff` — mất bảng field.
- Tự điền bảng field khi không có report — bảng phải phản ánh proto thật.
- Ghi `Not migrated` cho field Console không deprecated — proto sai, quay lại sửa proto.
- Tạo PR thứ hai cho cùng branch.
- Gắn `release:major` để "cho qua" một thay đổi breaking.
- Để `core_service.proto` lọt vào diff của PR `new` / `followup` (trừ PR batch đăng ký ở Bước 8 của workflow, hoặc `extend` khi RPC đã có sẵn).

## Red Flags

🚩 Report có `## Stopped` khác `None` mà vẫn được yêu cầu mở PR.
🚩 `--base master` cho PR follow-up (diff sẽ lẫn toàn bộ PR gốc).
🚩 Note cho JP reviewer trong PR (dưới `### Target RPCs` / `### Required in Console, optional in Core`) chứa câu hỏi chưa từng hỏi user.

## Reference

| File | Đọc khi |
|---|---|
| [templates.md](references/templates.md) | Soạn body — 4 template tiếng Anh |
| [section-rules.md](references/section-rules.md) | Viết từng mục, giá trị hợp lệ của `Status` / `Handling` |
| [ci-and-labels.md](references/ci-and-labels.md) | Chọn label semver, hiểu CI chạy gì trên PR, reviewer |
