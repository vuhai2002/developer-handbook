# Hướng Dẫn Cấu Hình Trang Bảo Trì (Maintenance Page) Tự Động Với Caddy Docker

Khi bạn triển khai ứng dụng bằng Docker và dùng Caddy làm Reverse Proxy, mỗi khi bạn chạy `docker compose up --build` hoặc khởi động lại container, ứng dụng sẽ có một khoảng thời gian downtime ngắn. Trong lúc này, nếu người dùng truy cập, Caddy không thể kết nối đến container (upstream) và sẽ trả về lỗi **`502 Bad Gateway`** mặc định (trắng xoá, rất xấu).

Hướng dẫn này giúp bạn "đánh chặn" lỗi 502 đó và tự động hiển thị một trang HTML bảo trì (Maintenance Page) chuyên nghiệp. Khi container chạy xong, Caddy sẽ tự động chuyển hướng lại vào ứng dụng chính bình thường.

## 🌟 Điểm lợi của kiến trúc này

1. **Chuyên nghiệp hóa trải nghiệm người dùng (UX):** Người dùng sẽ biết hệ thống đang nâng cấp, tránh ấn tượng xấu hoặc tưởng nhầm website đã "sập".
2. **Quản lý tập trung một chỗ:** Toàn bộ file cấu hình Caddy, file HTML bảo trì và `docker-compose.yml` đều nằm gọn trong thư mục `~/services/caddy`, cực kỳ gọn gàng, thuận tiện cho việc backup cấu hình (ví dụ: lên GitHub) hoặc di chuyển nguyên cụm sang VPS khác.
3. **Automated Recovery (Tự phục hồi):** Không cần phải bật/tắt trang bảo trì tính năng theo kiểu thủ công (như ở Nginx cũ). Caddy liên tục tự retry proxy; ngay khi Docker build xong và container khả dụng lại, lỗi 502 tự biến mất và Caddy nối request về lại website một cách tự động và mượt mà.
4. **Tối ưu tài nguyên:** Không cần cấu hình các giải pháp Blue-Green Deployment tốn kém bộ nhớ VPS, hoàn toàn phù hợp với các ứng dụng nhỏ hoặc ứng dụng chịu được khoảng thời gian downtime bảo trì ngắn.

---

## 🛠️ Step-by-Step Cấu Hình (Dành cho Caddy chạy bằng Docker)

Kiến trúc thư mục Caddy dự kiến trên máy chủ của bạn sẽ như sau:
```text
~/services/caddy/
├── docker-compose.yml
├── Caddyfile
└── maintenance/
    └── maintenance.html
```

### Bước 1: Tạo trang HTML Bảo trì độc lập
Trang bảo trì cần là một trang **HTML tĩnh độc lập** vì lúc này App Server (ví dụ Next.js, API) đang tắt.

Đầu tiên, tạo thư mục chứa trang bảo trì nằm chung ngay trong thư mục cấu hình Caddy (giữ nguyên tắc quản lý tập trung):
```bash
mkdir -p ~/services/caddy/maintenance
```

Tiếp theo, tạo file `maintenance.html` (Xem code mẫu HTML ở cuối trang để copy dán vào):
```bash
sudo nano ~/services/caddy/maintenance/maintenance.html
```

### Bước 2: Mount thư mục maintenance vào container Caddy
Bởi vì Caddy đang chạy trong một container Docker phân lập, nó sẽ không thể nhìn ra thư mục ở bên ngoài Host OS. Do đó ta cần cấu hình mount (gắn) thư mục đó vào trong container.

Mở file `docker-compose.yml` của Caddy lên:
```bash
nano ~/services/caddy/docker-compose.yml
```

Tìm đến phần `volumes` của dịch vụ `caddy` và thêm dòng mount thư mục `maintenance`:
```yaml
services:
  caddy:
    image: caddy:latest # hoặc alpine tùy bạn đang dùng
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      # 👇 Dòng cực kỳ quan trọng: Gắn thư mục host vào root folder của Caddy
      - ./maintenance:/var/www/maintenance
      - caddy_data:/data
      - caddy_config:/config
```

### Bước 3: Cấu hình Caddy đánh chặn lỗi 502
Mở file `Caddyfile`:
```bash
nano ~/services/caddy/Caddyfile
```

