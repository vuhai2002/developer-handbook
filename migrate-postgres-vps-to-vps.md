# Migrate PostgreSQL Database giữa 2 VPS (pg_dump + restore)

Hướng dẫn di chuyển toàn bộ một database PostgreSQL (cả schema lẫn data) từ **VPS nguồn** sang **VPS đích**, trung chuyển qua máy local (Windows + Git Bash). Dùng khi tách DB sang VPS prod riêng, đổi nhà cung cấp, hoặc gộp/tách hạ tầng.

- Nguồn chỉ bị **ĐỌC** - không ghi gì lên nguồn.
- Restore chạy trong **1 transaction** -> lỗi là rollback sạch, không để DB đích nửa vời.
- Idempotent: chạy lại bao nhiêu lần cũng ra trạng thái sạch = đúng bản dump.

> Phù hợp DB nhỏ tới vừa, **cùng major version** PostgreSQL (vd 16 -> 16). Nếu pg_dump mới hơn server đích (vd client 17 dump rồi restore vào server 16) thì làm thêm Bước 5. Media trên object storage (S3/B2) nằm ngoài DB nên không bị ảnh hưởng.

## 🧩 Cần chuẩn bị (điền giá trị)

| Placeholder | Ý nghĩa |
|---|---|
| `<source-host>` `<source-port>` | Host + port Postgres nguồn (mặc định 5432) |
| `<source-user>` `<source-db>` `<source-password>` | Tài khoản + tên DB nguồn |
| `<target-host>` `<target-port>` | Host + port Postgres đích (nếu nối qua SSH tunnel thì là `localhost:<port-tunnel>`) |
| `<target-user>` `<target-db>` `<target-password>` | Tài khoản + tên DB đích (nên tạo sẵn DB rỗng trước) |
| `<pg-version>` | Phiên bản PostgreSQL client trên Windows (vd `17`) |

> **Quan trọng:** chạy mọi lệnh bằng **Git Bash** (KHÔNG phải PowerShell - `export` là cú pháp bash). DB đích thường chỉ cho truy cập nội bộ VPS -> mở **SSH tunnel** tới nó trước (xem [Kết nối Database qua SSH Tunnel](./ssh-tunnel-database-local.md)).

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

```bash
# 0. Them PostgreSQL client vao PATH (doi <pg-version> cho dung, vd 17)
export PATH="/c/Program Files/PostgreSQL/<pg-version>/bin:$PATH"

# 1. Khai bao ket noi - mat khau de RIENG, KHONG nhet vao URL (tranh vo URL parsing)
export SOURCE_DATABASE_URL='postgresql://<source-user>@<source-host>:<source-port>/<source-db>?sslmode=require'
export SOURCE_DB_PASSWORD='<source-password>'
export TARGET_DATABASE_URL='postgresql://<target-user>@<target-host>:<target-port>/<target-db>?sslmode=require'
export TARGET_DB_PASSWORD='<target-password>'

# 2. Dump (plain SQL) -> strip transaction_timeout (neu pg_dump > server dich) -> restore
STAMP=$(date +%Y%m%d-%H%M%S); F="dump_$STAMP.sql"
PGPASSWORD="$SOURCE_DB_PASSWORD" pg_dump "$SOURCE_DATABASE_URL" \
  --format=plain --no-owner --no-privileges --clean --if-exists --file="$F"
grep -v '^SET transaction_timeout' "$F" > "$F.tmp" && mv "$F.tmp" "$F"
PGPASSWORD="$TARGET_DB_PASSWORD" psql "$TARGET_DATABASE_URL" \
  --set=ON_ERROR_STOP=on --single-transaction --file="$F"
```

---

## 📝 Các bước thực hiện (Step by Step)

### Mô hình

```
┌─────────────┐   pg_dump    ┌──────────────┐  psql restore  ┌─────────────┐
│  VPS nguon  │ ───(doc)───▶ │   May local  │ ─────────────▶ │  VPS dich   │
│  Postgres   │              │  (.sql file) │                │  Postgres   │
└─────────────┘              └──────────────┘                └─────────────┘
```

### Bước 1: Chuẩn bị tool

Cần `pg_dump` + `psql`. Trên Windows thường đã có sẵn trong `C:\Program Files\PostgreSQL\<pg-version>\bin`. Thêm vào PATH cho phiên Git Bash hiện tại:

```bash
export PATH="/c/Program Files/PostgreSQL/<pg-version>/bin:$PATH"
pg_dump --version && psql --version
```

> Nên dùng `pg_dump` phiên bản **>= server đích**. Cùng major version (16 -> 16) là an toàn nhất.

### Bước 2: Khai báo connection (mật khẩu để RIÊNG)

Nếu mật khẩu có ký tự `@ % $ / ?` mà nhét thẳng vào URL thì hỏng parsing (dấu `@` trong mật khẩu đụng dấu `@` ngăn host; `%xx` bị hiểu là percent-encoding). Cách chắc chắn: URL **không** chứa mật khẩu, để mật khẩu vào biến `*_DB_PASSWORD` (libpq đọc raw, không parse).

```bash
export SOURCE_DATABASE_URL='postgresql://<source-user>@<source-host>:<source-port>/<source-db>?sslmode=require'
export SOURCE_DB_PASSWORD='<source-password>'
export TARGET_DATABASE_URL='postgresql://<target-user>@<target-host>:<target-port>/<target-db>?sslmode=require'
export TARGET_DB_PASSWORD='<target-password>'
```

> URL chỉ còn `user@host`, KHÔNG có `:matkhau`. Dùng nháy đơn `'...'` để ký tự đặc biệt không bị shell hiểu nhầm. Bỏ `?sslmode=require` nếu DB không bật SSL.

### Bước 3: Test kết nối 2 đầu

```bash
echo "== SOURCE ==" && PGPASSWORD="$SOURCE_DB_PASSWORD" psql "$SOURCE_DATABASE_URL" -tAc "SELECT current_database();"
echo "== TARGET ==" && PGPASSWORD="$TARGET_DB_PASSWORD" psql "$TARGET_DATABASE_URL" -tAc "SELECT current_database();"
```

Cả 2 in ra tên DB tương ứng là kết nối OK. Lỗi `Connection refused` ở đích -> kiểm tra SSH tunnel.

### Bước 4: Dump database nguồn (chỉ đọc)

```bash
STAMP=$(date +%Y%m%d-%H%M%S)
F="dump_$STAMP.sql"
PGPASSWORD="$SOURCE_DB_PASSWORD" pg_dump "$SOURCE_DATABASE_URL" \
  --format=plain \
  --no-owner \
  --no-privileges \
  --clean \
  --if-exists \
  --file="$F"
ls -lh "$F"
```

| Flag | Ý nghĩa |
|---|---|
| `--format=plain` | Xuất plain SQL (dễ đọc/audit; restore bằng `psql`) |
| `--no-owner` | Bỏ lệnh gán owner (user 2 VPS thường khác nhau) |
| `--no-privileges` | Bỏ GRANT/REVOKE (tránh lỗi role không tồn tại) |
| `--clean --if-exists` | Thêm `DROP ... IF EXISTS` ở đầu -> chạy lại được (idempotent) |

### Bước 5: Strip `SET transaction_timeout` (chỉ khi pg_dump mới hơn server đích)

pg_dump **17+** chèn dòng `SET transaction_timeout = 0;` vào đầu dump - tham số này server **< 17 không hiểu** và sẽ làm restore lỗi. Nó chỉ nghĩa là "không giới hạn timeout" nên bỏ đi an toàn:

```bash
grep -v '^SET transaction_timeout' "$F" > "$F.tmp" && mv "$F.tmp" "$F"
```

> Nếu pg_dump cùng version với server đích thì bỏ qua bước này.

### Bước 6: Restore vào database đích

```bash
PGPASSWORD="$TARGET_DB_PASSWORD" psql "$TARGET_DATABASE_URL" \
  --set=ON_ERROR_STOP=on \
  --single-transaction \
  --file="$F"
```

- `--single-transaction`: bọc toàn bộ trong 1 transaction -> lỗi là rollback hết, không để DB nửa vời.
- `--set=ON_ERROR_STOP=on`: dừng ngay khi gặp lỗi đầu tiên.

### Bước 7: Verify (đếm `count(*)` chính xác 2 đầu)

Block này tự lấy danh sách bảng (kèm schema) rồi so số dòng thật từng bảng:

```bash
TABLES=$(PGPASSWORD="$SOURCE_DB_PASSWORD" psql "$SOURCE_DATABASE_URL" -tAc \
  "SELECT schemaname||'.'||relname FROM pg_stat_user_tables ORDER BY 1;")

printf "%-40s %12s %12s\n" "table" "source" "target"
for t in $TABLES; do
  s=$(PGPASSWORD="$SOURCE_DB_PASSWORD" psql "$SOURCE_DATABASE_URL" -tAc "SELECT count(*) FROM $t;")
  d=$(PGPASSWORD="$TARGET_DB_PASSWORD" psql "$TARGET_DATABASE_URL" -tAc "SELECT count(*) FROM $t;")
  flag=""; [ "$s" != "$d" ] && flag="  <-- LECH"
  printf "%-40s %12s %12s%s\n" "$t" "$s" "$d" "$flag"
done
```

Đạt yêu cầu khi mọi dòng có source = target và không có `<-- LECH`.

> Việc tự lấy danh sách bảng (`schema.table`) giúp bắt được cả bảng nằm ngoài schema `public` - vd dự án dùng **Drizzle ORM** để bảng `__drizzle_migrations` trong schema `drizzle`.

### Bước 8: Cutover - trỏ backend sang DB mới

Sửa `DATABASE_URL` trong file env của backend:

```dotenv
DATABASE_URL=postgresql://<target-user>:<target-password-da-encode>@<target-host>:<target-port>/<target-db>?sslmode=require
```

> Ở đây backend **parse chuỗi URL**, nên mật khẩu PHẢI percent-encode nếu có ký tự đặc biệt (khác Bước 2 dùng `PGPASSWORD` raw):
> `%` -> `%25` (encode trước tiên), `@` -> `%40`, `/` -> `%2F`, `?` -> `%3F`, `#` -> `%23`, `:` -> `%3A`. Ký tự `$ ! - _` để nguyên được.
> Ví dụ mật khẩu `ab%cd@ef` -> viết trong URL là `ab%25cd%40ef`.

Khởi động lại backend và kiểm tra health/ready endpoint để chắc nó kết nối đúng DB mới.

---

## 🤖 Script tự động hoá (chạy 1 phát)

Lưu thành `migrate-db.sh`, đặt cạnh nơi muốn chứa dump. Đọc 4 biến môi trường ở Bước 2 (URL không mật khẩu + `*_DB_PASSWORD`).

```bash
#!/usr/bin/env bash
# Migrate a PostgreSQL DB between two servers via pg_dump (plain SQL) -> psql.
# Source is READ-ONLY. Restore runs in a single transaction.
#
#   export SOURCE_DATABASE_URL='postgresql://<user>@<host>:<port>/<db>?sslmode=require'
#   export SOURCE_DB_PASSWORD='...'
#   export TARGET_DATABASE_URL='postgresql://<user>@<host>:<port>/<db>?sslmode=require'
#   export TARGET_DB_PASSWORD='...'
#   ./migrate-db.sh            # asks before touching the target
#   CONFIRM=1 ./migrate-db.sh  # non-interactive
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="${DUMP_DIR:-$SCRIPT_DIR/dumps}"
TS="$(date +%Y%m%d-%H%M%S)"
DUMP_FILE="$DUMP_DIR/dump_$TS.sql"

die() { echo "ERROR: $*" >&2; exit 1; }
redact() { printf '%s' "$1" | sed -E 's#(://[^:/@]+:)[^@]*@#\1***@#'; }

command -v pg_dump >/dev/null 2>&1 || die "pg_dump not found in PATH"
command -v psql    >/dev/null 2>&1 || die "psql not found in PATH"
: "${SOURCE_DATABASE_URL:?Set SOURCE_DATABASE_URL}"
: "${TARGET_DATABASE_URL:?Set TARGET_DATABASE_URL}"
mkdir -p "$DUMP_DIR"

echo "==> Source (read-only): $(redact "$SOURCE_DATABASE_URL")"
echo "==> Target (overwrite): $(redact "$TARGET_DATABASE_URL")"
echo "==> Dump file:          $DUMP_FILE"

if [ "${CONFIRM:-0}" != "1" ]; then
  echo "This DUMPS the source (read-only) and OVERWRITES matching tables on the TARGET."
  printf "Type 'yes' to continue: "; read -r ans
  [ "$ans" = "yes" ] || die "Aborted by user"
fi

echo "==> [1/3] Dumping source ..."
if [ -n "${SOURCE_DB_PASSWORD:-}" ]; then export PGPASSWORD="$SOURCE_DB_PASSWORD"; fi
pg_dump "$SOURCE_DATABASE_URL" --format=plain --no-owner --no-privileges --clean --if-exists --file="$DUMP_FILE"
unset PGPASSWORD
# pg_dump 17+ emits `SET transaction_timeout` that servers < 17 reject; safe to drop.
if grep -q '^SET transaction_timeout' "$DUMP_FILE"; then
  grep -v '^SET transaction_timeout' "$DUMP_FILE" > "$DUMP_FILE.tmp" && mv "$DUMP_FILE.tmp" "$DUMP_FILE"
fi

echo "==> [2/3] Restoring into target ..."
if [ -n "${TARGET_DB_PASSWORD:-}" ]; then export PGPASSWORD="$TARGET_DB_PASSWORD"; fi
psql "$TARGET_DATABASE_URL" --set=ON_ERROR_STOP=on --single-transaction --quiet --file="$DUMP_FILE"

echo "==> [3/3] Row counts on target:"
psql "$TARGET_DATABASE_URL" --quiet --command='DO $$ DECLARE r record; BEGIN FOR r IN SELECT schemaname, relname FROM pg_stat_user_tables LOOP EXECUTE format($q$ANALYZE %I.%I$q$, r.schemaname, r.relname); END LOOP; END $$;'
psql "$TARGET_DATABASE_URL" --quiet --command="SELECT schemaname||'.'||relname AS table, n_live_tup AS rows FROM pg_stat_user_tables ORDER BY 1;"
unset PGPASSWORD

echo "Done. Dump kept at: $DUMP_FILE"
```

