# Simple steps to config a new VPS

Watch the accompanying tutorial on YouTube: https://www.youtube.com/watch?v=2T_Dx7YgBFw

---

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
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### 13. Push the SSH key to your server

#### Windows
```powershell
scp $env:USERPROFILE/.ssh/id_ed25519.pub <username>@<your-server-ip>:~/.ssh/authorized_keys
```
Example:
```powershell
scp $env:USERPROFILE/.ssh/id_ed25519.pub vuhai@128.199.244.223:~/.ssh/authorized_keys
```

#### macOS
```bash
scp ~/.ssh/id_ed25519.pub <username>@<your-server-ip>:~/.ssh/authorized_keys
```

#### Linux
```bash
ssh-copy-id <username>@<your-server-ip>
```

### 14. Log back into your server
```bash
ssh <username>@<your-server-ip>
```

### 15. Open SSH configuration
```bash
sudo nano /etc/ssh/sshd_config
```

#### SSH Hardening
- Disable IPv6:
```text
AddressFamily inet
```

- Disable password authentication:
```text
PasswordAuthentication no
```

- Disable root login:
```text
PermitRootLogin no
```

### 16. Clear included SSH config (if exists)
```bash
sudo nano /etc/ssh/sshd_config.d/*.conf
```
Delete all content inside the file.

### 17. Restart SSH service
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
