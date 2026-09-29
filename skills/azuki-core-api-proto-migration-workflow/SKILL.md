---
name: azuki-core-api-proto-migration-workflow
description: >
  Workflow end-to-end migrate Console API → Core API ở tầng proto trong
  cred-proto, ghép 3 skill riêng lẻ theo thứ tự: tạo branch (cred-proto-git) →
  phân tích RPC và viết proto (azuki-migrate-console-rpc-to-core-proto, KHÔNG
  đăng ký vào core_service.proto) → commit/push (cred-proto-git) → tạo PR và
  description (azuki-core-api-migration-pr) → review lại
  (azuki-review-console-rpc-to-core-proto, tuỳ chọn). Mỗi RPC một branch/PR
  riêng (không gộp batch); đăng ký core_service.proto dồn vào 1 PR khác sau.
  Dùng khi user đưa 1 (hoặc vài, xử lý tuần tự) Console RPC và muốn "migrate và
  mở PR", "làm trọn từ branch tới PR", hoặc đưa link một PR migrate cũ và muốn
  "tạo PR follow-up để sửa cho đúng quy tắc". Chỉ cần một bước riêng (chỉ viết
  proto, chỉ tạo PR, chỉ tạo branch) thì dùng thẳng skill tương ứng.
---

# Workflow: Console RPC → Core proto → PR

## Khi Nào Dùng

- User đưa Console RPC (thường 1 RPC — xem "Mỗi RPC Một PR" bên dưới) và muốn đi hết từ branch tới PR.
- User đưa link PR migrate cũ và muốn một PR follow-up sửa cho đúng quy tắc hiện tại, không đụng PR gốc.

Skill này **không chứa quy tắc nghiệp vụ**. Nó chỉ gọi đúng skill theo đúng thứ tự, truyền đầu ra bước trước làm đầu vào bước sau, và dừng khi một bước dừng. Quy tắc proto nằm ở skill `azuki-migrate-console-rpc-to-core-proto`.

## Mỗi RPC Một PR

Chính sách hiện tại (thay cho batch 3-5 RPC/PR trước đây): **mỗi Console RPC migrate ra đúng 1 PR proto riêng**, và PR đó **không đụng `core_service.proto`** — import + dòng `rpc` chỉ được ghi vào migration report (mục "Registration (pending)"), việc đăng ký thật vào `CoreService` dồn lại làm theo lô ở 1 PR riêng sau (base `master` mới nhất, sau khi các PR RPC liên quan đã merge). Mục đích: nhiều RPC được review/merge song song mà không đụng conflict ở `core_service.proto`.

User đưa nhiều RPC trong 1 lần yêu cầu → chạy workflow này **tuần tự cho từng RPC**, mỗi RPC một branch riêng từ `master`, một PR riêng — không gộp vào 1 branch/PR.

## Các Skill Được Dùng

| Bước | Skill | Việc |
|---|---|---|
| 1, 4 | `cred-proto-git` | Tạo branch (`new` / `followup`), commit + push |
| 2 | `azuki-migrate-console-rpc-to-core-proto` | Phân tích RPC, viết proto, lint/gen, so field, xuất migration report |
| 5 | `azuki-core-api-migration-pr` | Title/body tiếng Anh, `gh pr create`, label |
| 6 | `azuki-review-console-rpc-to-core-proto` | Review lại PR vừa tạo (tuỳ chọn, khuyến nghị) |

Thiếu skill nào trên máy → báo user cài (`./install.sh <tên-skill>` trong repo `agent-skills`), hoặc làm bước đó thủ công theo "Đầu ra phải có" ở bảng dưới.

## Đầu Vào

| Chế độ | Cần có |
|---|---|
| RPC mới | 1 Console RPC (có/không kèm loại), ticket `CRES-#####`, đường dẫn repo `cred-proto` |
| Follow-up | Số/link PR migrate cũ; ticket lấy từ title PR gốc nếu user không đưa |

Nên có thêm đường dẫn `azuki` và `azuki-app` (bước 2 kiểm chứng validate bổ sung bằng code). Không có → bước 2 không thêm validate nào, ghi `Not added` trong report.

Thiếu ticket ở chế độ RPC mới → hỏi trước khi bắt đầu.

## Quy Trình

### Bước 1 — Chuẩn bị branch (`cred-proto-git`)

- RPC mới: chế độ `new`, tên `feature/CRES-#####-<kebab-tên-rpc>` (1 RPC/branch, ví dụ `feature/CRES-20700-core-api-get-borrower-notes`).
- Follow-up: chế độ `followup` với số PR gốc.

**Đầu ra phải có:** `branch`, `base`, `mode`. Worktree có thay đổi lạ → skill dừng, workflow dừng theo.

### Bước 2 — Phân tích và viết proto (`azuki-migrate-console-rpc-to-core-proto`)

Truyền: **1 RPC** (hoặc số PR gốc ở follow-up), ticket, `mode`. Skill **không sửa `core_service.proto`** — chỉ ghi import/dòng `rpc` cần thêm vào mục "Registration (pending)" của report.

**Đầu ra phải có:** file proto đã sửa (chưa commit, **không gồm `core_service.proto`**) và **đường dẫn migration report**.

### Bước 3 — Cổng kiểm tra report

Đọc report:

| Điều kiện | Hành động |
|---|---|
| `Result: stopped` hoặc `## Stopped` khác `None` | **Dừng.** Trình bày từng điểm dừng cho user kèm các option. User quyết → quay lại bước 2 cho đúng RPC đó (cùng branch), rồi đọc lại report |
| `## Verification` có lint/format/gen fail hoặc `not run` | Dừng, báo user (thường là Docker down) |
| RPC là `Skipped` / `Out of scope` | Không có gì để commit → dừng, báo user chọn RPC khác. Xoá branch rỗng nếu vừa tạo ở bước 1 (`git switch -` rồi `git branch -d <branch>`) sau khi user đồng ý |
| Còn lại | Sang bước 4 |

