# Simple steps to config a new VPS

Watch the accompanying tutorial on YouTube: https://www.youtube.com/watch?v=2T_Dx7YgBFw

## Instructions & Commands

### 1. Get your VPS server using password

### 2. Log into your server as root
```bash
ssh root@<your-server-ip>
```
Then type your password.

### 3. Update Linux packages
```bash
apt update && apt upgrade -y
```

### 4. Create a new user
```bash
adduser <username>
```
Example:
```bash
adduser vuhai
```

### 5. Add the user to the sudo group
```bash
usermod -aG sudo <username>
```

### 6. Logout from your server
```bash
logout
```

### 7. Log in with your new user account
```bash
ssh <username>@<your-server-ip>
```
Example:
```bash
ssh vuhai@128.199.244.223
```

### 8. Check if sudo works
```bash
sudo -v
```
If you don't get an error, it's good.

### 9. Create the SSH key folder
```bash
mkdir ~/.ssh && chmod 700 ~/.ssh
```

### 10. Confirm the folder exists
```bash
ls -a
```

### 11. Logout again
```bash
logout
```

### 12. Generate an SSH key on your local machine

#### Trường hợp 1: Đây là VPS đầu tiên (chưa có SSH key nào)
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

#### Trường hợp 2: Đã có SSH key cho VPS khác (⚠️ Quan trọng)

> **Cảnh báo:** Nếu bạn đã có SSH key (ví dụ `id_ed25519` cho VPS 1), **KHÔNG được** chạy lại lệnh trên rồi nhấn Enter liên tục — nó sẽ **ghi đè** lên key cũ và bạn sẽ mất quyền truy cập VPS 1!

Thay vào đó, dùng cờ `-f` để đặt một tên riêng cho key mới:

**Windows (PowerShell):**
```powershell
ssh-keygen -t ed25519 -C "your_email@example.com" -f $env:USERPROFILE\.ssh\id_ed25519_<tên-vps>
```

**macOS / Linux:**
```bash
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519_<tên-vps>
```

Ví dụ tạo key cho VPS tên "openclaw":
```powershell
ssh-keygen -t ed25519 -C "vuhai@gmail.com" -f $env:USERPROFILE\.ssh\id_ed25519_openclaw
```

Sau khi chạy xong, trong thư mục `.ssh` sẽ xuất hiện thêm 2 file mới:
- `id_ed25519_openclaw` (Private key)
- `id_ed25519_openclaw.pub` (Public key)

Các key cũ (`id_ed25519`, `id_ed25519.pub`) vẫn được giữ nguyên.

### 13. Push the SSH key to your server

Thay `id_ed25519.pub` bằng tên file `.pub` tương ứng nếu bạn đã đặt tên riêng ở bước 12.

#### Windows
```powershell
# Key mặc định:
scp $env:USERPROFILE/.ssh/id_ed25519.pub <username>@<your-server-ip>:~/.ssh/authorized_keys

# Key có tên riêng (ví dụ cho VPS "openclaw"):
scp $env:USERPROFILE/.ssh/id_ed25519_openclaw.pub vuhai@178.128.27.49:~/.ssh/authorized_keys
```

#### macOS
```bash
scp ~/.ssh/id_ed25519.pub <username>@<your-server-ip>:~/.ssh/authorized_keys
```

#### Linux
```bash
ssh-copy-id <username>@<your-server-ip>
```

### 13.5. Cấu hình SSH Config (Bắt buộc nếu dùng nhiều key)

> **Lưu ý:** Nếu bạn đặt tên key khác mặc định (vd: `id_ed25519_openclaw`), SSH sẽ **không tự nhận ra** key đó khi kết nối. Bạn sẽ vẫn bị hỏi mật khẩu dù đã đẩy public key lên VPS!

Có 2 cách xử lý:

#### Cách 1: Dùng cờ `-i` mỗi lần SSH (Tạm thời)
```bash
ssh -i ~/.ssh/id_ed25519_openclaw vuhai@178.128.27.49
```

#### Cách 2: Thiết lập file `~/.ssh/config` (Khuyến nghị ✅)

Mở (hoặc tạo mới) file `~/.ssh/config` và thêm cấu hình cho từng VPS:

**Windows:** File nằm ở `C:\Users\<username>\.ssh\config` (không có đuôi `.txt`)

```text
# VPS 1 - Dùng key mặc định
Host vps1
    HostName <IP-VPS-1>
    User <username>
    IdentityFile ~/.ssh/id_ed25519

# VPS 2 - Dùng key tên riêng
Host openclaw
    HostName 178.128.27.49
    User vuhai
    IdentityFile ~/.ssh/id_ed25519_openclaw
```

Sau khi lưu file config, từ giờ chỉ cần gõ:
```bash
ssh vps1       # Vào VPS 1
ssh openclaw   # Vào VPS 2
```

Không cần nhớ IP, username hay đường dẫn key nữa!

### 14. Log back into your server
```bash
ssh <username>@<your-server-ip>
```

### 15. Open SSH configuration
```bash
sudo nano /etc/ssh/sshd_config
```

#### SSH Hardening
- Disable IPv6: remove comment at line `#AddressFamily any` and replace by:
```text
AddressFamily inet
```
(This disables IPv6 IP addresses and it only keeps IPv4 enabled. This is considered a good security practice because we don’t use IPv6 for anything here. So it’s a good idea to lock this and not make it available anymore because it’s just another attack vector for people to access our server)

- Disable password authentication:
```text
PasswordAuthentication no
```

- Disable root login:
```text
PermitRootLogin no
```

### 16. Clear included SSH config (if exists)
- If there is an included `.conf` file, make it empty. E.g.
```bash
sudo nano /etc/ssh/sshd_config.d/*.conf
```
Delete all content inside the file.

### 17. Restart SSH
```bash
sudo systemctl restart ssh
```
(On some distros it may be `sshd` instead of `ssh`)

### 18. Logout and verify
Ensure root login and password login are disabled.

### 19. Install firewall
```bash
sudo apt install ufw
```

### 20. Whitelist ports
```bash
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
```

### 21. Enable firewall
```bash
sudo ufw enable
```

### 22. Check firewall status
```bash
sudo ufw status
```

### 23. Disable ping (ICMP echo request)
(E.g. `ping 128.199.244.223 -t`). So when we ping our server, we don’t get a response back.

Open firewall rules:
```bash
sudo nano /etc/ufw/before.rules
```

Add the following line under the `# ok icmp codes for INPUT` block:
```text
-A ufw-before-input -p icmp --icmp-type echo-request -j DROP
```

### 24. Reboot the server
```bash
sudo reboot
```

Log back in once the server is reachable again.
