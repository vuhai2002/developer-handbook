# Tối ưu hiệu suất VPS: Swap, PostgreSQL & DB Pool

Hướng dẫn tối ưu hiệu suất VPS Ubuntu khi chạy nhiều Docker containers và PostgreSQL. Bao gồm 3 phần: tăng Swap tránh OOM, tối ưu cấu hình PostgreSQL cho server 16GB RAM, và tăng DB connection pool trong ứng dụng.

> **Khi nào cần dùng?**
> - VPS chạy chậm, swap gần cạn kiệt
> - PostgreSQL vẫn dùng cấu hình mặc định (chỉ dùng 128MB shared_buffers)
> - Ứng dụng thường bị lỗi "too many connections" hoặc timeout

---

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

### Kiểm tra hệ thống trước khi tối ưu

```bash
echo "===== SYSTEM INFO =====" && \
echo "--- RAM ---" && free -h && \
echo "--- DISK ---" && df -h / && \
echo "===== POSTGRESQL =====" && \
sudo -u postgres psql -c "SHOW shared_buffers;" && \
sudo -u postgres psql -c "SHOW effective_cache_size;" && \
sudo -u postgres psql -c "SHOW work_mem;" && \
sudo -u postgres psql -c "SHOW max_connections;" && \
sudo -u postgres psql -c "SELECT count(*) as active_connections FROM pg_stat_activity;"
```

### Tăng Swap (không downtime)

```bash
sudo fallocate -l 4G /swapfile2 && sudo chmod 600 /swapfile2 && \
sudo mkswap /swapfile2 && sudo swapon /swapfile2 && \
echo '/swapfile2 none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Tối ưu PostgreSQL (cần restart ~3-5s)

```bash
PG_CONF="/etc/postgresql/16/main/postgresql.conf"
sudo cp $PG_CONF ${PG_CONF}.bak.$(date +%Y%m%d)
sudo sed -i "s/^#*shared_buffers\s*=.*/shared_buffers = 512MB/" $PG_CONF
sudo sed -i "s/^#*effective_cache_size\s*=.*/effective_cache_size = 6GB/" $PG_CONF
sudo sed -i "s/^#*work_mem\s*=.*/work_mem = 8MB/" $PG_CONF
sudo sed -i "s/^#*maintenance_work_mem\s*=.*/maintenance_work_mem = 128MB/" $PG_CONF
sudo sed -i "s/^#*wal_buffers\s*=.*/wal_buffers = 16MB/" $PG_CONF
sudo sed -i "s/^#*checkpoint_completion_target\s*=.*/checkpoint_completion_target = 0.9/" $PG_CONF
sudo sed -i "s/^#*random_page_cost\s*=.*/random_page_cost = 1.1/" $PG_CONF
sudo sed -i "s/^#*effective_io_concurrency\s*=.*/effective_io_concurrency = 200/" $PG_CONF
sudo sed -i "s/^#*log_min_duration_statement\s*=.*/log_min_duration_statement = 1000/" $PG_CONF
sudo systemctl restart postgresql
```

---

## 📝 Các bước thực hiện (Step by Step)

### Phần 1: Tăng Swap — Chống OOM Killer

#### 🤔 Tại sao cần tăng Swap?

**Swap** là vùng ổ cứng được hệ thống dùng như RAM dự phòng. Khi RAM vật lý cạn kiệt, Linux sẽ chuyển các dữ liệu ít dùng từ RAM sang Swap để giải phóng bộ nhớ.

Nếu cả RAM lẫn Swap đều hết → Linux kích hoạt **OOM Killer** (Out of Memory Killer), tự động giết các process tiêu tốn RAM nhất — có thể là PostgreSQL hoặc Docker container của bạn! ☠️

> **VPS 16GB RAM chạy ~30 Docker containers** → Swap mặc định 2GB là không đủ. Cần tăng lên ít nhất 6GB.

#### Bước 1.1 — Kiểm tra Swap hiện tại

```bash
echo "=== SWAP HIỆN TẠI ===" && swapon --show && free -h | grep Swap
```

Kết quả sẽ cho thấy swap hiện tại là bao nhiêu và đã dùng bao nhiêu. Nếu `used` gần bằng `total` → cần tăng gấp.

#### Bước 1.2 — Tạo thêm 4GB Swap

```bash
# Tạo file 4GB làm swap
sudo fallocate -l 4G /swapfile2

