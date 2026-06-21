# Kết nối Database qua SSH Tunnel (Local Dev) & Localhost (Production)

Hướng dẫn cách kết nối PostgreSQL trên VPS từ máy local bằng SSH Tunnel, và cấu hình `.env` cho từng môi trường (local / production).

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

**Local — SSH Tunnel:**

```bash
# Mở terminal riêng, giữ chạy suốt phiên làm việc
ssh -L 5432:localhost:5432 <user>@<vps-ip> -i ~/.ssh/<private-key> -N
```

```env
# .env.local
DATABASE_URL=postgresql://<db_user>:<password>@localhost:5432/<db_name>
```

**Production (deploy chung VPS):**

```env
# .env.production
DATABASE_URL=postgresql://<db_user>:<password>@localhost:5432/<db_name>
```

> Trên production, backend chạy cùng VPS với PostgreSQL nên dùng thẳng `localhost` — không cần SSH Tunnel.

---

## 📝 Các bước thực hiện (Step by Step)

### 1. Hiểu mô hình kết nối

```
┌──────────────────┐          SSH Tunnel           ┌──────────────────┐
│   Máy Local      │ ──── port 5432 ──────────────▶│   VPS            │
│   (dev machine)  │   ssh -L 5432:localhost:5432  │   PostgreSQL     │
│                  │                                │   :5432          │
└──────────────────┘                                └──────────────────┘
```

- **Local**: Máy dev không truy cập thẳng được DB trên VPS (port 5432 thường bị firewall chặn).
  → Dùng **SSH Tunnel** để "ánh xạ" port 5432 local → port 5432 VPS.
- **Production**: Backend deploy cùng VPS với DB → dùng `localhost` trực tiếp.

### 2. Tạo SSH Tunnel (dành cho Local Dev)

Mở một terminal riêng và chạy:

```bash
ssh -L 5432:localhost:5432 ssh_user@14.225.220.160 -i ~/.ssh/id_ed25519 -N
```

| Flag | Ý nghĩa |
|------|----------|
| `-L 5432:localhost:5432` | Forward port 5432 local → port 5432 trên VPS |
| `ssh_user@14.225.220.160` | User và IP của VPS |
| `-i ~/.ssh/id_ed25519` | Đường dẫn tới private key SSH |
| `-N` | Không mở shell, chỉ giữ tunnel |

> **Lưu ý:** Terminal này phải **giữ mở** trong suốt phiên làm việc. Đóng terminal = mất kết nối DB.

### 3. Cấu hình `.env.local` (Local Dev)

```env
DATABASE_URL=postgresql://db_user:<password>@localhost:5432/litespa
```

Vì SSH tunnel đã ánh xạ `localhost:5432` → VPS, backend sẽ kết nối DB bình thường như thể DB nằm trên máy local.

### 4. Cấu hình `.env.production` (Deploy chung VPS)

```env
DATABASE_URL=postgresql://db_user:<password>@localhost:5432/litespa
```

Khi backend deploy cùng VPS với PostgreSQL, `localhost` trỏ thẳng tới DB trên cùng máy — không cần tunnel hay IP công khai.

### 5. (Nâng cao) Chạy SSH Tunnel ở background

Nếu không muốn giữ terminal mở, có thể chạy tunnel ở background:

```bash
ssh -f -N -L 5432:localhost:5432 ssh_user@14.225.220.160 -i ~/.ssh/id_ed25519
```

| Flag | Ý nghĩa |
|------|----------|
| `-f` | Chạy ở background sau khi xác thực |
| `-N` | Không mở shell |

Để tắt tunnel background:

```bash
# Tìm PID
ps aux | grep "ssh -f -N -L"

# Kill process
kill <PID>
```

**Trên Windows (PowerShell):**

```powershell
# Tìm PID
Get-Process ssh | Where-Object { $_.CommandLine -like "*5432*" }

# Kill process
Stop-Process -Id <PID>
```

### 6. (Nâng cao) Xử lý trùng port

Nếu local đã có PostgreSQL chạy trên port 5432, dùng port khác:

```bash
ssh -L 5433:localhost:5432 ssh_user@14.225.220.160 -i ~/.ssh/id_ed25519 -N
```

Và cập nhật `.env.local`:

```env
DATABASE_URL=postgresql://db_user:<password>@localhost:5433/litespa
```

---

## ⚠️ Troubleshooting / Lưu ý

| Vấn đề | Nguyên nhân | Cách xử lý |
|---------|-------------|-------------|
| `Connection refused` trên local | SSH tunnel chưa chạy hoặc đã bị đóng | Kiểm tra terminal tunnel, chạy lại lệnh SSH |
| `Address already in use` | Port 5432 local đã bị chiếm (PostgreSQL local đang chạy) | Dùng port khác `-L 5433:localhost:5432` |
| `Permission denied (publickey)` | Sai đường dẫn key hoặc key chưa được add vào VPS | Kiểm tra `-i` path, đảm bảo public key có trong `~/.ssh/authorized_keys` trên VPS |
| `Network is unreachable` | VPS không online hoặc IP thay đổi | Kiểm tra ping tới VPS, xác nhận IP |
| Tunnel tự ngắt sau 1 thời gian | Server timeout do idle | Thêm `-o ServerAliveInterval=60` vào lệnh SSH |

**Giữ tunnel ổn định:**

```bash
ssh -L 5432:localhost:5432 ssh_user@14.225.220.160 \
  -i ~/.ssh/id_ed25519 \
  -N \
  -o ServerAliveInterval=60 \
  -o ServerAliveCountMax=3
```
