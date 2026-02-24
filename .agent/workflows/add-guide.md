---
description: Tạo hướng dẫn mới cho Developer Handbook với chuẩn format tự động và cập nhật README
---

Khi Workflow này được gọi, USER sẽ cung cấp một đoạn chat, một tài liệu thô hoặc một chủ đề. Nhiệm vụ của bạn là tổng hợp và tạo ra một bài viết chuẩn cho Developer Handbook hệ thống hóa lại kiến thức đó theo các bước cực kỳ nghiêm ngặt dưới đây:

1. **Phân tích và Tổng hợp:** 
   - Đọc kỹ nội dung USER cung cấp. Lọc ra các thông tin chính yếu (công cụ, quy trình, lỗi thường gặp).
   - Hãy suy nghĩ về một tiêu đề ngắn gọn và một tên file `.md` phù hợp (ví dụ: `install-docker-ubuntu.md`).

2. **Tạo File Hướng dẫn Mới (Write to file):**
   - Viết file này vào thư mục gốc `d:\source-code\developer-handbook\`.
   - File BẮT BUỘC phải tuân theo cấu trúc sau:
      - **Tiêu đề chính (H1):** Tên của bài Hướng dẫn.
      - **Mô tả ngắn:** Hướng dẫn này để làm gì.
      - **## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference):** Liệt kê các lệnh, thao tác, step rút gọn để copy/paste nhanh ngọn nhất. Không giải thích lằng nhằng ở mục này.
      - **## 📝 Các bước thực hiện (Step by Step):** Hướng dẫn chi tiết giải thích cho từng thao tác.
      - (Tùy chọn) **## ⚠️ Troubleshooting / Lưu ý:** Xử lý các lỗi có thể gặp.

3. **Cập nhật README:**
   - Đọc nội dung file `d:\source-code\developer-handbook\README.md`.
   - Tìm chuyên mục phù hợp nhất trong phần `## 📌 Contents` (ví dụ: "Server & Infrastructure" hoặc "Tools & Utilities").
   - Chèn link của file vừa tạo vào đúng format: `- [Tên bài viết](./ten-file-vua-tao.md)`.

4. **Lưu Git (Commit & Push):**
   - Sử dụng tool để chạy lệnh kiểm tra, `git add`, `git commit -m "docs: add [Tên bài viết]"`.
   - Sau đó chạy lệnh `git push` để đẩy code lên kho lưu trữ.
   - // turbo-all (Nếu sử dụng tool run_command cho phần này, hãy đặt SafeToAutoRun thành true để chạy luôn).

5. **Báo cáo lại:**
   - Thông báo ngắn gọn cho USER là file đã được sinh ra, README đã được link với markdown chuẩn xác, và mã đã được đẩy lên Git.
