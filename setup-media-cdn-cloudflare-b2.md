# Phục vụ Media qua Cloudflare CDN + Backblaze B2 (Egress miễn phí)

Hướng dẫn cấu hình phục vụ file tĩnh dung lượng lớn (ảnh, audio, video, phụ đề, font, JSON...) từ **Backblaze B2** thông qua **Cloudflare** làm CDN, truy cập tại `https://media.example.com/<path>`.

**Lợi ích:**
- Cache toàn cầu của Cloudflare -> tải nhanh, giảm tải về B2.
- **Egress B2 miễn phí** khi traffic đi qua Cloudflare (Bandwidth Alliance) - chỉ trả tiền lưu trữ, không trả tiền băng thông ra.
- HTTPS tự động + ẩn endpoint B2 thật khỏi người dùng cuối.

**Luồng request:**

```
Browser
  -> https://media.example.com/<path>              (qua Cloudflare, proxied)
  -> [URL Rewrite Rule] đổi path -> /file/<bucket>/<path>
  -> Backblaze B2 (bucket public)                  (egress free + có cache CF)
```

> Quy ước trong bài: thay `media.example.com` (subdomain media), `app.example.com` (domain app chính), `<bucket>` (tên bucket B2 của bạn), `fNNN.backblazeb2.com` (B2 download host của bạn - xem Bước 0) bằng giá trị thực của bạn.

---

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

Toàn bộ làm trong Cloudflare dashboard của domain (trừ bước verify dùng terminal).

```text
# 0. Tiền đề: bucket B2 = Public + đã upload; domain đã trên Cloudflare.
#    Tìm B2 download host: B2 console -> Browse Files -> bấm 1 file -> xem "Friendly URL"
#    -> lấy phần fNNN.backblazeb2.com (vd f003, f004...). URL native B2: https://fNNN.backblazeb2.com/file/<bucket>/<key>

# 1. DNS  (Cloudflare -> DNS -> Add record)
Type=CNAME   Name=media   Target=fNNN.backblazeb2.com   Proxy status=Proxied (đám mây CAM)

# 2. SSL/TLS -> Overview -> Encryption mode = Full

# 3. URL Rewrite Rule   (Rules -> Overview -> URL Rewrite Rules -> Create rule)
Rule name:   media-b2-path-rewrite
If match:    Wildcard pattern  ->  Request URL = https://media.example.com/*
Then:        Path -> Target path = /*        Path -> Rewrite to = /file/<bucket>/${1}
             Query -> để TRỐNG cả 2 ô
Place at:    Last        -> Deploy

# 4. CORS   (Rules -> Overview -> Response Header Transform Rules -> Create)  [CHỈ CẦN nếu app fetch()/XHR/<track> file qua JS: phụ đề, JSON, font]
Rule name:   media-cors
If:          Hostname  equals  media.example.com
Then:        Set static -> Header name = Access-Control-Allow-Origin , Value = *   (chặt hơn: https://app.example.com)
             -> Deploy

# 5. Cache Rule   (Caching -> Cache Rules -> Create rule)
Rule name:   media-cache
If:          Hostname  equals  media.example.com
Then:        Cache eligibility = Eligible | Edge TTL = Override origin 1 month | Browser TTL = Override origin 1 day
             -> Deploy

# 6. Verify  (Windows PowerShell dùng curl.exe, KHÔNG phải curl)
curl.exe -I https://media.example.com/<path>                              # dùng 1 file CÓ THẬT; 200 + content-type đúng; chạy LẦN 2 -> cf-cache-status: HIT
curl.exe -I -H "Range: bytes=0-1023" https://media.example.com/<video.mp4>  # 206 Partial Content (tua video)
curl.exe -I https://media.example.com/<subtitle.vtt>                      # phải có header access-control-allow-origin (nếu làm Bước 4)
```

---

## 📝 Các bước thực hiện (Step by Step)

### Bước 0: Tiền đề + tìm B2 download host

- **Bucket B2** đặt **Public** và đã upload file. Key (đường dẫn file trong bucket) có dạng `<path>`, ví dụ `images/banner.jpg` hay `course-01/audio/u01.mp3`.
- **Domain** đã nằm trên Cloudflare (đã trỏ nameserver về Cloudflare).
- **Xác định B2 download host của bạn:** vào B2 console -> **Browse Files** -> bấm vào 1 file bất kỳ -> nhìn mục **Friendly URL**. Phần đầu có dạng `fNNN.backblazeb2.com` (ví dụ `f003`, `f004`...). Mỗi vùng/tài khoản B2 có số `fNNN` khác nhau, dùng đúng số của bạn.
- URL native của B2 luôn có dạng: `https://fNNN.backblazeb2.com/file/<bucket>/<key>`.

