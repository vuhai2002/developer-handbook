# VPS Quick Check — Kiểm Tra Nhanh Thông Số VPS

Script bash one-liner giúp kiểm tra toàn bộ thông số VPS (OS, CPU, RAM, Disk, Network) chỉ với **một dòng lệnh duy nhất**. Hiển thị đẹp với màu sắc và tự động đánh giá ✅ Tốt / ⚠️ Cần lưu ý / ❌ Có vấn đề.

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

**Cách nhanh nhất — Paste vào terminal bất kỳ VPS nào:**

```bash
curl -sL https://raw.githubusercontent.com/vuhai2002/developer-handbook/main/vps-check.sh | bash
```

**Hoặc tải về rồi chạy:**

```bash
curl -sL https://raw.githubusercontent.com/vuhai2002/developer-handbook/main/vps-check.sh -o ~/vps-check.sh
chmod +x ~/vps-check.sh
bash ~/vps-check.sh
```

**Copy sang VPS khác (nếu đã có sẵn file):**

```bash
scp ~/vps-check.sh user@ip-vps-moi:~/vps-check.sh
ssh user@ip-vps-moi "bash ~/vps-check.sh"
```

## 📝 Các bước thực hiện (Step by Step)

### Bước 1: Chạy Script

SSH vào VPS cần kiểm tra, rồi chạy one-liner:

```bash
curl -sL https://raw.githubusercontent.com/vuhai2002/developer-handbook/main/vps-check.sh | bash
```

Script sẽ tự động quét trong ~15 giây và hiển thị kết quả.

### Bước 2: Đọc Kết Quả

Script hiển thị **6 mục chính**:

| # | Mục | Chi tiết kiểm tra |
|---|-----|-------------------|
| 1 | 💻 Hệ điều hành | OS, kernel, uptime, loại ảo hóa |
| 2 | ⚙️ CPU | Model, số vCPU, tần số, load trung bình |
| 3 | 🧠 RAM | Tổng/dùng/trống, swap, % sử dụng |
| 4 | 💾 Disk | Dung lượng, filesystem, tốc độ ghi (benchmark 64MB) |
| 5 | 🌐 Mạng | IP, vị trí DC, nhà cung cấp, tốc độ download, ping |
| 6 | 📋 Tổng kết | Bảng tổng hợp + điểm đánh giá tổng /6 |

### Bước 3: Hiểu Hệ Thống Chấm Điểm

Mỗi mục sẽ tự động đánh giá bằng biểu tượng + màu:

- ✅ **Xanh** — Tốt, không cần lo
- ⚠️ **Vàng** — Cần lưu ý, theo dõi thêm
- ❌ **Đỏ** — Có vấn đề, cần xử lý

Điểm tổng **/6** dựa trên 6 tiêu chí: CPU load, RAM, Disk, Swap, Network speed, Ping.

## 📊 Bảng Tham Chiếu Thông Số VPS (Reference)

### CPU

| Thông số | ❌ Yếu | ⚠️ Trung bình | ✅ Tốt | 🚀 Mạnh |
|----------|--------|---------------|-------|---------|
| vCPU | 1 vCPU | 2 vCPU | 4 vCPU | 8+ vCPU |
| Load (% so với vCPU) | > 80% | 50–80% | 20–50% | < 20% |
| Tần số | < 1.5 GHz | 1.5–2.5 GHz | 2.5–3.5 GHz | > 3.5 GHz |

> **Cách đọc Load:** Load 1.0 trên VPS 1 vCPU = 100% tải. Load 2.0 trên VPS 4 vCPU = 50% tải (2/4). Lý tưởng là load < 70% số vCPU.

### RAM

| Thông số | ❌ Yếu | ⚠️ Trung bình | ✅ Tốt | 🚀 Mạnh |
|----------|--------|---------------|-------|---------|
| Tổng RAM | 512MB | 1–2 GB | 4–8 GB | 16+ GB |
| % Sử dụng | > 80% | 50–80% | 30–50% | < 30% |
| Swap | Không có ❌ | < 1 GB | 1–2 GB | 2+ GB |

> **Lưu ý:**  Không có Swap là nguy hiểm — hệ thống sẽ OOM kill process khi hết RAM. Nên tạo swap ít nhất bằng 50% RAM.

### Disk (Ổ cứng)

| Thông số | ❌ Yếu | ⚠️ Trung bình | ✅ Tốt | 🚀 Mạnh |
|----------|--------|---------------|-------|---------|
| Dung lượng | < 20 GB | 20–40 GB | 40–80 GB | 100+ GB |
| % Sử dụng | > 85% | 60–85% | 30–60% | < 30% |
| Tốc độ ghi | < 80 MB/s (HDD) | 80–200 MB/s (SSD phổ thông) | 200–500 MB/s (SSD tốt) | > 500 MB/s (NVMe) |

> **Cách hiểu Disk I/O:** HDD thường < 100 MB/s. SSD SATA ~ 200–500 MB/s. NVMe SSD > 500 MB/s, có thể đạt 2–3 GB/s.

### Network (Mạng)

| Thông số | ❌ Yếu | ⚠️ Trung bình | ✅ Tốt | 🚀 Mạnh |
|----------|--------|---------------|-------|---------|
| Download | < 30 Mbps | 30–100 Mbps | 100–500 Mbps | > 500 Mbps |
| Ping (Google DNS) | > 100 ms | 50–100 ms | 10–50 ms | < 10 ms |

> **Ping phụ thuộc vị trí DC:** VPS ở Singapore ping về VN ~ 20–40ms. VPS ở US ping về VN ~ 150–200ms. Chọn DC gần user nhất.

### Gợi ý Cấu Hình Theo Mục Đích Sử Dụng

| Mục đích | vCPU | RAM | Disk | Ghi chú |
|----------|------|-----|------|---------|
| Blog / Landing page | 1 | 1 GB | 20 GB | Nginx + static site |
| App nhỏ (Node/Python) | 1–2 | 2 GB | 30 GB | + Swap 1GB |
| Web app + Database | 2–4 | 4 GB | 40–80 GB | PostgreSQL cần RAM |
| Production (nhiều user) | 4–8 | 8–16 GB | 80–160 GB | + Redis cache |
| CI/CD / Build server | 4+ | 8+ GB | 100+ GB | CPU-intensive |

## ⚠️ Troubleshooting / Lưu ý

### `curl: command not found`

```bash
# Ubuntu/Debian
apt update && apt install -y curl

# CentOS/RHEL
yum install -y curl
```

### `bc: command not found` (ảnh hưởng đánh giá Disk I/O)

```bash
# Ubuntu/Debian
apt install -y bc

# CentOS/RHEL
yum install -y bc
```

### Tốc độ download hiện "Không test được"

Nguyên nhân: Firewall chặn outbound HTTPS. Kiểm tra:

```bash
curl -s --connect-timeout 5 https://speed.cloudflare.com/__down?bytes=1000
```

Nếu không trả kết quả → mở port 443 outbound hoặc kiểm tra iptables/firewalld.

### Kết quả Disk I/O không chính xác

Script chỉ test ghi 64MB — đây là benchmark nhanh, không thay thế công cụ chuyên dụng. Để benchmark chính xác hơn:

```bash
# Test với fio (cần cài thêm)
fio --name=test --ioengine=libaio --rw=write --bs=1M --size=256M --numjobs=1 --runtime=10 --direct=1
```