### Bước 4 — Commit và push (`cred-proto-git`, chế độ `commit-push`)

- File: đúng `## Files changed` của report (không có `core_service.proto`).
- Message: `feat: [CRES-#####] Add <RpcName> to Core API` (RPC mới / extend) hoặc `fix: [CRES-#####] Align <RpcName> with Console types (chunk_1)` (follow-up); thân message tóm tắt từ report.

**Đầu ra phải có:** branch đã push.

### Bước 5 — Tạo PR (`azuki-core-api-migration-pr`)

Truyền: đường dẫn report, `branch`, `base`, ticket.

**Đầu ra phải có:** link + số PR, label `release:minor`.

### Bước 6 — Review lại (`azuki-review-console-rpc-to-core-proto`, khuyến nghị)

Review chính PR vừa tạo.

| Kết quả | Hành động |
|---|---|
| Có finding **Blocker** / **Cần sửa** | Quay lại bước 2 trên cùng branch cho các RPC bị nêu → bước 4 (commit `fix:`) → cập nhật description bằng skill `azuki-core-api-migration-pr` (chế độ cập nhật). Lặp tối đa 2 vòng, sau đó báo user |
| Chỉ **Nên sửa** | Sửa luôn nếu đơn giản (comment, JSON mẫu), hoặc liệt kê cho user |
| **Cần hỏi JP** | Đảm bảo đã có trong `### Points to confirm` của PR |

### Bước 7 — Báo cáo cho user

```text
PR: <link> (base: <base>, label: release:minor)
RPC: <Added / Extended / Skipped / Out of scope theo report>
Validate bổ sung: <số rule> (xem PR)
Cần JP confirm: <tóm tắt Points to confirm>
Đăng ký core_service.proto: pending (dồn vào PR batch riêng sau khi merge)
Chưa làm: handler azuki, switch azuki-app, feature flag, rollout
```

### Bước 8 — Đăng ký `core_service.proto` theo lô (khi user yêu cầu, không tự động)

Không chạy bước này ngay sau bước 7. Chỉ chạy khi user chủ động yêu cầu "đăng ký các RPC đã merge vào core_service", thường sau khi vài PR RPC ở trên đã merge vào `master`.

1. Kiểm tra RPC nào thật sự đã merge (`git log --diff-filter=A -- proto/core/rpc/<file>.proto` trên `master`, hoặc `gh pr view <n> --json state,mergedAt`). Chỉ gom RPC đã merge; RPC còn ở PR chưa merge thì bỏ lại, không đăng ký hụt (rpc trỏ tới file không tồn tại trên `master` sẽ làm `buf` lỗi).
2. Bước 1 (`cred-proto-git`, chế độ `new`) tạo 1 branch mới từ `master` mới nhất, ví dụ `feature/CRES-#####-register-core-service`.
3. Gộp mục "Registration (pending)" của các migration report liên quan (hoặc đọc trực tiếp từng file `.proto` đã merge nếu không còn giữ report) thành 1 lần sửa `core_service.proto`: import đúng alphabet, dòng `rpc` đặt cạnh cụm domain liên quan.
4. Chạy `make lint`, `make format/check`, `make gen`.
5. Bước 4 (`commit-push`): message `feat: [CRES-#####] Register <RPC group> in CoreService`.
6. Bước 5 (`azuki-core-api-migration-pr`): title `[CRES-#####] Register <RPC group> in CoreService`, body liệt kê RPC được đăng ký và PR proto tương ứng (link, không cần bảng field vì proto không đổi).

## Tuỳ Biến Cho Từng Member

Mỗi bước là một skill độc lập, thay được bằng cách làm riêng của member, miễn giữ **đầu ra phải có** của bước đó:

| Muốn | Cách |
|---|---|
| Tự quản branch/commit theo quy trình riêng | Bỏ bước 1 và 4, chỉ cần đưa cho bước 2 một branch không phải `master`, và branch đã push trước bước 5 |
| Chỉ viết proto, tự mở PR | Dừng sau bước 3, dùng migration report làm nội dung PR |
| Không review tự động | Bỏ bước 6 |
| Vẫn muốn gộp nhiều RPC vào 1 PR (khác chính sách mặc định hiện tại) | User phải nói rõ; gọi bước 2 nhiều lần trên cùng branch, ghép migration report trước bước 5, và báo user rằng PR gộp này vẫn nên tách `core_service.proto` ra theo Bước 8 |
| Nhiều agent song song | Mỗi agent một RPC, **mỗi RPC một branch** (không dùng chung branch giữa các agent) |

## Anti-patterns

- Sang bước 4/5 khi report `Result: stopped`.
- Tự sửa proto ở bước 5/6 mà không qua skill bước 2 (report không còn khớp proto).
- Gộp nhiều RPC vào một PR mà user không yêu cầu, hoặc nhiều PR cho một RPC.
- Sửa `core_service.proto` trong PR proto của từng RPC — kể cả khi chỉ thêm đúng 1 dòng.
- Mở PR follow-up với `base: master`.
- Chạy bước 8 (đăng ký batch) khi chưa được user yêu cầu, hoặc gom cả RPC chưa merge vào `master`.

## Red Flags

🚩 Bước 5 không tìm thấy migration report nhưng vẫn định tạo PR.
🚩 Vòng lặp bước 6 → bước 2 quá 2 lần — có điểm cần user/JP quyết, không phải lỗi kỹ thuật.
🚩 `git status` trước bước 4 có file ngoài `## Files changed` của report.