> Dump chứa data thật (có thể gồm password hash, email). **Đừng commit file dump lên git** - thêm `dumps/` và `*.sql` vào `.gitignore`. Nếu để script `.sh` trong repo trên Windows, thêm `*.sh text eol=lf` vào `.gitattributes` để script không bị CRLF làm hỏng khi chạy trên Linux.

---

## ⚠️ Troubleshooting / Lưu ý

| Vấn đề | Nguyên nhân | Cách xử lý |
|---|---|---|
| `export: command not found` | Đang gõ trong **PowerShell** | Mở **Git Bash** (script là bash). Hoặc trong PowerShell dùng `$env:VAR='...'` |
| Kết nối hỏng dù đúng mật khẩu | Mật khẩu có `@ % $ /` nhét trong URL -> vỡ parsing | Để URL không mật khẩu + dùng `PGPASSWORD` (Bước 2) |
| `unrecognized configuration parameter "transaction_timeout"` | Dump bằng pg_dump 17+ restore vào server < 17 | Strip dòng đó (Bước 5) |
| `permission denied to create extension "..."` | User đích không đủ quyền tạo extension | Nhờ superuser tạo trước trên DB đích: `CREATE EXTENSION IF NOT EXISTS <ten>;` (vd `citext`, `unaccent`, `uuid-ossp`) rồi restore lại |
| `WARNING: permission denied to analyze "pg_..."` | `ANALYZE;` toàn cục đụng system catalog mà user không phải superuser | **Vô hại** - bảng app vẫn được analyze. Hoặc chỉ analyze bảng user (script đã làm vậy) |
| `relation "..." does not exist` khi verify | Bảng nằm ở schema khác `public` (vd `drizzle`) | Dùng tên đầy đủ `schema.table` (block verify Bước 7 đã tự xử lý) |
| `SSL connection required` | DB bắt buộc SSL | Thêm `?sslmode=require` vào cuối connection string |
| `Connection refused` ở đích | Chưa mở SSH tunnel tới VPS đích | Mở tunnel trước (xem guide SSH Tunnel) |

**Rollback:** DB đích chỉ chứa dữ liệu của lần migrate này nên rất an toàn - chạy lại script (idempotent) hoặc `psql "$TARGET_DATABASE_URL" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"` rồi restore lại. Nguồn không bao giờ bị đụng.

---

## 🔗 Liên quan

- [Clone PostgreSQL Database từ VPS về Local (Windows)](./clone-postgres-vps-to-local-windows.md) - lấy bản sao về máy dev (custom format, đổi port local)
- [Kết nối Database qua SSH Tunnel (Local Dev) & Localhost (Production)](./ssh-tunnel-database-local.md) - mở tunnel tới DB trên VPS
- [How to Setup PostgreSQL on a VPS](./setup-postgresql-on-vps.md)