Thêm biến khối `handle_errors` vào bên trong block domain của bạn. Ở đây lấy ví dụ cấu hình hoàn chỉnh cho `your-domain.com`:
```caddyfile
your-domain.com {
    # 1. Chuyển hướng traffic bình thường vào Docker App (Frontend/API) của bạn
    reverse_proxy my-app-container:3000

    # 2. Block này sẽ xử lý các lỗi trả ra từ reverse_proxy hoặc Caddy
    handle_errors {
        # Bắt riêng lỗi 502 (Bad Gateway - Upstream timeout, down reserting)
        @502 {
            expression {err.status_code} == 502
        }
        
        # Nếu đã bắt trúng lỗi 502, hãy thực thi khối lệnh xử lý trả về file tĩnh sau:
        handle @502 {
            # Báo cho Caddy trỏ đến thư mục tĩnh đã tạo lúc nãy
            root * /var/www/maintenance
            # Điều hướng tất cả request lỗi url về đúng file html này
            rewrite * /maintenance.html
            # Caddy đóng vai trò làm File Server trả file cho client
            file_server
        }
    }
}
```

### Bước 4: Khởi động lại Caddy để Update Volume Mount
Do ta vừa sửa file `docker-compose.yml` (để mount Volume mới), bạn cần Restart hoàn toàn Caddy container thay vì chỉ gõ lệnh cấu hình reload mềm như thông thường.

```bash
cd ~/services/caddy
docker compose up -d caddy
# Hoặc an toàn hơn: docker compose down && docker compose up -d
```

### Bước 5: Kiểm thử (Test) Trang Bảo Trì
Giờ bạn có thể giả lập bảo trì trên Host OS theo các bước:
1. Dừng ứng dụng chính (Ví dụ FrontEnd): `docker compose stop my-app-container`.
2. Truy cập trình duyệt để refresh trang: Web sẽ không hiển thị 502 mặc định nữa, mà hiện trang HTML Bảo trì màu sắc đúng nhận diện thiết kế bạn làm.
3. Kích lại ứng dụng bằng câu lệnh: `docker compose up -d`. Vài giây sau refresh lại, web lại hoạt động bình thường! 🎉

---

### Mẫu mã nguồn `maintenance.html` (Sử dụng Tailwind CDN)
Để web vẫn đẹp cả khi đang bảo trì, bạn copy đoạn code html sau vào file `maintenance.html`:

```html
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đang Bảo Trì Hệ Thống</title>
    <!-- Trỏ Tailwind thông qua CDN để load styles siêu tiện -->
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@300;400;500;600;700&display=swap');
        body { font-family: 'Be Vietnam Pro', sans-serif; background-color: #FAFAFA; }
        .text-primary { color: #D4AF37; }
        .bg-primary { background-color: #D4AF37; }
        .halo-effect { box-shadow: 0 0 50px rgba(212, 175, 55, 0.15); }
    </style>
</head>
<body class="min-h-screen flex items-center justify-center p-4">
    <div class="max-w-2xl w-full bg-white rounded-2xl shadow-sm border border-gray-100 p-8 md:p-12 text-center halo-effect">
        <!-- Logo hoạ tiết tuỳ biến dự án -->
        <div class="flex justify-center mb-8">
            <svg class="w-16 h-16 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 2v20m-9.6-9.6l19.2 0m-17.5-6.5l15.8 13.1m-15.8 0l15.8-13.1 M12 22c5.522 0 10-4.478 10-10S17.522 2 12 2 2 6.478 2 12s4.478 10 10 10z"></path>
            </svg>
        </div>
        <h1 class="text-3xl md:text-3xl font-bold text-gray-800 mb-4 tracking-tight">
            Hệ Thống Đang Trải Qua Nâng Cấp
        </h1>
        <p class="text-gray-500 mb-2 font-medium">(System is under maintenance)</p>
        <div class="h-px bg-gray-100 w-24 mx-auto my-6"></div>
        <div class="space-y-4 text-gray-600">
            <p>Hệ thống hiện đang bảo trì tự động và cập nhật dữ liệu. Xin vui lòng chờ, mọi dịch vụ dự kiến sẽ hoạt động lại trong vòng một vài phút nữa.</p>
        </div>
        <div class="mt-10">
            <button onclick="window.location.reload()" class="bg-primary hover:bg-[#C5A030] text-white font-medium py-3 px-8 rounded-full transition duration-300 shadow-md">
                Tải Lại Trang (Reload Page)
            </button>
        </div>
    </div>
</body>
</html>
```
