#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  VPS Quick Check — by vuhai                                  ║
# ║  Paste vào terminal bất kỳ VPS nào để xem thông số nhanh    ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Colors ──────────────────────────────────────────────────────
R='\033[0m'       # Reset
B='\033[1m'       # Bold
DIM='\033[2m'     # Dim
RED='\033[1;31m'
GRN='\033[1;32m'
YLW='\033[1;33m'
BLU='\033[1;34m'
MAG='\033[1;35m'
CYN='\033[1;36m'
WHT='\033[1;37m'
BG_BLU='\033[44m'
BG_GRN='\033[42m'
BG_RED='\033[41m'
BG_YLW='\033[43m'

# ── Helper functions ────────────────────────────────────────────
line()   { printf "${DIM}"; printf '%.0s─' $(seq 1 60); printf "${R}\n"; }
header() { printf "\n${BG_BLU}${WHT} %-58s ${R}\n" "$1"; }
label()  { printf "  ${CYN}%-22s${R} %s\n" "$1" "$2"; }
good()   { printf "  ${CYN}%-22s${R} ${GRN}✅ %s${R}\n" "$1" "$2"; }
warn()   { printf "  ${CYN}%-22s${R} ${YLW}⚠️  %s${R}\n" "$1" "$2"; }
bad()    { printf "  ${CYN}%-22s${R} ${RED}❌ %s${R}\n" "$1" "$2"; }
val()    { printf "  ${CYN}%-22s${R} ${WHT}${B}%s${R}\n" "$1" "$2"; }

# ── Start ───────────────────────────────────────────────────────
clear
printf "\n"
printf "${MAG}${B}"
printf "  ╔══════════════════════════════════════════════════╗\n"
printf "  ║        🚀  VPS QUICK CHECK  🚀                  ║\n"
printf "  ║        Kiểm tra nhanh thông số VPS               ║\n"
printf "  ╚══════════════════════════════════════════════════╝\n"
printf "${R}"
printf "  ${DIM}Đang quét... vui lòng đợi ~15 giây${R}\n"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. HỆ ĐIỀU HÀNH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
header "💻  HỆ ĐIỀU HÀNH"
line

OS_NAME=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2)
KERNEL=$(uname -r)
ARCH=$(uname -m)
HOSTNAME_VAL=$(hostname)
UPTIME_VAL=$(uptime -p 2>/dev/null || uptime)
VIRT=$(systemd-detect-virt 2>/dev/null || echo "Không xác định")

val  "Hostname"        "$HOSTNAME_VAL"
val  "Hệ điều hành"    "${OS_NAME:-Không xác định}"
val  "Kernel"          "$KERNEL"
val  "Kiến trúc"       "$ARCH"
val  "Ảo hóa"          "$VIRT"
val  "Uptime"          "$UPTIME_VAL"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. CPU
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
header "⚙️   CPU (Bộ xử lý)"
line

CPU_MODEL=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs)
CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
CPU_FREQ=$(grep "cpu MHz" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs)
CPU_CACHE=$(lscpu 2>/dev/null | grep "L2 cache" | cut -d: -f2 | xargs)
LOAD=$(cat /proc/loadavg | awk '{print $1" / "$2" / "$3}')
CPU_TYPE="Shared (chia sẻ)"
if lscpu 2>/dev/null | grep -qi "Thread(s) per core.*2"; then
    HT="Có (Hyper-Threading)"
else
    HT="Không"
fi

val  "Model CPU"        "${CPU_MODEL:-Không xác định}"
val  "Số vCPU"          "$CPU_CORES vCPU"
val  "Tần số"           "${CPU_FREQ:-N/A} MHz"
val  "Cache L2"         "${CPU_CACHE:-N/A}"
val  "Hyper-Threading"  "$HT"
val  "Load trung bình"  "$LOAD"

