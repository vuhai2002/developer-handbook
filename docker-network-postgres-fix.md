# Fix Lỗi Docker Container Không Kết Nối Được PostgreSQL Trên VPS

> **Nguyên nhân:** Docker tự động thay đổi dải IP mạng (dynamic allocation) mỗi khi bạn `docker-compose down` và `up` lại, khiến PostgreSQL từ chối kết nối vì IP mới không nằm trong danh sách được phép.

---

## Mục lục

1. [Tại sao Docker lại đổi IP?](#1-tại-sao-docker-lại-đổi-ip)
2. [Chẩn đoán: Tìm IP và Tên mạng hiện tại](#2-chẩn-đoán-tìm-ip-và-tên-mạng-hiện-tại)
3. [Xem dải mạng (Subnet) và Gateway](#3-xem-dải-mạng-subnet-và-gateway)
4. [Mở Firewall (UFW)](#4-mở-firewall-ufw)
5. [Cập nhật cấu hình PostgreSQL](#5-cập-nhật-cấu-hình-postgresql)
6. [Test lại](#6-test-lại)
7. [Giải pháp Silver Bullet (Khuyến nghị)](#7-giải-pháp-silver-bullet-khuyến-nghị)

---

## 1. Tại sao Docker lại đổi IP?

Hãy tưởng tượng Docker quản lý mạng giống như việc xếp phòng trong khách sạn:

- **Lần đầu chạy:** Bạn chạy `docker-compose up` cho dự án Video Streaming. Docker thấy "Phòng 1" (`172.17.x.x`) đang trống → Nó cấp cho dự án của bạn.
- **Lần sau:**
  1. Bạn cài thêm một dự án khác (ví dụ: `my-blog`). Dự án này chiếm "Phòng 1" (`172.17.x.x`).
  2. Sau đó bạn chạy lại dự án Video Streaming (`docker-compose up`).
  3. Docker thấy "Phòng 1" đã có người ở → Nó **tự động** đẩy dự án sang "Phòng 2" (`172.18.x.x`) hoặc "Phòng 3" (`172.19.x.x`).

**Hậu quả:** Lúc trước bạn cấu hình Postgres chỉ cho phép "Phòng 1" (`172.17.0.1`) truy cập. Giờ dự án bị đẩy sang "Phòng 2" (`172.18.0.1`), Postgres sẽ thấy IP lạ và chặn ngay lập tức → **Lỗi kết nối xuất hiện.**

---

## 2. Chẩn đoán: Tìm IP và Tên mạng hiện tại

Chạy lệnh sau để xem container đang nhận IP nào và thuộc mạng nào (thay `videostreaming-api` bằng tên container của bạn):

```bash
# Nếu đã cài jq (đẹp hơn)
docker inspect -f '{{json .NetworkSettings.Networks}}' videostreaming-api | jq .

# Nếu chưa cài jq (dùng grep)
docker inspect videostreaming-api | grep -A 20 "Networks"
```

👉 **Bạn cần tìm 2 thông tin:**

| Thông tin | Ví dụ |
|---|---|
| **Network Name** | `dotnetapi-video-streaming_default` |
| **IPAddress** | `172.19.0.2` |

---

## 3. Xem dải mạng (Subnet) và Gateway

Sau khi có **Tên mạng** ở bước 2, chạy lệnh sau để xem cấu trúc của mạng đó:

```bash
# Thay tên mạng bằng tên bạn tìm được ở bước 2
docker network inspect dotnetapi-video-streaming_default
```

Kết quả trả về sẽ có đoạn `Config` như này:

```json
"Config": [
    {
        "Subnet": "172.18.0.0/16",
        "Gateway": "172.18.0.1"
    }
]
```

> **Lưu ý:** `Gateway` chính là địa chỉ IP mà container dùng để kết nối ra ngoài (bao gồm kết nối tới PostgreSQL trên host).

---

## 4. Mở Firewall (UFW)

Chạy lệnh này trên VPS để UFW cho phép dải mạng Docker đi qua cổng PostgreSQL (5432):

```bash
# Thay 172.21.0.0/16 bằng Subnet bạn tìm được ở bước 3
sudo ufw allow from 172.21.0.0/16 to any port 5432
sudo ufw reload
```

---

## 5. Cập nhật cấu hình PostgreSQL

### 5.1. Sửa `pg_hba.conf`

```bash
# Tìm file config (thường ở /etc/postgresql/14/main/ hoặc 16/main/)
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

Thêm dòng này vào cuối file (thay subnet cho phù hợp):

```
# Cho phép Docker container kết nối tới PostgreSQL
host    all             all             172.21.0.0/16           scram-sha-256
```

> **Lưu ý:** Nếu bạn dùng xác thực `md5` thì đổi `scram-sha-256` thành `md5`. Kiểm tra trong log lỗi để biết bạn đang dùng loại nào.

### 5.2. Kiểm tra `postgresql.conf`

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

Tìm dòng `listen_addresses`:
- Nếu đã để `listen_addresses = '*'` → **Không cần sửa gì.**
- Nếu đang liệt kê từng IP → Bắt buộc phải thêm Gateway của Docker vào danh sách (ví dụ: `,172.21.0.1`).

### 5.3. Restart PostgreSQL

```bash
sudo systemctl restart postgresql
```

---

## 6. Test lại

Sau khi restart PostgreSQL, restart lại container API:

```bash
docker restart videostreaming-api
```

Kiểm tra log để xác nhận kết nối thành công:

```bash
docker logs videostreaming-api --tail 50
```

---

## 7. Giải pháp Silver Bullet (Khuyến nghị)

> **Vấn đề với cách fix ở trên:** Mỗi lần `docker-compose down` và `up` lại, Docker có thể đổi sang dải mạng khác (ví dụ `172.22.x.x`). Bạn sẽ phải lặp lại toàn bộ các bước trên.

**Giải pháp tối ưu:** Mở quyền truy cập cho **toàn bộ dải IP mà Docker có thể sử dụng** một lần duy nhất.

### Cơ sở lý thuyết

Theo chuẩn mạng RFC 1918, Docker được phép sử dụng dải IP Private Class B:
- Từ `172.16.0.0` đến `172.31.255.255`
- Viết gọn theo CIDR: **`172.16.0.0/12`**

Khi cấu hình cho phép `172.16.0.0/12`:

| Docker cấp IP | Kết quả |
|---|---|
| `172.17.0.1` | ✅ OK (Nằm trong dải) |
| `172.21.0.1` | ✅ OK (Nằm trong dải) |
| `172.30.0.1` | ✅ OK (Nằm trong dải) |

### Cách thực hiện Silver Bullet

#### Bước 1: Sửa `pg_hba.conf`

```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

Thêm dòng sau (hoặc thay thế dòng cũ):

```
# Silver Bullet: Cho phép bất kỳ IP nào thuộc dải Docker (172.16.x.x -> 172.31.x.x)
host    all             all             172.16.0.0/12           scram-sha-256
```

#### Bước 2: Mở Firewall UFW

```bash
sudo ufw allow from 172.16.0.0/12 to any port 5432
sudo ufw reload
```

#### Bước 3: Restart PostgreSQL

```bash
sudo systemctl restart postgresql
```

#### Bước 4: Cập nhật Connection String trong code

Connection String vẫn phải dùng đúng IP Gateway của mạng Docker hiện tại. Gateway luôn là `.1` của subnet:

| Subnet Docker | Host trong Connection String |
|---|---|
| `172.18.x.x` | `172.18.0.1` |
| `172.21.x.x` | `172.21.0.1` |

> **Mẹo nâng cao:** Để không bao giờ phải sửa Connection String, bạn có thể dùng `host.docker.internal` (trên Mac/Windows) hoặc cấu hình `extra_hosts` trong `docker-compose.yml` để map một tên cố định vào Gateway. Tuy nhiên, trên Linux VPS, dùng IP Gateway trực tiếp là cách đơn giản và hiệu quả nhất.

---

## Tóm tắt nhanh

```bash
# 1. Tìm tên mạng và IP của container
docker inspect videostreaming-api | grep -A 20 "Networks"

# 2. Xem subnet và gateway
docker network inspect <tên-mạng>

# 3. Mở firewall (Silver Bullet - làm 1 lần duy nhất)
sudo ufw allow from 172.16.0.0/12 to any port 5432
sudo ufw reload

# 4. Sửa pg_hba.conf - thêm dòng:
# host    all    all    172.16.0.0/12    scram-sha-256

# 5. Restart PostgreSQL
sudo systemctl restart postgresql

# 6. Restart container
docker restart videostreaming-api
```

---

*Tài liệu này được tạo ngày 2026-02-18. Áp dụng cho PostgreSQL 14/16 trên Ubuntu/Debian VPS với Docker.*
