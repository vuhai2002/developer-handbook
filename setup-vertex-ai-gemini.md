# 🚀 Hướng Dẫn Cấu Hình Vertex AI Để Sử Dụng Gemini API

Hướng dẫn cách setup **Google Cloud Vertex AI** để gọi API các model Gemini (2.5, 3.x...) bằng **Service Account** — phù hợp cho các môi trường không thể dùng Google AI Studio API (VPS, CI/CD, production...).

> **💡 Khi nào cần dùng Vertex AI thay vì AI Studio?**
> - Môi trường bị chặn AI Studio API endpoint
> - Muốn sử dụng **$300 Google Cloud Free Trial Credit**
> - Cần quản lý billing, IAM, logging chuyên nghiệp hơn

---

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

```bash
# 1. Enable APIs
gcloud services enable aiplatform.googleapis.com

# 2. Tạo Service Account + Key
gcloud iam service-accounts create my-ai-worker \
    --display-name="AI Worker"

gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member="serviceAccount:my-ai-worker@<PROJECT_ID>.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"

gcloud iam service-accounts keys create service-account-key.json \
    --iam-account=my-ai-worker@<PROJECT_ID>.iam.gserviceaccount.com

# 3. Cấu hình biến môi trường
export GOOGLE_CLOUD_PROJECT=<PROJECT_ID>
export GOOGLE_CLOUD_LOCATION=global          # ← QUAN TRỌNG: dùng "global" cho model preview
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json

# 4. Cài SDK
pip install google-genai google-auth

# 5. Test nhanh
python3 -c "
from google import genai
from google.oauth2 import service_account
creds = service_account.Credentials.from_service_account_file(
    'service-account-key.json',
    scopes=['https://www.googleapis.com/auth/cloud-platform']
)
client = genai.Client(vertexai=True, project='<PROJECT_ID>', location='global', credentials=creds)
r = client.models.generate_content(model='gemini-2.5-flash', contents='Xin chào')
print(r.text)
"
```

---

## 📝 Các bước thực hiện (Step by Step)

### Bước 1: Enable Vertex AI API