# Đánh giá load
LOAD_1=$(cat /proc/loadavg | awk '{print $1}')
LOAD_RATIO=$(echo "$LOAD_1 $CPU_CORES" | awk '{printf "%.0f", ($1/$2)*100}')
if [ "$LOAD_RATIO" -lt 50 ]; then
    good "Tình trạng CPU" "Nhàn rỗi ($LOAD_RATIO% tải)"
elif [ "$LOAD_RATIO" -lt 80 ]; then
    warn "Tình trạng CPU" "Tải vừa ($LOAD_RATIO% tải)"
else
    bad  "Tình trạng CPU" "Tải cao! ($LOAD_RATIO% tải)"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. RAM
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
header "🧠  RAM (Bộ nhớ)"
line

RAM_TOTAL=$(free -h | awk '/Mem:/{print $2}')
RAM_USED=$(free -h | awk '/Mem:/{print $3}')
RAM_FREE=$(free -h | awk '/Mem:/{print $7}')
RAM_PERCENT=$(free | awk '/Mem:/{printf "%.0f", $3/$2*100}')
SWAP_TOTAL=$(free -h | awk '/Swap:/{print $2}')
SWAP_USED=$(free -h | awk '/Swap:/{print $3}')

val  "Tổng RAM"         "$RAM_TOTAL"
val  "Đang dùng"        "$RAM_USED ($RAM_PERCENT%)"
val  "Còn trống"        "$RAM_FREE"

if [ "$RAM_PERCENT" -lt 50 ]; then
    good "Tình trạng RAM" "Thoải mái ($RAM_PERCENT% sử dụng)"
elif [ "$RAM_PERCENT" -lt 80 ]; then
    warn "Tình trạng RAM" "Trung bình ($RAM_PERCENT% sử dụng)"
else
    bad  "Tình trạng RAM" "Sắp đầy! ($RAM_PERCENT% sử dụng)"
fi

# Kiểm tra swap
SWAP_TOTAL_BYTES=$(free | awk '/Swap:/{print $2}')
if [ "$SWAP_TOTAL_BYTES" -eq 0 ] 2>/dev/null; then
    bad  "Swap"  "KHÔNG CÓ — nên tạo swap để tránh crash"
else
    val  "Swap"  "$SWAP_TOTAL (đang dùng: $SWAP_USED)"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. Ổ CỨNG
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
header "💾  Ổ CỨNG (Disk)"
line

DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
DISK_USED=$(df -h / | awk 'NR==2{print $3}')
DISK_FREE=$(df -h / | awk 'NR==2{print $4}')
DISK_PERCENT=$(df / | awk 'NR==2{print $5}' | tr -d '%')
DISK_FS=$(df -T / | awk 'NR==2{print $2}')

val  "Tổng dung lượng"  "$DISK_TOTAL"
val  "Đã dùng"          "$DISK_USED ($DISK_PERCENT%)"
val  "Còn trống"        "$DISK_FREE"
val  "Filesystem"       "$DISK_FS"

if [ "$DISK_PERCENT" -lt 60 ]; then
    good "Tình trạng Disk" "Rộng rãi ($DISK_PERCENT% sử dụng)"
elif [ "$DISK_PERCENT" -lt 85 ]; then
    warn "Tình trạng Disk" "Nên theo dõi ($DISK_PERCENT% sử dụng)"
else
    bad  "Tình trạng Disk" "Sắp đầy! ($DISK_PERCENT% sử dụng)"
fi

# Disk I/O test (nhanh, chỉ 64MB)
printf "\n  ${DIM}Đang test tốc độ ổ cứng...${R}\n"
DISK_WRITE=$(dd if=/dev/zero of=/tmp/.vps_check_io bs=1M count=64 oflag=dsync 2>&1 | tail -1 | awk -F',' '{print $NF}' | xargs)
rm -f /tmp/.vps_check_io
val  "Tốc độ ghi"       "$DISK_WRITE"