# Chỉ cho phép root đọc/ghi (bảo mật)
sudo chmod 600 /swapfile2

# Format file thành swap
sudo mkswap /swapfile2

# Kích hoạt swap ngay lập tức (không cần restart)
sudo swapon /swapfile2
```

**Giải thích:**
| Lệnh | Tác dụng |
|---|---|
| `fallocate -l 4G` | Tạo file rỗng 4GB trên ổ cứng |
| `chmod 600` | Chỉ root mới đọc/ghi được file này (tránh lỗ hổng bảo mật) |
| `mkswap` | Đánh dấu file này là vùng swap (format) |
| `swapon` | Kích hoạt ngay, không cần reboot |

#### Bước 1.3 — Đảm bảo Swap tự mount khi reboot

```bash
echo '/swapfile2 none swap sw 0 0' | sudo tee -a /etc/fstab
```

File `/etc/fstab` chứa danh sách các phân vùng tự động mount khi khởi động. Nếu bỏ qua bước này, swap sẽ mất sau khi reboot VPS.

#### Bước 1.4 — Xác nhận Swap đã tăng

```bash
echo "=== SWAP SAU KHI TĂNG ===" && swapon --show && free -h | grep Swap
```

✅ **Kết quả mong đợi:** Swap total ≈ 6GB (2GB cũ + 4GB mới)

---

### Phần 2: Tối ưu PostgreSQL — Tăng hiệu suất 2-5x

#### 🤔 Tại sao PostgreSQL mặc định chạy chậm?

PostgreSQL được cấu hình mặc định rất bảo thủ (chỉ dùng 128MB RAM!) để chạy được trên mọi server, kể cả máy có 512MB RAM. Trên VPS 16GB RAM, việc tối ưu config sẽ giúp:

- **Query nhanh hơn 2-5x** nhờ cache nhiều dữ liệu hơn trong RAM
- **Sort/Join nhanh hơn** nhờ tăng bộ nhớ cho mỗi truy vấn
- **VACUUM nhanh hơn** → bảng không bị bloat

#### Bảng chỉnh config (cho server 16GB RAM)

| Tham số | Mặc định | Chỉnh thành | Giải thích |
|---|---|---|---|
| `shared_buffers` | 128 MB ❌ | **512 MB** | Cache dữ liệu trong RAM. Rule of thumb: 25-40% RAM dành cho PG |
| `effective_cache_size` | 4 GB | **6 GB** | Gợi ý cho PG biết tổng RAM có thể dùng cho cache (OS + PG) |
| `work_mem` | 4 MB | **8 MB** | RAM cho mỗi thao tác sort/hash join. Cẩn thận: mỗi connection dùng riêng |
| `maintenance_work_mem` | 64 MB | **128 MB** | RAM cho VACUUM, CREATE INDEX. Chỉ chạy 1 lúc nên tăng được |
| `wal_buffers` | -1 (auto) | **16 MB** | Buffer cho Write-Ahead Log. 16MB là best practice |
| `checkpoint_completion_target` | 0.5 | **0.9** | Dàn đều I/O khi checkpoint, tránh spike |
| `random_page_cost` | 4.0 | **1.1** | Cho SSD. Giúp PG ưu tiên Index Scan thay vì Seq Scan |
| `effective_io_concurrency` | 1 | **200** | Cho SSD. Cho phép PG đọc nhiều trang đồng thời |
| `log_min_duration_statement` | -1 (tắt) | **1000** | Log các query chạy > 1 giây. Giúp tìm query chậm |

> ⚠️ **Lưu ý:** Các giá trị trên tối ưu cho VPS **16GB RAM + SSD**. Nếu server khác cấu hình, dùng [PGTune](https://pgtune.leopard.in.ua/) để tính lại.

#### Bước 2.1 — Tìm đường dẫn file config

```bash
sudo -u postgres psql -c "SHOW config_file;"
```

Thông thường sẽ là `/etc/postgresql/16/main/postgresql.conf` (đổi `16` theo phiên bản PG của bạn).

#### Bước 2.2 — Backup config cũ

```bash
# ⚠️ ĐỔI đường dẫn nếu phiên bản PG khác 16
sudo cp /etc/postgresql/16/main/postgresql.conf /etc/postgresql/16/main/postgresql.conf.bak.$(date +%Y%m%d)
```

Luôn backup trước khi chỉnh! Nếu có vấn đề, bạn có thể rollback ngay (xem mục Rollback bên dưới).

#### Bước 2.3 — Chạy script tự động chỉnh config

Copy **toàn bộ** block dưới đây vào terminal:

```bash
# ⚠️ ĐỔI đường dẫn nếu phiên bản PG khác 16
PG_CONF="/etc/postgresql/16/main/postgresql.conf"

