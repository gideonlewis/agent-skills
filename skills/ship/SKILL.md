---
name: ship
description: Chuẩn bị và deploy code lên production một cách an toàn, đầy đủ tài liệu. Dùng khi đã review xong và cần chốt các bước cuối trước khi release — versioning, changelog, deployment, monitoring.
---

# Ship

Chuẩn bị và ship thay đổi lên production.

**Phase: SHIP**

## Khi nào dùng

- Code đã được review và test pass, cần chuẩn bị các bước cuối để release.
- Cần checklist đảm bảo không bỏ sót bước nào trước khi deploy.

## Quy trình

Khi được kích hoạt:

1. **Final checks** — Toàn bộ test đã pass? Code đã được review?
2. **Documentation** — README, API docs, migration guide đã cập nhật?
3. **Versioning** — Semantic versioning (MAJOR.MINOR.PATCH)
4. **Changelog** — Ghi lại đã thay đổi gì và tại sao
5. **Deployment** — Push lên production (hoặc tạo PR để chờ approval)
6. **Monitoring** — Đảm bảo observability đã sẵn sàng

### Checklist

- [ ] Toàn bộ test pass ở local
- [ ] Code đã được review và approve
- [ ] Documentation đã cập nhật
- [ ] Version đã bump (CHANGELOG.md, package.json, v.v.)
- [ ] Migration guide đã viết (nếu cần)
- [ ] Đã deploy hoặc đã tạo PR
- [ ] Monitoring/alert đã sẵn sàng

## Anti-patterns

- Ship khi còn test fail hoặc chưa được review, "để fix sau".
- Bỏ qua changelog/documentation vì "thay đổi nhỏ".
- Deploy trực tiếp lên production mà không qua PR/approval khi quy trình team yêu cầu.

## Red Flags

🚩 Deploy được thực hiện mà chưa có xác nhận từ người dùng (đây là hành động khó đảo ngược, ảnh hưởng hệ thống chung).
🚩 Không có kế hoạch rollback nếu deployment gặp sự cố.