1. Truy cập [Google Cloud Console](https://console.cloud.google.com) → chọn project
2. Vào [APIs & Services → Library](https://console.cloud.google.com/apis/library)
3. Tìm **"Vertex AI API"** → Click **Enable**

Hoặc dùng CLI:
```bash
gcloud services enable aiplatform.googleapis.com
```

> **📝 Lưu ý:** Nếu project cần dùng Cloud Storage (upload file lớn), enable thêm:
> ```bash
> gcloud services enable storage.googleapis.com
> ```

---

### Bước 2: Tạo Service Account

1. Vào [IAM & Admin → Service Accounts](https://console.cloud.google.com/iam-admin/service-accounts)
2. Click **"+ CREATE SERVICE ACCOUNT"**
3. Điền thông tin:
   - **Name:** `my-ai-worker` (hoặc tên tùy ý)
   - **Description:** mô tả mục đích sử dụng
4. Click **"CREATE AND CONTINUE"**
5. **Gán roles** (tùy nhu cầu):

| Role | Mục đích |
|---|---|
| `Vertex AI User` | Gọi API Gemini qua Vertex AI |
| `Storage Object Admin` | Upload/xóa file trên GCS (nếu cần) |

6. Click **"CONTINUE"** → **"DONE"**

> **📝 Ghi chú:** Để test nhanh, có thể gán role **Owner**. Trong production, luôn dùng quyền tối thiểu (principle of least privilege).

---

### Bước 3: Tạo và Tải JSON Key

1. Trong danh sách Service Accounts, click vào service account vừa tạo
2. Chọn tab **"KEYS"**
3. Click **"ADD KEY"** → **"Create new key"**
4. Chọn **JSON** → Click **"CREATE"**
5. File JSON sẽ tự động tải về máy

```bash
# Upload key lên server (nếu cần)
scp ~/Downloads/<KEY_FILE>.json user@<SERVER_IP>:/path/to/project/service-account-key.json
```

> **🔒 BẢO MẬT:** Tuyệt đối **KHÔNG** commit file JSON key lên Git!
> ```bash
> echo "service-account-key.json" >> .gitignore
> ```

---

### Bước 4: Cấu hình biến môi trường

Thêm vào file `.env` của project:

```env
# === VERTEX AI CONFIG ===
GOOGLE_CLOUD_PROJECT=your_project_id
GOOGLE_CLOUD_LOCATION=global
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json

# Model sử dụng
GEMINI_MODEL=gemini-2.5-flash
```

| Biến | Mô tả | Ví dụ |
|---|---|---|
| `GOOGLE_CLOUD_PROJECT` | Project ID trên GCP | `my-project-123456` |
| `GOOGLE_CLOUD_LOCATION` | Endpoint location | `global` hoặc `us-central1` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Đường dẫn file JSON key | `/app/service-account-key.json` |
| `GEMINI_MODEL` | Tên model Gemini | `gemini-2.5-flash` |

---

### Bước 5: Cài đặt SDK

```bash
pip install google-genai google-auth
# Hoặc nếu dùng Node.js:
npm install @google-cloud/vertexai
```

| Package (Python) | Mục đích |
|---|---|
| `google-genai` | SDK chính gọi Gemini qua Vertex AI |
| `google-auth` | Xác thực với Service Account |
| `google-cloud-storage` | Upload file lên GCS (nếu cần) |

---

### Bước 6: Code mẫu sử dụng

#### Python (google-genai SDK)

```python
import os
from dotenv import load_dotenv
from google import genai
from google.genai import types
from google.oauth2 import service_account

load_dotenv()

# Tạo credentials từ Service Account key
creds = service_account.Credentials.from_service_account_file(
    os.getenv('GOOGLE_APPLICATION_CREDENTIALS'),
    scopes=['https://www.googleapis.com/auth/cloud-platform']
)

# Khởi tạo client — dùng location="global" cho model preview
client = genai.Client(
    vertexai=True,
    project=os.getenv('GOOGLE_CLOUD_PROJECT'),
    location=os.getenv('GOOGLE_CLOUD_LOCATION', 'global'),
    credentials=creds
)

# Gọi API
response = client.models.generate_content(
    model=os.getenv('GEMINI_MODEL', 'gemini-2.5-flash'),
    contents='Xin chào, hãy giới thiệu bạn là ai?',
    config=types.GenerateContentConfig(
        max_output_tokens=1024,
        temperature=0.7
    )
)
print(response.text)
```

#### REST API (cURL)

```bash
# Lấy access token
ACCESS_TOKEN=$(gcloud auth print-access-token)

# Gọi API với Global endpoint
curl -X POST \
  "https://aiplatform.googleapis.com/v1/projects/<PROJECT_ID>/locations/global/publishers/google/models/gemini-2.5-flash:generateContent" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{"role": "user", "parts": [{"text": "Xin chào"}]}]
  }'
```

---

## ⚠️ Troubleshooting / Lưu ý

### 🔴 Lỗi 404 "Model was not found" khi dùng Gemini 3.x Preview

```json
{
  "error": {
    "code": 404,
    "message": "Publisher Model `projects/.../locations/us-central1/publishers/google/models/gemini-3-pro-preview` was not found",
    "status": "NOT_FOUND"
  }
}
```

**Nguyên nhân:** Các model **Gemini 3.x preview** (gemini-3-pro-preview, gemini-3-flash-preview, gemini-3.1-pro-preview...) yêu cầu sử dụng **Global endpoint** thay vì regional endpoint (us-central1).

**Cách fix:** Đổi `location` từ `us-central1` sang `global`:

```python
# ❌ SAI — regional endpoint không hỗ trợ một số model preview
client = genai.Client(vertexai=True, project='PROJECT_ID', location='us-central1', credentials=creds)

# ✅ ĐÚNG — global endpoint hỗ trợ tất cả model preview
client = genai.Client(vertexai=True, project='PROJECT_ID', location='global', credentials=creds)
```

Hoặc với REST API:
```bash
# ❌ SAI
https://us-central1-aiplatform.googleapis.com/v1/projects/.../locations/us-central1/...

# ✅ ĐÚNG
https://aiplatform.googleapis.com/v1/projects/.../locations/global/...
```

> **📌 Tham khảo chính thức:** [Vertex AI Deployments and Endpoints — Global Endpoint](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/locations)
>
> **Yêu cầu phiên bản SDK:** `google-genai >= 0.8.0` hoặc `google-cloud-aiplatform >= 1.79.0`

---

### ⚡ Regional vs Global Endpoint — Khi nào dùng cái nào?

| | Regional (us-central1, ...) | Global |
|---|---|---|
| **Ưu điểm** | Kiểm soát được region xử lý, phù hợp compliance | Hỗ trợ đầy đủ model preview, giảm lỗi 429 |
| **Nhược điểm** | Một số model preview không khả dụng | Không kiểm soát được region xử lý |
| **Dùng khi** | Production cần data residency | Development, testing, hoặc cần model mới nhất |
| **Model 3.x** | ⚠️ Có thể lỗi 404 | ✅ Hoạt động |

**Khuyến nghị:** Luôn dùng `global` trừ khi có yêu cầu đặc biệt về data residency.

---

### Các model Gemini phổ biến trên Vertex AI (03/2026)

| Model | Tốc độ | Chi phí | Ghi chú |
|---|---|---|---|
| `gemini-2.5-flash` | ⚡ Nhanh | 💰 Rẻ | Ổn định, recommended cho đa số use case |
| `gemini-2.5-pro` | 🐌 Chậm hơn | 💰💰 Đắt | Chất lượng cao, dễ bị rate limit |
| `gemini-2.5-flash-lite` | ⚡⚡ Rất nhanh | 💰 Rẻ nhất | Tác vụ đơn giản |
| `gemini-3-pro-preview` | 🐌 Chậm | 💰💰 Đắt | Preview — **BẮT BUỘC dùng global endpoint** |
| `gemini-3-flash-preview` | ⚡ Nhanh | 💰 Trung bình | Preview — **BẮT BUỘC dùng global endpoint** |
| `gemini-3.1-pro-preview` | 🐌 Chậm | 💰💰 Đắt | Preview — **BẮT BUỘC dùng global endpoint** |

---

### Các lỗi thường gặp khác

| Lỗi | Nguyên nhân | Cách fix |
|---|---|---|
| `Permission denied` | Service Account thiếu role | Thêm role **Vertex AI User** trong IAM |
| `Vertex AI API has not been enabled` | Chưa enable API | Chạy `gcloud services enable aiplatform.googleapis.com` |
| `Could not automatically determine credentials` | Sai path JSON key | Kiểm tra `GOOGLE_APPLICATION_CREDENTIALS` |
| `429 RESOURCE_EXHAUSTED` | Rate limit | Giảm concurrent requests, thêm retry logic |
| `FAILED_PRECONDITION` | Lần đầu dùng Vertex AI | Chờ 2-3 phút để Google setup service agents |

---

### Script test model nào hoạt động

```python
import os
from dotenv import load_dotenv
from google import genai
from google.genai import types
from google.oauth2 import service_account

load_dotenv()

creds = service_account.Credentials.from_service_account_file(
    os.getenv('GOOGLE_APPLICATION_CREDENTIALS'),
    scopes=['https://www.googleapis.com/auth/cloud-platform']
)

# Dùng global endpoint để test tất cả model
client = genai.Client(
    vertexai=True,
    project=os.getenv('GOOGLE_CLOUD_PROJECT'),
    location='global',
    credentials=creds
)

models_to_test = [
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.5-flash-lite',
    'gemini-3-pro-preview',
    'gemini-3-flash-preview',
    'gemini-3.1-pro-preview',
]

for m in models_to_test:
    try:
        r = client.models.generate_content(
            model=m,
            contents='Xin chào',
            config=types.GenerateContentConfig(max_output_tokens=20)
        )
        print(f'✅ {m}: OK')
    except Exception as e:
        print(f'❌ {m}: {str(e)[:80]}')
```

---

### So sánh AI Studio vs Vertex AI

| | AI Studio | Vertex AI |
|---|---|---|
| **Xác thực** | API Key (`GOOGLE_API_KEY`) | Service Account JSON key |
| **Endpoint** | `generativelanguage.googleapis.com` | `aiplatform.googleapis.com` |
| **Billing** | AI Studio billing | Google Cloud billing ($300 credit ✅) |
| **Quản lý** | Đơn giản | IAM, logging, monitoring đầy đủ |
| **Phù hợp** | Prototype, cá nhân | Production, team, enterprise |

---

> **📚 Tham khảo thêm:**
> - [Model versions and lifecycle](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions)
> - [Deployments and endpoints](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/locations)
> - [Google Gen AI SDK](https://cloud.google.com/vertex-ai/generative-ai/docs/sdks/overview)
