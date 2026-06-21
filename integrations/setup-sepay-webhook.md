# Hướng dẫn cấu hình API Key và Webhook SePay

Tài liệu này hướng dẫn chi tiết từng bước cách lấy các thông tin cấu hình từ SePay.vn để tích hợp thanh toán (mã QR tĩnh & Webhook) vào hệ thống backend.

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

Bạn cần 4 biến môi trường sau để ứng dụng hoạt động:
```env
SEPAY_BANK_NAME="MBBank"       # Hoặc tên viết tắt ngân hàng khác (VD: Vietcombank, ACB)
SEPAY_ACCOUNT_NUMBER="123456"  # Số tài khoản
SEPAY_ACCOUNT_NAME="NGUYEN A"  # Tên tài khoản
SEPAY_WEBHOOK_API_KEY="xxx"    # Tạo trong phần Tích hợp Webhook => Kiểu chứng thực: API Key
```

## 📝 Các bước thực hiện (Step by Step)

### 1. Thêm tài khoản ngân hàng (Bank Account)
Thông tin này dùng để sinh mã QR hoặc đối soát giao dịch ngân hàng.

1. Đăng nhập [SePay](https://my.sepay.vn).
2. Vào menu **"Tài khoản ngân hàng"** > Nhấn **"Thêm tài khoản ngân hàng"**.
3. Điền Ngân hàng, Số tài khoản. Hệ thống thường tự động kiểm tra Tên tài khoản.
4. Lấy thông tin điền vào `.env`:
   - `SEPAY_BANK_NAME`: Cần dùng Tên viết tắt hoặc Mã Bin (VD: `MBBank`, `Vietcombank`, `Techcombank`).
   - `SEPAY_ACCOUNT_NUMBER`: Số tài khoản của bạn.
   - `SEPAY_ACCOUNT_NAME`: Tên hiển thị trên tài khoản.

### 2. Cấu hình Webhook & Lấy API Key (`SEPAY_WEBHOOK_API_KEY`)
Webhook giúp SePay "bắn" thông báo về server khi có người chuyển khoản thành công.

1. Vào menu **"Tích hợp Webhook"** > Nhấn **"Thêm Webhook"**.
2. Cấu hình các mục như sau:
   - **Tên:** Đặt tên tuỳ ý (VD: `LMS System Webhook`).
   - **(1) Chọn sự kiện:** Bắn WebHooks khi > Chọn `Có tiền vào`.
   - **(2) Chọn điều kiện:** 
     - Chọn tài khoản ngân hàng đã thêm ở bước 1.
     - Bỏ qua nếu nội dung giao dịch không có Code? > Chọn `Không` (Server sẽ tự bóc tách).
   - **(3) Thuộc tính WebHooks:**
     - **Gọi đến URL:** Điền đường dẫn Webhook xử lý của Backend (VD: `https://<ngrok-url>/api/webhooks/sepay` khi local, hoặc `https://domain.com/api/webhooks/sepay`).
     - **Là WebHooks xác thực thanh toán?**: Chọn `Không`.
     - **Gọi lại Webhooks khi?**: Tích chọn thẻ `HTTP Status Code không nằm trong phạm vi từ 200 đến 299` (Để Retry nếu server bị lỗi tạm thời).
   - **(4) Cấu hình chứng thực WebHooks (BẮT BUỘC):**
     - **Kiểu chứng thực:** Chọn `API Key` (hoặc `Bearer Token`).
     - **Giá trị:** 1 chuỗi mật khẩu tự sinh ra ngẫu nhiên hoặc bạn có thể tự chọn. _(Bạn sẽ copy chuỗi này vào `.env`)_
     - **Request Content type:** `application/json`.
   - **Trạng thái:** `Kích hoạt`
3. Nhấn **"Thêm / Lưu"**.
4. Copy chuỗi giá trị ở mục (4) dán vào biến `SEPAY_WEBHOOK_API_KEY` trong file `.env`.

### Tại sao không có `SEPAY_API_TOKEN`?
Hiện tại, mô hình tạo QR tĩnh (VietQR) và nhận kết quả thanh toán từ SePay qua Webhook sẽ **không cần đến** API Key gọi ngược lên hệ thống SePay (`SEPAY_API_TOKEN`). Mã QR có thể tự gen thông qua các thông tin gốc (Số tài khoản, ngân hàng, tên người nhận, số tiền) và chỉ cần `SEPAY_WEBHOOK_API_KEY` để kiểm tra auth lúc gửi Webhook đến server của chúng ta là đủ bảo mật.

## ⚠️ Troubleshooting / Lưu ý

- **Webhook không hoạt động (Không ghi nhận thanh toán):**
  - Vào [Lịch sử Webhook trên my.sepay.vn] kiểm tra xem SePay có đang gửi đi không và HTTP Status Code đang trả về từ server của bạn là số mấy.
  - Test môi trường local thì phải có ứng dụng như Ngrok / LocalTunnel để chuyển public URL về localhost.
- **Lỗi hiển thị sai ngân hàng / Mã QR ra lỗi:** Hãy kiểm tra lại đúng `SEPAY_BANK_NAME` đã sử dụng *Tên viết tắt* chính thức trên SePay chưa, nếu bạn gõ nhầm (VD: `MB Bank` thay vì `MBBank`) hệ thống VietQR sẽ sinh sai hoặc không sinh được QR.
