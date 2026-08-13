---
name: test
description: Chứng minh code hoạt động đúng bằng test coverage toàn diện. Dùng khi cần verify implementation, tìm gap trong test coverage, hoặc debug test đang fail.
---

# Test

Verify implementation bằng test.

**Phase: VERIFY**

## Khi nào dùng

- Cần verify một implementation đã đúng theo yêu cầu.
- Nghi ngờ có gap trong test coverage (thiếu edge case, thiếu integration test...).
- Test đang fail và cần debug nguyên nhân.

## Quy trình

Khi được kích hoạt:

1. **Xác định gap** — Những scenario nào chưa được test coverage?
2. **Viết test trước** — TDD: test định nghĩa hành vi
3. **Implement code** — Làm cho test pass
4. **Verify coverage** — Toàn bộ happy path và edge case
5. **Debug failures** — Nếu test fail, chẩn đoán và fix

### Các loại test

- Unit test (từng function riêng lẻ)
- Integration test (các component hoạt động cùng nhau)
- End-to-end test (toàn bộ luồng người dùng)
- Edge case (điều kiện biên, lỗi)

## Anti-patterns

- Viết test sau khi code đã hoàn chỉnh chỉ để đạt coverage number, không thực sự định nghĩa hành vi.
- Bỏ qua edge case và chỉ test happy path.
- Mock quá mức khiến test không còn phản ánh hành vi thực tế của hệ thống.

## Red Flags

🚩 Coverage cao nhưng test không assert hành vi thực sự (chỉ gọi function mà không check kết quả).
🚩 Test fail bị skip/comment out thay vì được debug và fix.