# Bộ nhớ chính
sudo sed -i "s/^#*shared_buffers\s*=.*/shared_buffers = 512MB/" $PG_CONF
sudo sed -i "s/^#*effective_cache_size\s*=.*/effective_cache_size = 6GB/" $PG_CONF
sudo sed -i "s/^#*work_mem\s*=.*/work_mem = 8MB/" $PG_CONF
sudo sed -i "s/^#*maintenance_work_mem\s*=.*/maintenance_work_mem = 128MB/" $PG_CONF

# Write-Ahead Log
sudo sed -i "s/^#*wal_buffers\s*=.*/wal_buffers = 16MB/" $PG_CONF
sudo sed -i "s/^#*checkpoint_completion_target\s*=.*/checkpoint_completion_target = 0.9/" $PG_CONF

# Tối ưu cho SSD
sudo sed -i "s/^#*random_page_cost\s*=.*/random_page_cost = 1.1/" $PG_CONF
sudo sed -i "s/^#*effective_io_concurrency\s*=.*/effective_io_concurrency = 200/" $PG_CONF

# Logging
sudo sed -i "s/^#*log_min_duration_statement\s*=.*/log_min_duration_statement = 1000/" $PG_CONF

echo "✅ Config đã được cập nhật!"
```

**`sed -i` là gì?** — Lệnh tìm & thay thế text trong file. Pattern `s/^#*param\s*=.*/param = value/` sẽ:
- `^#*` — Bỏ dấu `#` nếu dòng đang bị comment
- `\s*=.*` — Tìm phần `= giá_trị_cũ`
- Thay bằng giá trị mới

#### Bước 2.4 — Kiểm tra config đã đúng chưa

```bash
PG_CONF="/etc/postgresql/16/main/postgresql.conf"
echo "=== CONFIG MỚI ===" && \
grep -E "^(shared_buffers|effective_cache_size|work_mem|maintenance_work_mem|wal_buffers|checkpoint_completion_target|random_page_cost|effective_io_concurrency|log_min_duration_statement)" $PG_CONF
```

✅ **Kết quả mong đợi:**

```
shared_buffers = 512MB
effective_cache_size = 6GB
work_mem = 8MB
maintenance_work_mem = 128MB
wal_buffers = 16MB
checkpoint_completion_target = 0.9
random_page_cost = 1.1
effective_io_concurrency = 200
log_min_duration_statement = 1000
```

#### Bước 2.5 — Restart PostgreSQL

```bash
sudo systemctl restart postgresql
```

