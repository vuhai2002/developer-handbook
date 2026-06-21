# Clone PostgreSQL Database từ VPS về Local (Windows)

Hướng dẫn này giúp bạn tạo bản sao (clone) database PostgreSQL từ VPS về máy dev local trên Windows, bao gồm cả schema lẫn data, thông qua SSH Tunnel.

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

**Điều kiện:** PostgreSQL local dùng port khác (ví dụ 5433) để không xung đột với SSH tunnel (5432).

```powershell
# 1. Đổi port PostgreSQL local sang 5433 (trong postgresql.conf, bỏ dấu # và sửa)
#    port = 5433
# Sau đó restart service:
net start PostgreSQL-17

# 2. Tạo database local
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -p 5433 -U postgres -c "CREATE DATABASE litespace_test;"

# 3. Mở SSH tunnel (giữ terminal này mở)
ssh -L 5432:localhost:5432 user@your-vps-ip -i ~/.ssh/your_key -N

# 4. Dump từ VPS qua tunnel (terminal khác)
& "C:\Program Files\PostgreSQL\17\bin\pg_dump.exe" -h localhost -p 5432 -U litespace -d litespace -F c -f D:\litespace_dump.backup

# 5. Restore vào local
& "C:\Program Files\PostgreSQL\17\bin\pg_restore.exe" -h localhost -p 5433 -U postgres -d litespace_test -F c D:\litespace_dump.backup

# 6. Kiểm tra kết quả
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -p 5433 -U postgres -d litespace_test -c "\dt"
```

---

## 📝 Các bước thực hiện (Step by Step)

### Bước 1: Tìm đường dẫn data thực tế của PostgreSQL

PostgreSQL trên Windows có thể cài ở nhiều vị trí khác nhau. Dùng Registry để tìm chính xác:

```powershell
reg query "HKLM\SYSTEM\CurrentControlSet\Services\PostgreSQL-17" /v ImagePath
```

Kết quả sẽ hiện đường dẫn tương tự:
```
ImagePath    REG_EXPAND_SZ    "C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe" runservice -N "PostgreSQL-17" -D "D:\Software\PostgreSQL\17\data" -w
```

Phần `-D "..."` chính là thư mục `data`. Ở ví dụ trên là `D:\Software\PostgreSQL\17\data`.

### Bước 2: Đổi port PostgreSQL local

Cần đổi port vì SSH tunnel đang chiếm port 5432. Mở file config với Notepad (chạy **as Administrator**):

```
notepad "D:\Software\PostgreSQL\17\data\postgresql.conf"
```

Tìm dòng `port` và sửa (chú ý **bỏ dấu `#`** nếu có):

```conf
# Trước (bị comment, không có tác dụng):
#port = 5432

# Sau (đã bỏ comment và đổi port):
port = 5433
```

Lưu file rồi restart service:

```powershell
# Stop rồi start lại
net stop PostgreSQL-17
net start PostgreSQL-17
```

### Bước 3: Tạo database trên local

```powershell
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -p 5433 -U postgres -c "CREATE DATABASE litespace_test;"
```

### Bước 4: Mở SSH tunnel

Mở một terminal riêng và **giữ nó mở** trong suốt quá trình dump:

```powershell
ssh -L 5432:localhost:5432 litespace@14.225.220.160 -i ~/.ssh/id_ed25519_litespace -N
```

Lúc này, `localhost:5432` trên máy bạn = PostgreSQL đang chạy trên VPS.

### Bước 5: Dump database từ VPS

Mở terminal **khác** (không đóng terminal SSH):

```powershell
& "C:\Program Files\PostgreSQL\17\bin\pg_dump.exe" -h localhost -p 5432 -U litespace -d litespace -F c -f D:\litespace_dump.backup
```

- `-F c`: custom format (nén, restore nhanh hơn plain SQL)
- `-f`: đường dẫn file output
- Nhập password khi được hỏi

### Bước 6: Restore vào database local

```powershell
& "C:\Program Files\PostgreSQL\17\bin\pg_restore.exe" -h localhost -p 5433 -U postgres -d litespace_test -F c D:\litespace_dump.backup
```

### Bước 7: Kiểm tra kết quả

```powershell
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -p 5433 -U postgres -d litespace_test -c "\dt"
```

Lệnh này liệt kê tất cả bảng — nếu hiện ra danh sách bảng là restore thành công.

Connection string để dùng trong app:
```
postgresql://postgres:<your_local_password>@localhost:5433/litespace_test
```

---

## ⚠️ Troubleshooting / Lưu ý

### Lỗi: `role "litespace" does not exist`

```
pg_restore: error: could not execute query: ERROR:  role "litespace" does not exist
Command was: ALTER SCHEMA drizzle OWNER TO litespace;
```

**Nguyên nhân:** File backup chứa lệnh gán ownership cho role `litespace`, nhưng role này không tồn tại trên máy local.

**Giải pháp:** Lỗi này **không nghiêm trọng** — data và schema đã được restore thành công. Ownership chỉ đơn giản là thuộc về `postgres`. Bạn có thể dùng bình thường.

Nếu muốn ownership đúng như VPS, tạo role trước rồi restore lại:

```powershell
# Tạo role litespace trên local
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -p 5433 -U postgres -c "CREATE ROLE litespace WITH LOGIN PASSWORD 'pass' SUPERUSER;"

# Restore lại (--clean để drop objects cũ trước)
& "C:\Program Files\PostgreSQL\17\bin\pg_restore.exe" -h localhost -p 5433 -U postgres -d litespace_test --clean -F c D:\litespace_dump.backup
```

### Lỗi: `port = 5433` không có tác dụng

Kiểm tra xem dòng có bị comment không. Dòng có dấu `#` ở đầu là bị vô hiệu hóa:

```conf
# Không có tác dụng (bị comment):
#port = 5433

# Có tác dụng:
port = 5433
```

### Không tìm thấy thư mục log

Nếu `D:\Software\PostgreSQL\17\data\log` không tồn tại, nghĩa là PostgreSQL chưa start thành công lần nào. Thử start thủ công để xem lỗi:

```powershell
& "C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe" start -D "D:\Software\PostgreSQL\17\data" -l "D:\Software\PostgreSQL\17\data\startup.log"
notepad "D:\Software\PostgreSQL\17\data\startup.log"
```
