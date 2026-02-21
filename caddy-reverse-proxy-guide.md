# Hướng Dẫn Cài Đặt Caddy Reverse Proxy Cho VPS Mới

Hướng dẫn này giúp bạn thiết lập Caddy làm Reverse Proxy trên một VPS mới sử dụng Docker. Caddy nổi bật với khả năng **tự động cấp phát và gia hạn chứng chỉ SSL (HTTPS)** mà gần như không cần cấu hình phức tạp (Zero-config SSL).

## Tại sao chọn Caddy?
- Tự động lấy chứng chỉ SSL từ Let's Encrypt / ZeroSSL.
- Cấu hình file cực kỳ ngắn gọn và dễ hiểu.
- Hỗ trợ reload cấu hình không làm gián đoạn dịch vụ (Zero-downtime).

---

## Phần 1: Các bước cài đặt Caddy ban đầu

### Bước 1: Tạo thư mục chứa cấu hình Caddy
Việc nhóm các file cấu hình vào cùng một thư mục giúp bạn dễ dàng quản lý, chỉnh sửa và sao lưu sau này.

```bash
mkdir -p ~/services/caddy
cd ~/services/caddy
```

### Bước 2: Tạo mạng lưới (Network) dùng chung cho Docker
Để Caddy có thể "nhìn thấy" và chuyển tiếp (proxy) traffic đến các container khác, tất cả chúng cần nằm trên cùng một network. Ta sẽ tạo một network tên là `caddy-net` (hoặc bạn có thể dùng `nginx-proxy` như trước đây để tương thích ngược).

```bash
docker network create caddy-net
```

### Bước 3: Khởi tạo file cấu hình `Caddyfile`
`Caddyfile` là nơi bạn sẽ khai báo các domain và dịch vụ tương ứng.

```bash
cat > ~/services/caddy/Caddyfile << 'EOF'
# =============================================
# Caddy Reverse Proxy Configuration
# =============================================
# Chỉ cần khai báo domain, Caddy sẽ tự lo phần SSL!

# Ví dụ 1: Proxy đến một Next.js app
# app.yourdomain.com {
# 	reverse_proxy my-nextjs-container:3000
# }

# Ví dụ 2: Proxy đến một API backend
# api.yourdomain.com {
# 	reverse_proxy my-backend-api:8080
# }
EOF
```
*Lưu ý: Bạn thay `yourdomain.com` và tên container thành app thực tế của bạn khi cần.*

### Bước 4: Tạo `docker-compose.yml` cho Caddy
File này định nghĩa container Caddy, các cổng mạng (ports) cần mở và cấu hình các thư mục cần lưu trữ (volumes). Việc lưu trữ `caddy_data` rất quan trọng để không bị mất chứng chỉ SSL mỗi khi khởi động lại (tránh lỗi Rate Limit của Let's Encrypt).

```yaml
cat > ~/services/caddy/docker-compose.yml << 'EOF'
services:
  caddy:
    image: caddy:2-alpine
    container_name: caddy-proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp" # Bắt buộc mở udp port 443 nếu muốn hỗ trợ HTTP/3
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - caddy-net

volumes:
  caddy_data:
  caddy_config:

networks:
  caddy-net:
    external: true
EOF
```

### Bước 5: Khởi động hệ thống Caddy
Trước khi bật Caddy, hãy chắc chắn rằng VPS của bạn không có dịch vụ nào khác đang chiếm cổng `80` và `443` (Ví dụ: Nginx, Apache, hay proxy cũ).

Nếu đang chạy Nginx Proxy Manager, hãy tắt nó để giải phóng port:
```bash
docker stop nginx-proxy-manager-app-1
```

Khởi động Caddy:
```bash
cd ~/services/caddy
docker compose up -d
```

Để kiểm tra xem Caddy đã chạy ổn chưa và đã xin được SSL thành công chưa, bạn có thể xem logs của Caddy:
```bash
docker compose logs -f
```
*(Bấm `Ctrl+C` để thoát xem logs khi thấy log báo "certificate obtained successfully").*

---

## Phần 2: Workflow Thêm Một Ứng Dụng / Domain Mới

Mỗi khi bạn có một ứng dụng mới (ví dụ dịch vụ chạy trên port 3000 bằng Docker), bạn chỉ cần làm theo 3 bước chuẩn sau:

### 1️⃣ Kết nối container mới vào network của Caddy
Giả sử container của ứng dụng mới tên là `my-new-app`.
```bash
docker network connect caddy-net my-new-app
```
*Lưu ý: Tốt nhất là khai báo network `caddy-net` trực tiếp trong file `docker-compose.yml` của ứng dụng mới luôn để tự động bắt mạng khi khởi động lên.*

### 2️⃣ Cập nhật cấu hình vào `Caddyfile`
Mở file Caddyfile lên và thêm cấu hình domain mới:
```bash
nano ~/services/caddy/Caddyfile
```

Thêm khoảng cấu hình mới xuống dưới cùng:
```caddyfile
newapp.vuhai.me {
    reverse_proxy my-new-app:3000
}
```

### 3️⃣ Cập nhật lại Caddy (Cấu hình Zero Downtime)
Caddy hỗ trợ tính năng reload file cấu hình mà không cần phải khởi động lại (restart) container. Nghĩa là khách hàng đang truy cập hệ thống ở các hệ thống khác sẽ không hề biết, cũng không bị rớt mạng.

```bash
docker exec caddy-proxy caddy reload --config /etc/caddy/Caddyfile
```

**Xong!** 
Khi chạy lệnh này, Caddy sẽ tự nhận diện domain mới `newapp.vuhai.me`, tự động đi xin chứng chỉ SSL từ Let's Encrypt và bắt đầu chuyển tiếp requests ngay lập tức.
