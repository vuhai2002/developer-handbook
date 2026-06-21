# Hướng dẫn: Quay ngược commit (Git Rollback) & Cập nhật an toàn trên VPS

Tài liệu này hướng dẫn cách để đưa dự án của bạn (Local) về một commit cũ, sau đó ép đẩy (force push) lên remote và cập nhật lại server (VPS) một cách an toàn mà không bị lỗi conflict.

## 1. Thao tác trên máy cá nhân (Local)

Nếu bạn code bị lỗi và muốn huỷ bỏ các commit gần đây, quay về trạng thái của một commit cũ (ví dụ commit có mã hash `f387e83`):

```bash
# 1. Reset nhánh hiện tại về đúng trạng thái của commit cũ (bỏ các thay đổi sau đó)
git reset --hard f387e83

# 2. Xoá lịch sử trên remote thay bằng lịch sử hiện tại (Force push)
git push origin main --force
```

> **⚠️ Cẩn thận:** Nếu bạn làm việc nhóm, `force push` có thể xoá mất code của người khác. Hãy thông báo cho team trước khi thực hiện.

---

## 2. Thao tác trên máy chủ (VPS / Remote)

Sau khi `force push` từ local, code ở VPS vẫn là code trước khi rollback. 
Tuyệt đối **KHÔNG NÊN** dùng `git pull` lúc này vì cây lịch sử đã bị rẽ nhánh (diverged), dễ gây ra `merge conflict`.

Cách xử lý an toàn nhất trên VPS là reset để nó khớp 100% với branch remote:

```bash
# SSH vào VPS và chuyển đến thư mục project
cd /path/to/your/project

# 1. Fetch thông tin mới nhất từ origin (mà không tự động merge)
git fetch origin

# 2. Hard reset nhánh hiện tại theo đúng nhánh main trên origin
git reset --hard origin/main
```

---

## 3. Rebuild và Restart dịch vụ

Sau khi code trên VPS đã chuẩn về cũ, bạn cần khởi chạy / build lại để cập nhật ứng dụng đang chạy.

**Với Next.js, React, Node.js nói chung:**
```bash
npm install
npm run build
```

**Với PM2 (Quản lý tiến trình):**
```bash
pm2 restart <tên-app>
# hoặc
pm2 reload all
```

**Với Docker Compose:**
```bash
docker compose down
docker compose up -d --build
```

**Với ứng dụng .NET:**
```bash
dotnet publish -c Release
# Sau đó restart service, vd: systemctl restart <tên-service>
```

---

## 🔥 Lưu ý quan trọng về Cache

Nếu sau khi bạn đã rollback server thành công và cũng đã restart service nhưng load lại trang web vẫn thấy tính năng / giao diện cũ, vấn đề 99% nằm ở **Cache**.

Bạn nên kiểm tra và xoá các loại cache sau:
- Trình duyệt web (cửa sổ ẩn danh / Disable cache trong tab Network)
- Cache của CDN (ví dụ Cloudflare)
- Service Worker trong (Application tab trên Google Chrome)
- Next.js hay SSR frameworks (xoá thư mục build `.next`, `dist`...)