> ⚠️ **Cảnh báo:** Restart sẽ ngắt tất cả kết nối DB trong ~3-5 giây. Nên làm lúc ít người dùng nhất (ví dụ: 2-4 giờ sáng).

#### Bước 2.6 — Xác nhận PostgreSQL hoạt động bình thường

```bash
echo "=== PG STATUS ===" && \
sudo systemctl status postgresql --no-pager | head -5 && \
echo "" && \
echo "=== CONFIG VERIFY ===" && \
sudo -u postgres psql -c "SHOW shared_buffers;" && \
sudo -u postgres psql -c "SHOW effective_cache_size;" && \
sudo -u postgres psql -c "SHOW work_mem;" && \
sudo -u postgres psql -c "SHOW maintenance_work_mem;" && \
echo "" && \
echo "=== CONNECTIONS ===" && \
sudo -u postgres psql -c "SELECT count(*) as active_connections FROM pg_stat_activity;" && \
echo "" && \
echo "=== MEMORY SAU RESTART ===" && \
free -h
```

✅ Kiểm tra: `shared_buffers` hiển thị `512MB`, PG status là `active (running)`.

---

### Phần 3: Tăng DB Connection Pool trong ứng dụng

#### 🤔 Tại sao cần tăng Pool?

Mỗi request từ ứng dụng cần 1 kết nối đến PostgreSQL. **Connection pool** duy trì sẵn một số kết nối mở để tái sử dụng, tránh overhead tạo kết nối mới.

- Pool **quá nhỏ** → Request phải xếp hàng chờ → timeout
- Pool **quá lớn** → Lãng phí RAM (mỗi connection dùng ~5-10MB)

**Quy tắc:** `pool size ≤ max_connections * 0.8` để chừa headroom cho admin/monitoring.

#### Thực hiện (trên máy local, không phải VPS)

Sửa file cấu hình database pool trong source code, thay đổi giá trị `max`:

```typescript
const pool = new pg.Pool({
  connectionString: env.DATABASE_URL,
  max: 30,                        // Tăng từ 20 → 30
  idleTimeoutMillis: 30_000,      // Đóng connection idle sau 30s
  connectionTimeoutMillis: 10_000, // Timeout nếu không lấy được connection sau 10s
});
```

Sau khi sửa, **rebuild và deploy lại backend**.

---

## ⚠️ Troubleshooting / Lưu ý

### Rollback PostgreSQL config

Nếu sau khi restart PostgreSQL mà có vấn đề (lỗi khởi động, out of memory):

```bash
# ⚠️ ĐỔI đường dẫn và ngày nếu cần
sudo cp /etc/postgresql/16/main/postgresql.conf.bak.$(date +%Y%m%d) /etc/postgresql/16/main/postgresql.conf
sudo systemctl restart postgresql
```

### Xóa Swap nếu cần

```bash
sudo swapoff /swapfile2
sudo rm /swapfile2
# Xóa dòng /swapfile2 trong /etc/fstab
sudo sed -i '/swapfile2/d' /etc/fstab
```

### PostgreSQL không start sau khi chỉnh config

Kiểm tra log lỗi:

```bash
sudo tail -50 /var/log/postgresql/postgresql-16-main.log
```

Lỗi thường gặp:
- **`shared_buffers` quá lớn:** Giảm xuống. Tối đa nên là 40% RAM
- **Sai cú pháp trong config:** Kiểm tra lại file, chú ý không có space thừa

### Kiểm tra slow query log

Sau khi bật `log_min_duration_statement = 1000`, các query chạy > 1 giây sẽ được log vào:

```bash
sudo tail -f /var/log/postgresql/postgresql-16-main.log | grep "duration"
```

### Công cụ hữu ích

- **[PGTune](https://pgtune.leopard.in.ua/)** — Tính config tối ưu cho server của bạn
- **[pg_stat_statements](https://www.postgresql.org/docs/current/pgstatstatements.html)** — Extension theo dõi query performance
- **`htop`** — Xem RAM/CPU realtime trên VPS
