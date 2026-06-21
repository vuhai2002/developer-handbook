# Đặt App Ở Đâu Trên VPS? Cấu Trúc Thư Mục Chuẩn (`/opt/apps`)

Khi clone code một app về VPS để chạy (Docker), nên đặt nó ở thư mục nào cho chuẩn production mà không phải `sudo` mỗi lần `git pull`? Hướng dẫn này chốt quy ước: **đặt mỗi app trong `/opt/apps/<ten-app>`**, chown thư mục cha **một lần duy nhất**, từ đó clone/pull/sửa `.env` đều không cần sudo.

**Các giá trị cần thay** (chỗ nào ghi `<...>` là bạn điền giá trị thật của mình):
- `<username>` - user thường (non-root) bạn đã tạo trên VPS. Xem [config-new-vps](./config-new-vps.md). Vd: `vuhai`.
- `<repo-url>` - URL git của app cần deploy. Vd: `git@github.com:ban/my-api.git`.
- `<ten-app>` - tên thư mục app, **chính là tên repo** do `git clone` tự tạo (không cần đặt trước). Vd: `my-api`.

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

```bash
# 1. Lam 1 LAN DUY NHAT (ca doi): tao /opt/apps thuoc ve user cua ban
sudo install -d -o <username> -g <username> /opt/apps

# 2. Moi app moi - KHONG can sudo, KHONG can dat ten truoc:
cd /opt/apps
git clone <repo-url>            # tu tao /opt/apps/<ten-app> theo ten repo
cd /opt/apps/<ten-app>

# 3. Kiem tra (luu y: /opt/apps KHONG nam trong ~, phai ls /opt)
ls -ld /opt/apps                # owner phai la <username>, mode 755
```

> ⚠️ **TUYỆT ĐỐI KHÔNG** `chown` cả `/opt`. Docker đã tạo sẵn `/opt/containerd` (thuộc root) trong đó. Chỉ chown đúng `/opt/apps`.

## 📝 Các bước thực hiện (Step by Step)

### Bước 1: Tạo thư mục cha `/opt/apps` (chỉ 1 lần cho cả VPS)

`/opt` mặc định thuộc `root`, nên không clone thẳng vào được nếu không sudo. Cách gọn nhất là tạo sẵn 1 thư mục cha `/opt/apps` và gán quyền sở hữu cho user của bạn **một lần duy nhất**:

```bash
sudo install -d -o <username> -g <username> /opt/apps
```

- `install -d` = `mkdir` + set owner/group + mode 755 gọn trong 1 lệnh.
- **chown** (change owner) = đổi chủ sở hữu thư mục. Ở đây gán `/opt/apps` cho `<username>` để về sau khỏi cần sudo.
- **mode 755** = bộ quyền: chủ sở hữu (bạn) được đọc/ghi/chạy; user khác chỉ được đọc và đi vào, không sửa.
- Thay `<username>` bằng user thường của bạn (vd: user tạo ở guide [config-new-vps](./config-new-vps.md)).

### Bước 2: Clone app mới (từ giờ không cần sudo)

Vì `/opt/apps` giờ đã thuộc về bạn, `git clone` sẽ tự tạo thư mục con theo tên repo mà không cần đặt tên trước, không cần sudo:

```bash
cd /opt/apps
git clone <repo-url>            # vd: tao /opt/apps/my-api
cd /opt/apps/<ten-app>
```

Tạo file `.env` trực tiếp trong thư mục app này, rồi `docker compose up -d` như bình thường.

### Bước 3: Cấu trúc thư mục thu được (toàn cảnh từ gốc `/`)

`/opt/apps` và home của bạn (`/home/<username>`, tức `~`) là **2 nhánh tách biệt** từ gốc `/`. Đây là lý do `ls ~` sẽ không thấy app:

```text
/                                <- goc he thong (2 nhanh tach biet ben duoi)
├── home/
│   └── <username>/              <- ~ (home cua ban) - APP KHONG nam o day
│       └── <thu-muc-rieng>/     <- cac thu muc ca nhan khac cua ban
└── opt/
    ├── apps/                    <- THUOC <username>: clone/pull KHONG can sudo
    │   ├── <ten-app>/
    │   │   ├── .git/
    │   │   ├── Dockerfile
    │   │   ├── docker-compose.yml
    │   │   ├── .env             <- tao truc tiep o day
    │   │   └── src/ ...
    │   └── <app-2>/
    └── containerd/              <- cua Docker (root): DUNG dung vao
```

## ⚠️ Troubleshooting / Lưu ý

### Tại sao chọn `/opt` thay vì `~/apps`?
Sau khi đã `chown`, workflow hằng ngày của `/opt/apps` và `~/apps` **y hệt nhau** (đều không cần sudo). Chọn `/opt` vì:
- **Convention production** - theo chuẩn **FHS** (Filesystem Hierarchy Standard - quy ước bố trí thư mục chuẩn trên Linux), `/opt` là nơi dành cho phần mềm ứng dụng cài thêm (add-on). Người bàn giao/quản trị sau quen tìm app ở `/opt`, không soi `/home`.
- **Không dính account cá nhân** - lỡ sau này xóa/đổi user thì app không bị kẹt trong home của user đó.

Nếu bạn thích `~/apps` thì vẫn hoàn toàn ổn về mặt kỹ thuật - không thua thiệt gì. Đây là lựa chọn convention, không phải đúng/sai.

### `ls ~` không thấy `/opt/apps`?
Bình thường (xem sơ đồ cây ở Bước 3). `/opt/apps` bắt đầu bằng `/` nên nằm ở **gốc hệ thống** (`/opt`), khác cây với home của bạn (`/home/<username>`). Muốn thấy thì:
```bash
ls /opt           # hoac
cd /opt/apps
```

### Nhiều người cùng quản trị VPS (optional)
Nếu có nhiều admin, thay vì gán `/opt/apps` cho 1 user, tạo group `deploy` + bật setgid để file mới luôn kế thừa group:
```bash
sudo groupadd -f deploy
sudo usermod -aG deploy <username>
sudo install -d -o root -g deploy -m 2775 /opt/apps   # 2775 = setgid
# logout/login lai cho group co hieu luc
```
- **setgid** (số `2` đứng đầu trong `2775`): mọi file/thư mục tạo trong `/opt/apps` sẽ tự thừa hưởng group `deploy`, nhờ vậy admin nào trong group cũng đọc/sửa được - không cần chỉnh quyền thủ công.
- Sau này thêm người: `sudo usermod -aG deploy <user-moi>` (rồi user đó logout/login lại).

### Vị trí những thứ liên quan khác
Guide này chỉ bàn **chỗ đặt code app**. Các thành phần khác đặt nơi riêng:
- **Caddy reverse proxy**: đặt riêng, KHÔNG nằm trong thư mục app. Tùy cách bạn chạy: Caddy trên **host** (cài qua apt) thì config ở `/etc/caddy/Caddyfile`; Caddy trong **Docker** thì config ở `~/services/caddy/` (xem [caddy-reverse-proxy-guide](./caddy-reverse-proxy-guide.md)). Dù cách nào, Caddy là hạ tầng dựng 1 lần nên không để chung trong `/opt/apps`.
- **Database**: dùng Postgres sẵn trên host hay bundle trong Docker - xem [setup-postgresql-on-vps](../database/setup-postgresql-on-vps.md) và [ssh-tunnel-database-local](../database/ssh-tunnel-database-local.md).
- **Data có state** (db, file upload): ưu tiên **Docker named volume** (Docker tự quản lý ở `/var/lib/docker/volumes`, không mất khi rebuild container) hoặc **bind mount** (map thẳng một thư mục như `./data` trong app vào container). Tránh để data sống bên trong container vì rebuild là mất sạch.
