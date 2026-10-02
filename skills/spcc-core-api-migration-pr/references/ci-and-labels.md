# CI, label semver, reviewer của cred-proto

## 1. Label semver — CI chặn

Workflow `require-semver-label.yml` bắt buộc gắn **đúng 1** trong 4 label:

| Label | Khi nào |
|---|---|
| `release:major` | Breaking — di chuyển, đổi tên, xoá định nghĩa protobuf |
| `release:minor` | Tương thích ngược — thêm định nghĩa mới, thêm field, tạo RPC mới |
| `release:patch` | Thay đổi không ảnh hưởng — sửa comment |
| `norelease` | Bỏ qua release |

**Thêm Core RPC mới = `release:minor`.** Nếu vô tình tạo breaking change thì đó là dấu hiệu làm sai — xem lại thay vì gắn `release:major`. Ngoại lệ duy nhất: hướng B cho Core RPC chưa ship (`GetContracts`, `GetContractApplications`) mà user/JP đã chấp nhận breaking change — xem `existing-core-rpcs.md §3` của skill `spcc-migrate-console-rpc-to-core-proto`.

```bash
gh pr edit <number> --add-label "release:minor"
```

## 2. CI sẽ chạy những gì

| Workflow | Điều kiện | Chặn cái gì |
|---|---|---|
| `lint-and-format.yml` | mọi PR | `make lint` + `make format/check` |
| `pr-title-jira-check.yml` | PR mở/sửa | Title phải chứa `CRES-#####` |
| `require-semver-label.yml` | mở/gắn label/push | Đúng 1 label semver |
| `preview-core-api-docs.yml` | PR đụng `proto/core/**` | Build Redoc rồi comment link preview (~45 phút) |
| `preview-dist-diff.yml` | PR đụng config build/codegen | Comment diff của code sinh ra |
| `jira.yml` | vòng đời PR | Đồng bộ Jira |

`preview-core-api-docs.yml` **luôn chạy** với PR của skill này (vì đụng `proto/core/**`) và chạy khá lâu — báo trước cho user, đừng tưởng CI treo.

## 3. Reviewer

`.github/CODEOWNERS` chỉ có 1 dòng:

```
* @Finatext/d-cred-reviewer
```

Reviewer được gán tự động, không cần tự thêm.

Merge đi qua PR (`Merge pull request #NNNN from Finatext/<branch>`), không push thẳng `master`.

