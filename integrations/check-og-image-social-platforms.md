# Kiểm tra & Xóa Cache OG Image trên các Nền tảng Mạng xã hội

Sau khi deploy OG tags (Open Graph) cho website, các nền tảng mạng xã hội thường cache bản preview cũ. Hướng dẫn này giúp bạn buộc từng nền tảng quét lại để hiển thị đúng ảnh OG mới.

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

| Nền tảng | Công cụ | URL |
|---|---|---|
| Facebook / Messenger | Sharing Debugger | https://developers.facebook.com/tools/debug/ |
| Twitter / X | Card Validator | https://cards-dev.twitter.com/validator |
| Telegram | Bot @webpagebot | Gửi URL cho bot trên Telegram |
| Zalo | Không có tool | Chờ 24-48h hoặc thêm `?v=2` vào URL |
| LinkedIn | Post Inspector | https://www.linkedin.com/post-inspector/ |

**Thao tác chung:**
```
1. Paste URL website vào tool của từng nền tảng
2. Ấn Scrape / Debug / Inspect
3. Kiểm tra ảnh preview hiển thị đúng chưa
```

## 📝 Các bước thực hiện (Step by Step)

### 1. Facebook / Messenger

Facebook cache OG rất mạnh. Bạn cần dùng **Sharing Debugger** để buộc nó fetch lại.

1. Truy cập [Facebook Sharing Debugger](https://developers.facebook.com/tools/debug/)
2. Paste URL cần kiểm tra, ví dụ: `https://example.com/`
3. Ấn **"Debug"**
4. Kiểm tra phần **"og:image"** — nếu vẫn hiện ảnh cũ hoặc trống:
   - Ấn nút **"Scrape Again"**
   - **Ấn lần 2** cho chắc (Facebook đôi khi cần 2 lần mới cập nhật)
5. Sau khi scrape xong, kiểm tra mục **"Link Preview"** ở cuối trang để thấy ảnh mới

> **Lưu ý:** Bạn cần đăng nhập tài khoản Facebook Developer để sử dụng tool này.

### 2. Twitter / X

1. Truy cập [Twitter Card Validator](https://cards-dev.twitter.com/validator)
2. Paste URL cần kiểm tra
3. Ấn **"Preview card"**
4. Kiểm tra ảnh hiển thị trong card preview

> **Lưu ý:** Twitter yêu cầu thêm các meta tag `twitter:card`, `twitter:image` ngoài OG tags thông thường. Ví dụ:
> ```html
> <meta name="twitter:card" content="summary_large_image" />
> <meta name="twitter:image" content="https://example.com/og-image.png" />
> ```

### 3. Telegram

Telegram cache preview rất nặng, nhưng có bot chuyên xóa cache.

1. Mở Telegram, tìm bot **@webpagebot**
2. Gửi URL cần refresh cho bot, ví dụ:
   ```
   https://example.com/
   ```
3. Bot sẽ tự động fetch lại HTML, xóa cache và trả về preview mới
4. Sau đó gửi lại link trong bất kỳ chat nào — preview sẽ hiển thị ảnh mới

### 4. Zalo

Zalo **không có công cụ debug OG** công khai. Cache của Zalo rất nặng.

**Cách xử lý:**
- **Chờ tự động:** Zalo thường cập nhật cache sau **24-48 giờ**
- **Đánh lừa cache:** Thêm query string vào URL khi gửi:
  ```
  https://example.com/?v=2
  ```
  Zalo sẽ coi đây là URL mới và fetch lại preview
- Mỗi lần cần refresh, tăng số version: `?v=3`, `?v=4`...

### 5. LinkedIn

1. Truy cập [LinkedIn Post Inspector](https://www.linkedin.com/post-inspector/)
2. Paste URL cần kiểm tra
3. Ấn **"Inspect"**
4. Kiểm tra phần preview hiển thị ảnh OG đúng chưa
5. Nếu cần refresh, ấn **"Inspect"** lại lần nữa

## ⚠️ Troubleshooting / Lưu ý

### Ảnh OG không hiển thị dù đã scrape lại

- **Kiểm tra format ảnh:** Một số nền tảng cũ không hỗ trợ `.webp`. Nếu gặp lỗi, convert sang `.png` hoặc `.jpg`:
  ```bash
  # Convert webp sang png (cần cài cwebp tools)
  dwebp og-image.webp -o og-image.png
  
  # Hoặc dùng ffmpeg
  ffmpeg -i og-image.webp og-image.png
  ```
  Sau đó cập nhật tag trong HTML:
  ```html
  <meta property="og:image" content="https://example.com/og-image.png" />
  ```

- **Kiểm tra kích thước ảnh:** Facebook khuyến nghị ảnh OG tối thiểu **1200x630 pixels**

- **Kiểm tra URL ảnh truy cập được:** Paste trực tiếp URL ảnh lên trình duyệt, đảm bảo nó load được (không bị 404, không bị chặn bởi auth)

### Checklist OG Tags chuẩn

```html
<!-- OG Tags cơ bản -->
<meta property="og:title" content="Tiêu đề trang" />
<meta property="og:description" content="Mô tả ngắn về trang" />
<meta property="og:image" content="https://example.com/og-image.png" />
<meta property="og:url" content="https://example.com/" />
<meta property="og:type" content="website" />

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="Tiêu đề trang" />
<meta name="twitter:description" content="Mô tả ngắn về trang" />
<meta name="twitter:image" content="https://example.com/og-image.png" />
```

### Thứ tự ưu tiên format ảnh (tương thích tốt nhất)

1. **PNG** — tương thích tốt nhất trên mọi nền tảng
2. **JPG/JPEG** — tương thích tốt, file nhẹ hơn
3. **WebP** — hỗ trợ trên Facebook, Twitter, LinkedIn (2024+), nhưng một số nền tảng cũ có thể không hiển thị
