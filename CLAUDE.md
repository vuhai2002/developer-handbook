# Developer Handbook - hướng dẫn cho Claude Code

Kho cẩm nang dev cá nhân: các guide how-to (markdown) chia theo folder chủ đề - `vps/`, `database/`, `integrations/`, `dev-tools/`; `README.md` ở gốc là index.

## Repo này là PUBLIC (cực kỳ quan trọng)

Repo được share công khai. TUYỆT ĐỐI không để giá trị thật/nhạy cảm lọt vào bất kỳ file nào:
- Không domain/subdomain thật, không IP thật, không tên bucket/account ID thật.
- Không API key, token, password, connection string, secret.
- Mọi guide viết bằng **placeholder generic**: `example.com`, `app.example.com`, `<bucket>`, `fNNN`, `<path>`, `<token>`...
- Trước khi commit file mới: quét lại tìm giá trị thật lọt vào (grep domain thật, IP `([0-9]{1,3}\.){3}`, `password`, `token`, `secret`, `Bearer`).

## Văn phong

- Tiếng Việt, thực dụng, copy-paste được.
- **GIỮ dấu tiếng Việt ở MỌI nơi, KỂ CẢ trong code block / comment** - không strip thành không dấu (vd phải viết "Tiền đề", "phụ đề", "để TRỐNG", không phải "Tien de").
- Punctuation ASCII: `-` (không em-dash), `->` (không mũi tên unicode), `"` thẳng (không cong).

## Thêm guide mới

Dùng skill **`/add-guide`** (`.claude/skills/add-guide/`) - nó lo đúng format (Quick Reference + Step by Step), cập nhật README, quét bảo mật, rồi commit `docs: ...` + push. Khi người dùng nói "thêm guide / lưu cách làm này vào handbook", làm theo skill đó.
