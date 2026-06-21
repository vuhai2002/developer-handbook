# Developer Handbook

A personal developer handbook that documents practical setup guides, best practices, and reusable knowledge collected from real-world experience.

This repository is intended to be:
- Simple
- Practical
- Copy-paste friendly
- Beginner-friendly but production-ready

## 📌 Contents

### 🖥️ VPS - dựng & vận hành server
- [Simple steps to config a new VPS](./vps/config-new-vps.md)
- [Đặt App ở đâu trên VPS? Cấu trúc thư mục chuẩn (/opt/apps)](./vps/vps-app-directory-structure.md)
- [VPS Quick Check — Kiểm Tra Nhanh Thông Số VPS](./vps/vps-quick-check.md)
- [How to Setup Caddy Reverse Proxy on a VPS](./vps/caddy-reverse-proxy-guide.md)
- [How to Setup Automated Maintenance Page with Caddy](./vps/caddy-maintenance-page-guide.md)
- [Phục vụ Media qua Cloudflare CDN + Backblaze B2 (Egress miễn phí)](./vps/setup-media-cdn-cloudflare-b2.md)

### 🗄️ Database - PostgreSQL & công cụ DB
- [How to Setup PostgreSQL on a VPS](./database/setup-postgresql-on-vps.md)
- [Tối ưu hiệu suất VPS: Swap, PostgreSQL & DB Pool](./database/optimize-vps-postgresql.md)
- [Fix Docker not connecting to PostgreSQL on VPS](./database/docker-network-postgres-fix.md)
- [Kết nối Database qua SSH Tunnel (Local Dev) & Localhost (Production)](./database/ssh-tunnel-database-local.md)
- [Clone PostgreSQL Database từ VPS về Local (Windows)](./database/clone-postgres-vps-to-local-windows.md)
- [Migrate PostgreSQL Database giữa 2 VPS (pg_dump + restore)](./database/migrate-postgres-vps-to-vps.md)
- [DBeaver Tips and Tricks](./database/dbeaver-tips.md)

### 🔌 Integrations - dịch vụ & API bên thứ 3
- [Hướng dẫn Cài đặt Email bằng Brevo API (Thay thế SMTP)](./integrations/setup-brevo-email.md)
- [Hướng dẫn cấu hình API Key và Webhook SePay](./integrations/setup-sepay-webhook.md)
- [Hướng Dẫn Cấu Hình Vertex AI Để Sử Dụng Gemini API](./integrations/setup-vertex-ai-gemini.md)
- [Cấu hình Google OAuth với Domain mới](./integrations/config-google-oauth-domain.md)
- [Kiểm tra & Xóa Cache OG Image trên các Nền tảng Mạng xã hội](./integrations/check-og-image-social-platforms.md)

### 🧰 Dev Tools - tiện ích dev & local
- [Git Rollback & Safe VPS Update Guide](./dev-tools/git-rollback-vps-guide.md)
- [Bypass SSL Pinning & Debug Android App](./dev-tools/android-app-debug-bypass-ssl.md)
- [Hướng dẫn sửa lỗi kết nối Claude Code trên Windows (ECONNREFUSED & Bun Crash)](./dev-tools/claude-code-windows-fix.md)

(More guides will be added over time.)

## 🚀 Purpose

The goal of this repository is to:
- Avoid repeating the same setup mistakes
- Document proven workflows
- Serve as a quick reference when setting up new environments
- Share clean and minimal guides with others

All documents are written with **clarity > complexity** in mind.

## 🧰 Tech & Topics Covered

Depending on the document, this handbook may include:
- Linux server setup & hardening
- SSH & firewall configuration
- Docker & deployment notes
- Backend development notes
- General developer best practices

## ⚠️ Disclaimer

This handbook reflects **personal experience and preferences**.  
Always adapt configurations to your own security requirements and infrastructure.

## 📄 License

This repository is shared for learning and reference purposes.
Feel free to fork or reuse the content with attribution.