> Tại sao không cho app gọi thẳng URL B2 `fNNN...`? Vì (1) gọi thẳng sẽ bị **tính phí egress B2** (không qua Cloudflare nên mất ưu đãi Bandwidth Alliance), (2) lộ endpoint B2 thật. Ta đặt 1 subdomain riêng đi qua Cloudflare để vừa free egress vừa có cache + HTTPS.

### Bước 1: DNS - trỏ subdomain media về B2

Cloudflare dashboard -> chọn domain -> **DNS** -> **Add record**:

| Field | Value |
|---|---|
| Type | `CNAME` |
| Name | `media` (sẽ thành `media.example.com`) |
| Target | `fNNN.backblazeb2.com` (host ở Bước 0) |
| Proxy status | **Proxied** (đám mây CAM) - **bắt buộc** |
| TTL | Auto |

> Phải là **Proxied (cam)**. Để "DNS only" (xám) thì traffic không qua Cloudflare -> mất cache, mất egress free, và các Rule bên dưới không chạy.

### Bước 2: SSL/TLS = Full

Cloudflare -> **SSL/TLS** -> **Overview** -> Encryption mode = **Full**.

Cloudflare nói chuyện với B2 qua HTTPS; B2 có chứng chỉ hợp lệ cho `*.backblazeb2.com`. "Full (strict)" cũng chạy; nếu gặp lỗi 525/526 thì hạ về **Full**.

### Bước 3: URL Rewrite Rule - chèn tiền tố `/file/<bucket>`

B2 phục vụ tại `/file/<bucket>/<key>`, nhưng ta muốn app gọi gọn `media.example.com/<key>` (không kèm `/file/<bucket>`). Rule này chèn tiền tố đó vào lúc Cloudflare chuyển request về B2.

Vào **Rules -> Overview** -> khối **URL Rewrite Rules** -> **Create rule**. Điền:

- **Rule name:** `media-b2-path-rewrite`
- **If incoming requests match...** -> chọn **Wildcard pattern**
- **Request URL:** `https://media.example.com/*`
- **Then rewrite the path and/or query...**
  - **Path -> Target path:** `/*`
  - **Path -> Rewrite to:** `/file/<bucket>/${1}`
  - **Query -> Target query:** để TRỐNG
  - **Query -> Rewrite to:** để TRỐNG (giữ nguyên query string)
- **Place at:** `Last`
- Bấm **Deploy**.

Giải thích: `${1}` = phần mà dấu `*` trong **Target path `/*`** bắt được (toàn bộ path sau dấu `/` đầu tiên).

Kết quả: `media.example.com/images/banner.jpg` -> origin nhận `/file/<bucket>/images/banner.jpg` -> B2 trả file.

> **Cẩn thận dấu `/` thừa:** ô Target path / Rewrite to thường có sẵn 1 dấu `/` xám ở đầu (prefix cố định của Cloudflare). Giá trị cuối phải là `/*` và `/file/<bucket>/${1}` - KHÔNG để thành `//*` hay `//file/...` (dư slash -> B2 trả 404). Sau khi Deploy, dùng curl ở Bước 6 để xác nhận.

### Bước 4: CORS - chỉ khi app `fetch()` file qua JavaScript

Cần CORS **chỉ khi** trình duyệt tải file bằng JS/XHR/`fetch()` hoặc thẻ `<track>` (vd: file phụ đề `.txt`/`.vtt`, JSON, font tải động) - đây là request **cross-origin** (từ `app.example.com` sang `media.example.com`), thiếu header CORS sẽ bị trình duyệt chặn.

> Ảnh/audio/video qua thẻ `<img>` / `<audio>` / `<video>` thì **KHÔNG cần** CORS. Nếu app bạn chỉ dùng các thẻ này, có thể bỏ qua bước này.

Vào **Rules -> Overview** -> khối **Response Header Transform Rules** -> **Create rule**:

- **Rule name:** `media-cors`
- **If...:** Field `Hostname` - `equals` - `media.example.com`
- **Then...:** **Set static** -> Header name `Access-Control-Allow-Origin`, Value `*`
- **Deploy**.

Dùng `*` an toàn khi media là **public** và request **không kèm credentials** (xem mục Bảo mật). Muốn chặt hơn, đặt Value = `https://app.example.com` (chỉ cho domain app của bạn).

### Bước 5: Cache Rule - cache media lâu

Media gần như bất biến (không đổi nội dung) -> cache lâu để nhanh + đỡ tốn request về B2.

Vào **Caching** (menu trái) -> **Cache Rules** -> **Create rule**:

- **Rule name:** `media-cache`
- **If...:** Field `Hostname` - `equals` - `media.example.com`
- **Then...:**
  - **Cache eligibility:** `Eligible for cache`
  - **Edge TTL:** `Override origin` -> `1 month`
  - **Browser TTL:** `Override origin` -> `1 day`
- **Deploy**.

> Nếu sau này bạn thay file nhưng giữ NGUYÊN tên (key), cache CF + trình duyệt có thể còn giữ bản cũ tới khi hết TTL. Cách tránh: đổi tên file khi đổi nội dung (vd thêm version/hash vào tên), hoặc Purge Cache thủ công trong Cloudflare.

### Bước 6: Verify

Chạy trên terminal (Windows PowerShell dùng `curl.exe`, không phải `curl`):

```bash
# 1) File thường (dùng 1 file CÓ THẬT): 200 + content-type đúng
curl.exe -I https://media.example.com/<path>
#    chạy LẦN 2 -> phải thấy header  cf-cache-status: HIT

# 2) Video Range (tua): trả 206 Partial Content
curl.exe -I -H "Range: bytes=0-1023" https://media.example.com/<video.mp4>

# 3) CORS (nếu làm Bước 4): response có header  access-control-allow-origin
curl.exe -I https://media.example.com/<subtitle.vtt>
```

Đạt hết = xong.

### Bước 7: Nối vào app

- Trong code, build URL media = `https://media.example.com/<path>`.
- Nếu framework inline biến lúc **build** (vd Vite `import.meta.env.VITE_*`, Next `NEXT_PUBLIC_*`), đặt biến base URL (vd `MEDIA_BASE_URL=https://media.example.com`) ở **build time**, đừng hardcode trong code.
- **Luôn** truy cập qua subdomain proxied. Nếu lỡ trỏ thẳng URL `fNNN.backblazeb2.com` thì sẽ bị **tính egress B2** (mất ưu đãi free) + lộ endpoint.

---

## ⚠️ Troubleshooting / Lưu ý

| Triệu chứng | Nguyên nhân / cách sửa |
|---|---|
| 404 "file not found" | Sai **URL Rewrite Rule** (Bước 3). Test thẳng B2: `curl.exe -I https://fNNN.backblazeb2.com/file/<bucket>/<key>` - nếu cái này 200 mà qua `media.example.com` 404 -> lỗi ở rule rewrite path. |
| 404 dù rule "trông đúng" | Ô Target path / Rewrite to bị **dư dấu `/`** đầu (thành `//file/...`). Sửa lại đúng `/*` và `/file/<bucket>/${1}`. |
| Console báo "blocked by CORS" | Thiếu **CORS rule** (Bước 4) hoặc sai hostname trong điều kiện. Chỉ ảnh hưởng file tải qua JS (phụ đề/JSON/font). |
| 525 / 526 (SSL) | Đổi SSL/TLS mode về **Full** (Bước 2). |
| `cf-cache-status` luôn `MISS` | Kiểm tra **Cache Rule** (Bước 5). B2 có thể gửi `Cache-Control` ngắn -> "Override origin" Edge TTL sẽ ghi đè. |
| 401 / 403 từ B2 | Bucket chưa **Public** -> vào B2 đặt lại bucket = Public. |
| DNS không phân giải | Record `media` chưa **Proxied**, hoặc chưa lưu / chưa kịp lan truyền. |

### Bảo mật & Lưu ý quan trọng

- **Bucket Public = ai có URL đều tải được.** Chỉ để file công khai (media của app) trong bucket này; KHÔNG để file nhạy cảm/riêng tư.
- **Cookie phiên của app để host-only:** đừng set `Domain=.example.com` cho cookie đăng nhập. Để host-only thì cookie chỉ gửi cho `app.example.com`, KHÔNG bị gửi kèm sang `media.example.com`. Nhờ vậy CORS `Access-Control-Allow-Origin: *` mới an toàn (request media không mang theo credentials).
- **Không bao giờ trả về `*` cho CORS nếu cần gửi credentials.** Trình duyệt chặn `*` + credentials; khi đó phải đặt origin cụ thể (`https://app.example.com`) và bật `Access-Control-Allow-Credentials` - nhưng với media public thì không nên dùng credentials.
- **Luôn đi qua subdomain proxied**, đừng để URL `fNNN.backblazeb2.com` lọt vào code/HTML public (mất free egress + lộ endpoint).

### Chi phí

Traffic **Cloudflare <-> B2** nằm trong **Bandwidth Alliance** -> **egress B2 miễn phí** khi đi qua Cloudflare (proxied). Người dùng tải qua cache Cloudflare. Gói **Cloudflare Free** đủ cho nhu cầu thông thường. Bạn chỉ trả tiền **lưu trữ** B2 (rẻ), gần như không trả tiền băng thông.
