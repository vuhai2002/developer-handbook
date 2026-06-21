# Hướng dẫn Debug và Bypass SSL Pinning App Android trên Giả Lập

Hướng dẫn này giúp bạn "soi" (inspect) traffic (Request/Response API) của một ứng dụng Android từ Google Play Store, đặc biệt là các app Production có sử dụng **SSL Pinning**, bằng sự kết hợp của **LDPlayer 9** và **HTTP Toolkit**.

## 🛠️ Trình độ / Yêu cầu
- Máy tính chạy Windows.
- Khuyên dùng giả lập **LDPlayer 9** (chạy Android 9) vì có sẵn quyền Root và dễ cấu hình kết nối.
- Sử dụng **HTTP Toolkit** (đóng vai trò MITM proxy + tự động tiêm mã bypass SSL).

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

Nếu bạn đã setup xong 1 lần, những lần sau chỉ cần làm theo trình tự này:
1. Mở LDPlayer.
2. Mở Terminal (CMD/PowerShell) chạy lệnh: `adb connect 127.0.0.1:5555`
3. Mở HTTP Toolkit.
4. Chọn kết nối **Android 9 emulator**.
5. Cấp quyền Root / VPN trên LDPlayer (nếu nó hỏi).
6. Mở App cần soi và bắt đầu đọc Traffic!

---

## 📝 Các bước thực hiện (Step by Step)

### Bước 1: Chuẩn bị môi trường cài đặt giả lập (Bật Root)

1. Tải và cài đặt giả lập **LDPlayer 9**.
2. Bật "Quyền Root" (Root permission) và "ADB Debugging" trên LDPlayer:
   - Mở LDPlayer. Click vào biểu tượng **Cài đặt** (Bánh răng) ở thanh công cụ bên phải (hoặc góc trên phải).
   - Chọn tab **Cài đặt khác** (Other Settings).
   - Tìm **Quyền Root** (Root permission) và đổi từ Tắt (Disable) sang **Bật** (Enable).
   - Tại mục **ADB Debugging** (ngay bên dưới hoặc cùng bảng), chọn **Open Local Connection** (hoặc Enable) để mở cổng ADB Local.
   - Nhấn nút **Lưu cài đặt** (Save settings).
   - BẮT BUỘC chọn **Khởi động lại ngay** (Restart now) để có hiệu lực.
3. Đăng nhập Google Play, rồi tải và cài đặt Application bạn muốn debug vào giả lập.

### Bước 2: Khắc phục lỗi và kết nối qua HTTP Toolkit

Thường thì HTTP Toolkit sẽ tự chọn dạng *"Android Device via ADB"*, nhưng nếu nó không nhận thấy (do dùng khác phiên bản ADB hoặc sai port):

1. Mở LDPlayer lên và đợi vào màn hình chính.
2. Mở CMD / PowerShell trên Windows.
3. Kết nối thủ công tới cổng ADB của giả lập (cổng mặc định cho 1 instance là `5555`). Gõ lệnh:
   ```bash
   adb connect 127.0.0.1:5555
   ```
   *Lưu ý: Nếu nhận lỗi `adb is not recognized`, hãy trỏ trực tiếp đến thư mục LDPlayer. Đặc biệt trong PowerShell, bạn phải dùng `.\adb.exe`:*
   ```powershell
   cd C:\LDPlayer\LDPlayer9
   .\adb.exe connect 127.0.0.1:5555
   ```
4. Nếu kết nối báo `connected to 127.0.0.1:5555` là thành công.
   *(Trường hợp treo ADB, bạn có thể gõ `adb kill-server` và `adb start-server` sau đó thử lại lệnh connect)*.

### Bước 3: Cấp quyền và kết nối chặn HTTPS với HTTP Toolkit

1. Mở phần mềm **HTTP Toolkit** trên máy tính tính, lúc này nó đã nhìn thấy thiết bị qua ADB.
2. Trên màn hình danh sách thiết bị, hãy tick vào lựa chọn bấm nút cấu hình **"Android 9 emulator"** (Màu xanh dương) thay vì các thiết lập máy cũ (như Samsung S10/S22/G973N... trên bộ nhớ cache).
3. **QUAN TRỌNG:** Ngay khi bấm chọn ở máy tính, mắt bạn hãy nhìn ngay vào màn hình giả lập LDPlayer.
   - Ứng dụng HTTP Toolkit sẽ được push, tự động cài lên giả lập và mở lên.
   - Giả lập sẽ hiện thông báo hỏi **quyền Superuser (Root)** -> Bạn bấm **Cho phép** (Allow) hoặc "Forever".
   - Tiếp tục, app trên giả lập sẽ có cảnh báo cấu hình **Thiết lập VPN** (để route toàn bộ traffic qua nó) -> Bạn bấm **OK**.
4. Khi HTTP Toolkit trên máy tính chuyển trạng thái sang biểu tượng **Connected** màu xanh lá là thành công!

### Bước 4: Bypass SSL tự động và Quan sát

1. Mở app mục tiêu bạn muốn inspect trên giả lập.
2. Máy chủ proxy của HTTP Toolkit (với cơ chế nhúng mã Frida tích hợp) sẽ tự nhận biết và chọc vào app để đánh lừa/ bypass hàm kiểm tra SSL của hệ thống.
3. Quay lại máy tính tại giao diện chính HTTP Toolkit, bạn sẽ thấy đầy đủ chuỗi Traffic:
   - Request Headers (Tokens, Cookie, User-Agent...).
   - Body JSON dữ liệu gửi đi.
   - Raw Response nhận từ Server.
   - Query.

---

## ⚠️ Giải quyết các lỗi nâng cao

App dạng "Production Chuẩn" thỉnh thoảng sẽ có các lớp bảo vệ đặc biệt, nếu bạn vẫn gặp lỗi, có vài cách fix nâng cao:

*   **Chặn giả lập (Emulator Detection) hoặc Root sâu:** Đóng cửa văng (crash) ngay khi mở do check Root. Bạn sẽ cần dùng Thiết bị phụ thật (hoặc cài **Magisk** trên LDPlayer + Module Hide/Zygisk/Denylist) để bypass phát hiện này.
*   **Mã hóa Payload (Application Layer Encryption):** Server đã nhận Request OK, nhưng HTTP Toolkit thấy các ký tự mã hóa lộn xộn thay vì chữ (App dùng key mã hóa RSA/AES trồi trên HTTPS). Phương án là phải dùng JADX để build Decompile APK ra tìm khóa hoặc tự viết code Frida đọc Hook thẳng để bắt Data Raw.
*   **Certificate Pinning Custom Network (OkHttp3/Retrofit):** Proxy báo đỏ, chửi chứng chỉ sai. Cần sử dụng các Script chuẩn cho Universal Pinning Bypass qua công cụ Frida-Tools thay vì auto trên HTTP toolkit.