# Đánh giá
WRITE_SPEED=$(echo "$DISK_WRITE" | grep -oP '[\d.]+' | head -1)
WRITE_UNIT=$(echo "$DISK_WRITE" | grep -oP '(MB|GB)' | head -1)
if [ "$WRITE_UNIT" = "GB" ]; then
    good "Đánh giá I/O" "Rất nhanh (NVMe / SSD cao cấp)"
elif [ "$(echo "$WRITE_SPEED > 200" | bc -l 2>/dev/null)" = "1" ]; then
    good "Đánh giá I/O" "Nhanh (SSD tốt)"
elif [ "$(echo "$WRITE_SPEED > 80" | bc -l 2>/dev/null)" = "1" ]; then
    warn "Đánh giá I/O" "Trung bình (SSD phổ thông)"
else
    bad  "Đánh giá I/O" "Chậm — có thể là HDD hoặc SSD cũ"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. MẠNG
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
header "🌐  MẠNG (Network)"
line

# Public IP
PUBLIC_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || curl -s --connect-timeout 5 icanhazip.com 2>/dev/null || echo "Không lấy được")
val  "IP Public"         "$PUBLIC_IP"

# Private IPs
PRIVATE_IPS=$(hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '^$' | head -3 | tr '\n' ', ' | sed 's/,$//')
val  "IP Private"        "${PRIVATE_IPS:-Không có}"

# Geolocation
GEO=$(curl -s --connect-timeout 5 ipinfo.io 2>/dev/null)
if [ -n "$GEO" ]; then
    CITY=$(echo "$GEO" | grep -oP '"city"\s*:\s*"\K[^"]+')
    REGION=$(echo "$GEO" | grep -oP '"region"\s*:\s*"\K[^"]+')
    COUNTRY=$(echo "$GEO" | grep -oP '"country"\s*:\s*"\K[^"]+')
    ORG=$(echo "$GEO" | grep -oP '"org"\s*:\s*"\K[^"]+')
    val  "Vị trí DC"    "$CITY, $REGION ($COUNTRY)"
    val  "Nhà cung cấp" "$ORG"
fi

