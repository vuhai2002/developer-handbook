---
name: add-guide
description: Thêm một guide how-to mới vào repo developer-handbook theo đúng format chuẩn (Quick Reference + Step by Step), cập nhật README index, quét bảo mật, rồi commit + push. Dùng khi người dùng muốn thêm/tạo một guide, "lưu cách làm này vào handbook", hoặc hệ thống hoá một đoạn chat / tài liệu / quy trình thành bài viết trong cẩm nang dev.
---

# Add Guide - thêm guide vào Developer Handbook

Người dùng cung cấp 1 đoạn chat / tài liệu thô / chủ đề. Nhiệm vụ: tổng hợp thành 1 guide chuẩn của repo, cập nhật README, rồi commit + push. Repo này **PUBLIC** -> generic hoá tuyệt đối (xem `CLAUDE.md`).

## Quy trình

### 1. Tổng hợp + đặt tên
- Lọc thông tin chính (công cụ, quy trình, lệnh, lỗi thường gặp) từ nội dung người dùng đưa.
- Đặt **tiêu đề ngắn** (tiếng Việt) + **tên file kebab-case** ở gốc repo, vd `setup-redis-cache.md`, `fix-nginx-502.md`.

### 2. Viết file guide (ở gốc repo)
Theo khung `resources/guide-template.md`. Cấu trúc BẮT BUỘC:
- **H1** tiêu đề + **mô tả ngắn** (1-2 câu: guide để làm gì).
- `## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)` - lệnh/step rút gọn, copy-paste, KHÔNG giải thích dài.
- `## 📝 Các bước thực hiện (Step by Step)` - chi tiết, giải thích từng bước (kèm "tại sao" khi cần).
- (tùy chọn) `## ⚠️ Troubleshooting / Lưu ý`.

### 3. Cập nhật README.md
- Tìm mục phù hợp trong `## 📌 Contents`: `🔐 Server & Infrastructure` (server/VPS/DB/network/proxy) hoặc `🛠️ Tools & Utilities` (công cụ/tích hợp/tiện ích).
- Chèn dòng: `- [Tiêu đề](./ten-file.md)`.

### 4. Guardrail BẮT BUỘC (repo PUBLIC)
- **Chỉ placeholder generic**: `example.com`, `app.example.com`, `<bucket>`, `fNNN`, `<path>`, `<token>`... KHÔNG domain/IP/bucket/secret thật.
- **Giữ dấu tiếng Việt ở MỌI chỗ, kể cả comment trong code block** (đừng strip thành không dấu).
- Punctuation ASCII (`-`, `->`, `"`).
- **Quét bảo mật trước khi commit** - grep file mới tìm giá trị thật lọt vào:
  ```bash
  grep -nEi '<domain-that-cua-ban>|([0-9]{1,3}\.){3}[0-9]{1,3}|password|secret|token|Bearer|api[_-]?key' <file-moi>.md
  ```
  Có nghi vấn -> đổi thành placeholder, quét lại tới khi sạch.

### 5. Commit + push
- `git add <file-moi>.md README.md`
- `git commit -m "docs: add <tiêu đề>"` (conventional commit, KHÔNG có AI reference).
- `git push`.

### 6. Báo cáo
Báo ngắn: file đã tạo, README đã link đúng mục, kết quả quét bảo mật, và commit hash đã push.

## Resources
- `resources/guide-template.md` - khung guide chuẩn, copy rồi điền.
