# Cấu hình Google OAuth với Domain mới (Next.js & .NET API)

Hướng dẫn thay đổi thông tin xác thực Google OAuth khi hệ thống cấu hình lại với một email quản trị mới và domain mới, bao gồm thao tác trên Google Cloud Console và cách cập nhật biến môi trường cho cả Frontend (Next.js) lẫn Backend (.NET API).

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

1. **Google Cloud**: Tạo `Web application` Client ID trong mục Credentials.
2. **Authorized JavaScript origins**: Các URL gốc (`http://localhost:3000`, `https://yourdomain.com`).
3. **Authorized redirect URIs**: Các đường dẫn callback (Vd: `.../api/auth/google/callback`).
4. Copy sinh ra **Client ID** & **Client Secret**.
5. **Frontend**: Cập nhật `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_GOOGLE_CLIENT_ID` trong `.env`.
6. **Backend**: Cập nhật `Google__ClientId`, `Google__ClientSecret`, `Google__RedirectUri` và `Frontend__BaseUrl`.

## 📝 Các bước thực hiện (Step by Step)

### Bước 1: Khai báo ứng dụng trên Google Cloud (OAuth Consent Screen)
Nếu bạn chưa tạo màn hình đồng ý ứng dụng cho email mới:
1. Đăng nhập [Google Cloud Console](https://console.cloud.google.com/).
2. Tạo dự án mới hoặc chọn dự án hiện tại.
3. Chuyển đến phần **APIs & Services** > **OAuth consent screen** (hoặc nhấn nút Get Started trên giao diện mới).
4. Chọn **User Type: External** và tiếp tục.
5. Điền thông tin:
   - **App name**: Tên ứng dụng của bạn.
   - **User support email** & **Developer contact email**: Email của bạn.
   - **Authorized domains**: Tên miền chính (vd: `yourdomain.com`).
6. Nhấn Save and Continue cho đến khi hoàn thành (Finish).

### Bước 2: Tạo Credentials để lấy Client ID & Secret
1. Chuyển sang mục **Credentials** (menu bên trái).
2. Nhấn nút xanh **+ CREATE CREDENTIALS** (hoặc **CREATE CLIENT**) > Chọn **OAuth client ID**.
3. Tại trường **Application type**, chọn **Web application**.
4. Đặt **Name** cho client (vd: `Project Web Client`).
5. Ở **Authorized JavaScript origins** (Nguồn gốc ứng dụng), thêm:
   - `http://localhost:3000`
   - `https://yourdomain.com`
6. Ở **Authorized redirect URIs** (Đường dẫn chuyển hướng trả về), thêm đủ các link callback:
   - `http://localhost:3000/vi/auth/callback`
   - `http://localhost:3000/en/auth/callback`
   - `https://yourdomain.com/vi/auth/callback`
   - `https://yourdomain.com/en/auth/callback`
   - `https://api.yourdomain.com/api/auth/google/callback` (Dành cho Backend xử lý)
7. Nhấn **Create**. Sao chép ngay **Client ID** và **Client Secret** vừa được cấp.

### Bước 3: Cập nhật biến môi trường cho Frontend
Mở file `.env` (hoặc cấu hình môi trường deploy) của dự án Frontend (Next.js) và thay đổi:
```env
# Trỏ Backend base URL về domain mới
NEXT_PUBLIC_API_URL=https://api.yourdomain.com/api

# Cài đặt Google Client ID vừa lấy
NEXT_PUBLIC_GOOGLE_CLIENT_ID=<Client ID mới>
```

### Bước 4: Cập nhật biến môi trường cho Backend
Mở file `.env` (hoặc file cấu hình production) của dự án Backend (.NET API) và sửa:
```env
# Cấu hình Google OAuth
Google__ClientId=<Client ID mới>
Google__ClientSecret=<Client Secret mới>
Google__RedirectUri=https://api.yourdomain.com/api/auth/google/callback

# Cấu hình Frontend Base URL để setup CORS hoặc các logic Redirect liên quan
Frontend__BaseUrl=https://yourdomain.com
```

## ⚠️ Troubleshooting / Lưu ý

- **Lỗi Mismatch Redirect URI (`redirect_uri_mismatch`)**:
  Đảm bảo URL gọi từ trình duyệt lên API **khớp chính xác 100%** (kể cả phần `http(s)` và dấu `/` nếu có) với danh sách đã khai báo trong mục **Authorized redirect URIs** trên Google Cloud.
- **Thời gian áp dụng**: Google có thể mất từ 5-10 phút để cấu hình mới và domain hoạt động đầy đủ trên hệ thống của họ.
- Nếu Backend chạy phía sau Proxy (ví dụ Cloudflare / Nginx / Caddy), đảm bảo **Forward Headers** đã được cấu hình đúng để máy chủ nhận diện giao thức đang gọi là `https`, nếu không `RedirectUri` sẽ sinh ra là `http` và gây lỗi `mismatch`.