# Speed test (nhỏ, nhanh — chỉ 5MB)
printf "\n  ${DIM}Đang test tốc độ mạng...${R}\n"
NET_RESULT=$(curl -o /dev/null -w "%{speed_download}" -s --connect-timeout 5 https://speed.cloudflare.com/__down?bytes=5000000 2>/dev/null)
if [ -n "$NET_RESULT" ] && [ "$NET_RESULT" != "0" ]; then
    NET_MBPS=$(echo "$NET_RESULT" | awk '{printf "%.0f", $1/1024/1024*8}')
    val  "Tốc độ download" "~${NET_MBPS} Mbps"
    if [ "$NET_MBPS" -gt 500 ]; then
        good "Đánh giá mạng" "Rất nhanh"
    elif [ "$NET_MBPS" -gt 100 ]; then
        good "Đánh giá mạng" "Nhanh"
    elif [ "$NET_MBPS" -gt 30 ]; then
        warn "Đánh giá mạng" "Trung bình"
    else
        bad  "Đánh giá mạng" "Chậm"
    fi
else
    warn "Tốc độ download" "Không test được (firewall?)"
fi

# Ping
PING_RESULT=$(ping -c 3 -W 3 8.8.8.8 2>/dev/null | tail -1)
if [ -n "$PING_RESULT" ]; then
    PING_AVG=$(echo "$PING_RESULT" | awk -F'/' '{printf "%.1f", $5}')
    val  "Ping (Google DNS)" "${PING_AVG} ms"
    PING_INT=$(echo "$PING_AVG" | cut -d. -f1)
    if [ "$PING_INT" -lt 10 ]; then
        good "Đánh giá latency" "Cực thấp — tuyệt vời"
    elif [ "$PING_INT" -lt 50 ]; then
        good "Đánh giá latency" "Tốt"
    elif [ "$PING_INT" -lt 100 ]; then
        warn "Đánh giá latency" "Chấp nhận được"
    else
        bad  "Đánh giá latency" "Cao — xa datacenter"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. TỔNG KẾT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
header "📋  BẢNG TỔNG KẾT NHANH"
line

printf "\n"
printf "  ${B}┌────────────────────┬────────────────────────────────┐${R}\n"
printf "  ${B}│${CYN} %-18s ${B}│${WHT} %-30s ${B}│${R}\n" "Thông số"       "Giá trị"
printf "  ${B}├────────────────────┼────────────────────────────────┤${R}\n"
printf "  ${B}│${R} %-18s ${B}│${WHT} %-30s ${B}│${R}\n" "Nhà cung cấp"   "${ORG:-N/A}"
printf "  ${B}│${R} %-18s ${B}│${WHT} %-30s ${B}│${R}\n" "Vị trí"         "${CITY:-N/A}, ${COUNTRY:-N/A}"
printf "  ${B}│${R} %-18s ${B}│${WHT} %-30s ${B}│${R}\n" "OS"             "${OS_NAME:-N/A}"
printf "  ${B}│${R} %-18s ${B}│${WHT} %-30s ${B}│${R}\n" "CPU"            "${CPU_CORES} vCPU — ${CPU_MODEL:-N/A}"
printf "  ${B}│${R} %-18s ${B}│${WHT} %-30s ${B}│${R}\n" "RAM"            "${RAM_TOTAL}"
printf "  ${B}│${R} %-18s ${B}│${WHT} %-30s ${B}│${R}\n" "Disk"           "${DISK_TOTAL} (${DISK_FS})"
printf "  ${B}│${R} %-18s ${B}│${WHT} %-30s ${B}│${R}\n" "Disk I/O"       "${DISK_WRITE}"
printf "  ${B}│${R} %-18s ${B}│${WHT} %-30s ${B}│${R}\n" "Network"        "~${NET_MBPS:-?} Mbps"
printf "  ${B}│${R} %-18s ${B}│${WHT} %-30s ${B}│${R}\n" "Ping"           "${PING_AVG:-?} ms"
printf "  ${B}│${R} %-18s ${B}│${WHT} %-30s ${B}│${R}\n" "IP"             "${PUBLIC_IP}"
printf "  ${B}│${R} %-18s ${B}│${WHT} %-30s ${B}│${R}\n" "Ảo hóa"        "${VIRT}"
printf "  ${B}└────────────────────┴────────────────────────────────┘${R}\n"

# Điểm tổng
SCORE=0
[ "$LOAD_RATIO" -lt 70 ] && SCORE=$((SCORE+1))
[ "$RAM_PERCENT" -lt 70 ] && SCORE=$((SCORE+1))
[ "$DISK_PERCENT" -lt 70 ] && SCORE=$((SCORE+1))
[ "$SWAP_TOTAL_BYTES" -gt 0 ] 2>/dev/null && SCORE=$((SCORE+1))
[ "${NET_MBPS:-0}" -gt 100 ] 2>/dev/null && SCORE=$((SCORE+1))
[ "${PING_INT:-999}" -lt 50 ] 2>/dev/null && SCORE=$((SCORE+1))

printf "\n"
if [ "$SCORE" -ge 5 ]; then
    printf "  ${BG_GRN}${WHT}${B}  ĐÁNH GIÁ TỔNG: ⭐ $SCORE/6 — VPS tốt, sẵn sàng sử dụng!  ${R}\n"
elif [ "$SCORE" -ge 3 ]; then
    printf "  ${BG_YLW}${WHT}${B}  ĐÁNH GIÁ TỔNG: ⭐ $SCORE/6 — Tạm ổn, cần cải thiện        ${R}\n"
else
    printf "  ${BG_RED}${WHT}${B}  ĐÁNH GIÁ TỔNG: ⭐ $SCORE/6 — Cần xem lại cấu hình!        ${R}\n"
fi

printf "\n  ${DIM}Hoàn thành lúc $(date '+%H:%M:%S %d/%m/%Y')${R}\n"
printf "  ${DIM}Script: vps-check.sh — https://github.com/vuhai${R}\n\n"
