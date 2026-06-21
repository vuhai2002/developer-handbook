# Hướng dẫn Cài đặt Email bằng Brevo API (Thay thế SMTP)

Do một số nhà cung cấp VPS (như DigitalOcean, Vultr, Linode) chặn mặc định các cổng SMTP (465, 587) để chống spam, việc gửi email thông qua giao thức SMTP thông thường (như Gmail SMTP) từ VPS sẽ bị thất bại (timeout hoặc connection refused).

Hướng dẫn này giúp bạn sử dụng **Brevo HTTP API v3** (giao tiếp qua HTTPS port 443, không bị chặn) để gửi email xác thực thay vì dùng port SMTP, đồng thời khắc phục lỗi hiển thị sai địa chỉ email người gửi.

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

1. **Đăng ký**: Tạo tài khoản miễn phí trên [Brevo](https://www.brevo.com/).
2. **Xác thực Email gửi**: Vào `Senders, Domains & Dedicated IPs` > `Senders` > Thêm Email gửi và bấm link xác nhận trong hộp thư.
3. **Lấy API Key**: Menu Profile > `SMTP & API` > **Tab `API keys & MCP`** > Nhấn `Generate a new API key` (mã có dạng `xkeysib-...`). KHÔNG lấy SMTP key.
4. **Xác thực Domain (Nếu dùng email tên miền riêng)**: Vào Tab `Domains` > Thêm domain > Khai báo 3 bản ghi DNS: `TXT (DKIM)`, `TXT (SPF)` và `CNAME (Return-Path)`.
5. **Cấu hình app**: Cập nhật `.env` với các thông số API Key sinh ra ở bước 3. Khởi động lại Docker (`docker compose down` & `docker compose up -d --build`).

---

## 📝 Các bước thực hiện (Step by Step)

### Bước 1: Đăng ký tài khoản Brevo

Brevo có gói miễn phí vĩnh viễn cho phép gửi 300 email/ngày (rất dư dả cho việc gửi OTP/xác thực tài khoản).

1. Truy cập trang chủ: **[brevo.com](https://www.brevo.com/)**
2. Bấm vào **Sign up free** ở góc phải trên.
3. Đăng ký bằng Google cho nhanh hoặc đăng ký bằng email bình thường.
4. Điền các thông tin cá nhân/công ty mà họ yêu cầu (không bắt buộc thẻ tín dụng).

### Bước 2: Xác thực Người Gửi (Verify Sender Email)

> ⚠️ **QUAN TRỌNG**: Brevo KHÔNG cho phép gửi email bằng API nếu bạn chưa chứng minh bạn là chủ sở hữu của địa chỉ email gửi đi.

1. Tại Dashboard Brevo, nhìn menu bên phải dưới cùng (hoặc góc trên phải), vào phần **Senders, Domains & Dedicated IPs**.
2. Chọn tab **Senders**.
3. Bấm nút **Add a sender** (Thêm người gửi).
4. Nhập thông tin:
   - **From Name**: (Ví dụ: `Kho Tàng Chánh Pháp`, `Video Streaming Admin`)
   - **From Email**: (Địa chỉ email sẽ gửi thư, ví dụ: `anhtrangchung@gmail.com` hoặc `admin@cesglobal.com.vn`)
5. Mở hòm thư của bạn, tìm email từ Brevo và nhấp vào nút/link **Verify** để xác minh thư.
6. Đảm bảo trạng thái của Sender trên Brevo chuyển thành **Active/Verified**.

### Bước 3: Xác thực Tên miền (Domain Verification)

Nếu bạn dùng email theo tên miền riêng (VD: `admin@cesglobal.com.vn`), lúc gửi thư khách hàng thường sẽ thấy người gửi là một email lạ như: `admin@10716263.brevosend.com` thay vì email chính xác của bạn. 

**Lý do:** Sender domain chưa verify nên Brevo tự động route email qua domain phụ của họ để không bị rớt vào Spam. 

**Cách khắc phục:**
1. Vào `Settings > Senders & Domains` (hoặc Dashboard tương tự).
2. Bấm **Add a domain** > Nhập tên miền (ví dụ: `cesglobal.com.vn`).
3. Brevo yêu cầu bạn thêm 3 bản ghi (Records) này vào mục quản lý DNS của tên miền (Cloudflare, MatBao, Tenten,...):

| Loại | Tên (Host/Name) | Mục đích |
| :--- | :--- | :--- |
| **TXT** (DKIM) | `mail._domainkey.tenmien.com` | Xác thực email là của bạn |
| **TXT** (SPF) | `tenmien.com` | Cho phép Brevo gửi email thay bạn |
| **CNAME** (Return-Path) | `xxxxxx.tenmien.com` | Tracking bounces (theo dõi thư trả về) |

4. Cấu hình DNS xong, quay lại Brevo bấm **Verify**. Chờ vài phút (hoặc tối đa vài giờ) để DNS cập nhật.
5. Sau khi thành công, bạn thêm lại sender `admin@tenmien.com` như Bước 2. Thư sẽ hiển thị chuẩn `admin@tenmien.com` và không bị bay vào Spam.

### Bước 4: Lấy khóa HTTP API (API Key)

> ⚠️ **CẢNH BÁO LỚN**: Brevo có 2 loại key là **SMTP key** và **API key**. Bạn **BẮT BUỘC PHẢI LẤY API KEY**. 
> - ❌ Key sai: Bắt đầu bằng `***` và kết thúc bằng vài chữ cái ngắn (đây là SMTP password).
> - ✅ Key ĐÚNG: Cực kỳ dài và luôn bắt đầu bằng chữ `xkeysib-`.

1. Nhấp vào Profile ở góc trên bên phải trang Brevo, chọn **SMTP & API**.
2. Ở màn hình này, bạn sẽ thấy 2 tab: "SMTP" và "API keys & MCP".
3. **CHỌN TAB `API keys & MCP`**.
4. Bấm nút **Generate a new API key**.
5. Đặt tên gợi nhớ (ví dụ: `website-prod-api`).
6. Bấm **Generate**.
7. **Copy ngay lập tức** chuỗi mã này (`xkeysib-...`). *Lưu ý: Mã này chỉ hiện lên 1 lần duy nhất.*

### Bước 5: Cấu hình ứng dụng (.env)

Sau khi có đủ thông tin, trên máy chủ VPS (hoặc máy local), mở file `.env` và cập nhật cấu hình:

```env
# 1. Bật chế độ sử dụng HTTP API (brevo) thay cho SMTP truyền thống
Email__Provider=brevo

# 2. Dán mã xkeysib- vừa lấy được ở Bước 4 vào đây
Email__BrevoApiKey=xkeysib-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 3. Điền CHÍNH XÁC email đã verify ở Bước 2
Email__SenderEmail=anhtrangchung@gmail.com

# 4. Tên hiển thị người gửi (Nên khớp với From Name ở Bước 2)
Email__SenderName=Kho Tàng Chánh Pháp
```

**Khởi động lại ứng dụng Docker:**
```bash
docker compose down
docker compose up -d --build
```

---

## ⚠️ Troubleshooting / Xử lý sự cố thường gặp

- **Frontend báo lỗi (xoay vòng) & Log backend báo "Unauthorized":**
  - Do bạn copy dán nhầm *SMTP password* thay vì *API Key* của Brevo. Xem lại Bước 4 để đảm bảo lấy đúng khóa bắt đầu bằng `xkeysib-`.
- **Log báo API thành công (201 Created) nhưng KHÔNG nhận được thư:**
  - Do bạn chưa thực hiện Bước 2 (Xác thực Sender Email) nên Brevo chặn. 
  - Cũng có thể do thư bị bộ lọc kiểm duyệt của Brevo quét (nghi ngờ spam/phishing). Bạn vào Email Log trên Brevo Dashboard để xem kết quả chi tiết.
- **Thư vào mục Spam/Thư rác:**
  - Nếu gửi lần đầu, hộp thư (như Gmail) chưa "quen". Hãy bảo khách hàng mở hộp thư rác và đánh dấu **Not spam / Báo cáo không phải thư rác** vài lần để tăng độ uy tín (Deliverability).
  - Và hãy chắc chắn đã cấu hình DNS DKIM/SPF ở Bước 3!
- **Thư hiển thị sai email gửi dạng `admin@...brevosend.com`:**
  - Bạn chưa xác thực Domain (Bước 3). Bạn phải xác thực domain trong trang Brevo để có thể sử dụng địa chỉ email xịn.
