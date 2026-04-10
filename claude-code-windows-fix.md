# Hướng dẫn sửa lỗi kết nối Claude Code trên Windows (ECONNREFUSED & Bun Crash)

Hướng dẫn này giúp xử lý triệt để hai lỗi phổ biến khi cài đặt và sử dụng **Claude Code** trên Windows: lỗi không thể kết nối tới API (`Unable to connect to API: ECONNREFUSED` khi xuất ra prompt) và lỗi sập trình biên dịch bản Native (`Bun has crashed: Internal assertion failure`).

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

Mở PowerShell và chạy các lệnh sau theo thứ tự:

1. Gỡ bản cài đặt cũ qua NPM (nếu có):
   ```powershell
   npm uninstall -g @anthropic-ai/claude-code
   ```
2. Xóa các tệp cấu hình và cache bị lỗi của Claude Code:
   ```powershell
   Remove-Item -Path "$env:USERPROFILE\.claude" -Recurse -Force
   Remove-Item -Path "$env:USERPROFILE\.claude.json" -Force
   Remove-Item -Path ".claude" -Recurse -Force
   Remove-Item -Path ".mcp.json" -Force
   ```
3. Cài đặt lại Claude Code bằng bản **Native Stable** (Phiên bản ổn định của hãng, tránh lỗi bug từ nhánh Latest):
   ```powershell
   & ([scriptblock]::Create((irm https://claude.ai/install.ps1))) stable
   ```

## 📝 Các bước thực hiện (Step by Step)

### Bước 1: Gỡ bỏ phiên bản NPM (Do lỗi thời)
Trong đa số trường hợp, người cài đặt Claude Code ban đầu thường cài qua môi trường Node.js (`npm install -g @anthropic-ai/claude-code`). Tuy nhiên, tài liệu của Anthropic đã cập nhật đây là bản cài lỗi thời (deprecated). Chạy qua Node.js trên Windows hay gây ra các vấn đề về phân giải cổng mạng nội bộ (điển hình nhất là báo lỗi đoạn `ECONNREFUSED` giữa lúc sử dụng prompt do mất kết nối với local server). 

**Thực hiện:** Cần loại bỏ cài đặt cũ ra khỏi NPM trên hệ thống:
```powershell
npm uninstall -g @anthropic-ai/claude-code
```

### Bước 2: Xóa bộ đệm và tệp cấu hình (.claude.json)
Khi chuyển từ NPM sang sử dụng bản Native (biên dịch bằng lõi `Bun`), định dạng lưu ở file cấu hình JSON/YAML cũ có thể không tương thích. Lõi hệ thống Bun khi cố đọc tệp này có thể bị văng ra lỗi: `panic: Internal assertion failure - Bun has crashed... yaml_parse(500)`.

**Thực hiện:** Để tránh tàn dư lỗi từ cài đặt cũ, bạn cần xoá toàn bộ bộ đệm cấu hình (Lưu ý: Lịch sử chat cũ ở Terminal sẽ bị mất, công cụ được trả về trạng thái mặc định ban đầu):

Với thư mục gốc của tài khoản người dùng:
```powershell
Remove-Item -Path "$env:USERPROFILE\.claude" -Recurse -Force
Remove-Item -Path "$env:USERPROFILE\.claude.json" -Force
```
Nếu có tệp cấu hình tool ở trong thư mục dự án bạn đang mở PowerShell:
```powershell
Remove-Item -Path ".claude" -Recurse -Force
Remove-Item -Path ".mcp.json" -Force
```

### Bước 3: Cài đặt bản Native Stable
Cài đặt bản Native (file thực thi độc lập `.exe`) giúp ứng dụng chạy nhẹ hơn và bỏ qua được dependency của hệ điều hành. Tuy nhiên, để tránh trường hợp bản cập nhật quá mới (Latest) gặp bugs của Bun Compiler trên Win (ví dụ bản v2.1.100), tốt nhất là cài cố định vào nhánh `Stable`.

**Thực hiện:** Gõ lệnh sau vào PowerShell để thiết lập nhánh Stable:
```powershell
& ([scriptblock]::Create((irm https://claude.ai/install.ps1))) stable
```
*(Tip: Nếu muốn cập nhật lên bản dùng thử mới nhất sau này, bạn có thể xóa chữ stable và dùng lệnh `irm https://claude.ai/install.ps1 | iex`)*

## ⚠️ Troubleshooting / Lưu ý 

- **Xác minh lỗi do Proxy:** Đôi khi lỗi bị từ chối kết nối (ECONNREFUSED) đến từ việc Terminal trên máy Windows bị cài đè một HTTP Agent. Bạn có thể kiểm tra các biến môi trường Proxy ẩn bằng lệnh `$env:HTTP_PROXY` hoặc `$env:HTTPS_PROXY` và gán vô giá trị như `$env:HTTP_PROXY=""` nếu phát hiện có proxy rác.
- **Yêu cầu hệ thống phụ:** Chạy `claude` không cần khởi động quyền Administrator với bản Native, tuy nhiên máy tính của bạn phải được cài đặt **[Git for Windows](https://git-scm.com/downloads/win)** vì Claude ẩn danh sử dụng thư viện mô phỏng Bash từ nó.
