# 🚀 Cấu hình Vertex AI (Gemini Enterprise Agent Platform) để dùng Gemini API

Hướng dẫn setup **Google Cloud Vertex AI** để gọi API các model Gemini (2.5, 3.x...) - phù hợp cho môi trường không dùng được Google AI Studio API (VPS, CI/CD, production), hoặc muốn tận dụng **$300 Google Cloud Free Trial Credit**.

> **📌 Lưu ý đổi tên (2026):** Google đã đổi tên "Vertex AI" thành **"Gemini Enterprise Agent Platform"** (công bố tại Google Cloud Next 2026, hoàn tất khoảng cuối 5/2026). **Endpoint API KHÔNG đổi - vẫn là `aiplatform.googleapis.com`**, và code cũ vẫn chạy nguyên. Doc `cloud.google.com/vertex-ai/...` giờ 301-redirect sang `.../gemini-enterprise-agent-platform/...`. Trong guide này vẫn gọi là "Vertex AI" cho quen thuộc.

> **💡 Khi nào dùng Vertex AI thay vì AI Studio?**
> - Môi trường bị chặn AI Studio API endpoint (`generativelanguage.googleapis.com`)
> - Muốn dùng **$300 Free Trial Credit** (xem giới hạn ở dưới)
> - Cần IAM, logging, monitoring, billing chuyên nghiệp hơn

> **💰 $300 credit dùng được cho cái gì?** (quan trọng, nhiều người nhầm)
> - ✅ **DÙNG ĐƯỢC** cho Gemini qua **Vertex AI** (model Google, bill qua `aiplatform.googleapis.com`).
> - ❌ **KHÔNG** dùng được cho Gemini API qua **AI Studio** (`generativelanguage.googleapis.com`) - Google loại trừ từ ~3/2026.
> - ❌ **KHÔNG** dùng cho **partner model / model-as-a-service** trên Model Garden (Claude, Llama, Mistral...).

---

## ⚡ Tóm tắt Thao tác Nhanh (Quick Reference)

Có 2 cách xác thực. **Ưu tiên Keyless (ADC)** - an toàn hơn và né được org policy chặn tạo key (xem Troubleshooting).

```bash
# === 0. Enable API (tên service KHÔNG đổi dù đã rebrand) ===
gcloud services enable aiplatform.googleapis.com
gcloud services enable storage.googleapis.com   # nếu cần upload file lớn qua GCS

# === 1. Tạo Service Account + gán quyền ===
gcloud iam service-accounts create my-ai-worker --display-name="AI Worker"

gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member="serviceAccount:my-ai-worker@<PROJECT_ID>.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"
# Nếu dùng GCS: thêm role storage.objectAdmin tương tự

# === 2A. XÁC THỰC KEYLESS (khuyến nghị) - không cần file key ===
gcloud auth application-default login                       # login = danh tính của bạn (máy dev)
gcloud auth application-default set-quota-project <PROJECT_ID>
# Trên GCE / Cloud Run: gán SA vào máy/service -> ADC tự chạy, không cần lệnh nào

# === 2B. Hoặc dùng JSON key (khi buộc, vd VPS không login được) ===
gcloud iam service-accounts keys create service-account-key.json \
    --iam-account=my-ai-worker@<PROJECT_ID>.iam.gserviceaccount.com
# LƯU Ý: có thể bị chặn bởi org policy iam.disableServiceAccountKeyCreation -> xem Troubleshooting

# === 3. Biến môi trường ===
export GOOGLE_CLOUD_PROJECT=<PROJECT_ID>
export GOOGLE_CLOUD_LOCATION=global    # "global" bắt buộc cho model Gemini 3.x preview
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json   # CHỈ cần nếu dùng cách 2B

# === 4. Cài SDK (dùng google-genai, KHÔNG dùng vertexai SDK cũ - đã bị xóa 24/6/2026) ===
pip install "google-genai>=1.51.0" google-auth

# === 5. Test nhanh (keyless - không truyền credentials= -> SDK tự dùng ADC) ===
python3 -c "
from google import genai
client = genai.Client(vertexai=True, project='<PROJECT_ID>', location='global')
r = client.models.generate_content(model='gemini-2.5-flash', contents='Xin chào')
print(r.text)
"
```

---

## 📝 Các bước thực hiện (Step by Step)

### Bước 1: Enable Vertex AI API

**Cách chắc ăn nhất (khỏi mò tên trong UI):**
```bash
gcloud services enable aiplatform.googleapis.com
```

Hoặc mở thẳng trang Library của đúng service (thay `<PROJECT_ID>`):
```
https://console.cloud.google.com/apis/library/aiplatform.googleapis.com?project=<PROJECT_ID>
```

> **📝 Lưu ý sau rebrand:** Nếu vào **APIs & Services -> Library** rồi gõ search **"Vertex AI API"** mà **không thấy** (chỉ ra "Vertex AI Search for commerce API"...), đừng hoang mang. Nguyên nhân thường là: (a) API đã được enable sẵn nên không hiện trong khu Browse, hoặc (b) UI mới sau khi đổi tên. Cứ search **`aiplatform`** (service ID luôn khớp) hoặc dùng URL/lệnh gcloud ở trên.

Nếu cần upload file lớn qua Cloud Storage:
```bash
gcloud services enable storage.googleapis.com
```

---

### Bước 2: Tạo Service Account + gán quyền

```bash
gcloud iam service-accounts create my-ai-worker --display-name="AI Worker"
```

Gán role tối thiểu:

| Role | Mục đích |
|---|---|
| `roles/aiplatform.user` (Vertex AI User) | Gọi API Gemini qua Vertex AI |
| `roles/storage.objectAdmin` (Storage Object Admin) | Upload/xóa file trên GCS (chỉ khi cần) |

```bash
gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member="serviceAccount:my-ai-worker@<PROJECT_ID>.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"
```

> **📝 Ghi chú:** Test nhanh có thể gán `Owner`, nhưng production luôn theo least-privilege (chỉ 2 role trên).
>
> **Với cách Keyless dùng danh tính cá nhân của bạn (Bước 3, cách A):** không bắt buộc phải tạo SA - dùng chính account của bạn (nếu bạn đã là Owner/Editor project). SA chỉ cần cho attached-SA / impersonation / key file.

---

### Bước 3: Chọn cách xác thực

| Cách | Khi nào dùng | Cần file key? | Ghi chú |
|---|---|---|---|
| **A. User ADC** | Dev trên máy cá nhân | Không | `gcloud auth application-default login` |
| **B. Attached SA** | Chạy trên GCE / Cloud Run / GKE | Không | Gắn SA vào máy -> ADC tự chạy. **Tốt nhất cho production** |
| **C. Impersonation** | VPS/CI cần danh tính SA, không muốn key | Không | Login rồi impersonate SA |
| **D. JSON key** | Môi trường không login được ADC | **Có** | Có thể bị **org policy chặn** (xem Troubleshooting) |

**Google khuyến nghị Keyless (A/B/C) hơn key file (D)** - key JSON dài hạn là nguồn rò rỉ bảo mật phổ biến nhất.

#### Cách A - User ADC (dev nhanh)
```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project <PROJECT_ID>
```
ADC lưu tại `~/.config/gcloud/application_default_credentials.json`. SDK tự nhận, **không cần truyền `credentials=`**.

> Nếu `.env` có `GOOGLE_API_KEY` / `GEMINI_API_KEY`, hãy xóa/bỏ trống - nếu không SDK có thể ưu tiên key đó thay vì ADC.

#### Cách B - Attached Service Account (production)
Gắn SA `my-ai-worker@...` vào GCE VM / Cloud Run service khi tạo (hoặc sửa trong setting). Không cần lệnh nào, không cần file - ADC tự lấy từ metadata server.

#### Cách C - Impersonation (VPS/CI, không key)
```bash
gcloud auth application-default login \
    --impersonate-service-account=my-ai-worker@<PROJECT_ID>.iam.gserviceaccount.com
```
Account của bạn cần role `roles/iam.serviceAccountTokenCreator` trên SA đó.

#### Cách D - JSON key (khi bắt buộc)
```bash
gcloud iam service-accounts keys create service-account-key.json \
    --iam-account=my-ai-worker@<PROJECT_ID>.iam.gserviceaccount.com
```
> **🔴 Nếu báo lỗi "Service account key creation is disabled" (`iam.disableServiceAccountKeyCreation`)** -> org policy đang chặn. Xem mục Troubleshooting phía dưới. Ưu tiên chuyển sang Keyless (A/B/C).

Đẩy key lên server (nếu cần) + set quyền + gitignore:
```bash
scp service-account-key.json user@<SERVER_IP>:/path/to/project/service-account-key.json
ssh user@<SERVER_IP> "chmod 600 /path/to/project/service-account-key.json"
```
> **🔒 BẢO MẬT:** Tuyệt đối **KHÔNG** commit file key lên Git:
> ```bash
> echo "service-account-key.json" >> .gitignore
> # Kiểm tra đã ignore chưa:
> git check-ignore service-account-key.json
> ```

---

### Bước 4: Cấu hình biến môi trường

```env
# === VERTEX AI CONFIG ===
GOOGLE_CLOUD_PROJECT=<PROJECT_ID>
GOOGLE_CLOUD_LOCATION=global
# Chỉ cần dòng dưới nếu dùng JSON key (cách D); Keyless thì BỎ dòng này:
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json

# Model
GEMINI_MODEL=gemini-2.5-flash
```

| Biến | Mô tả | Ví dụ |
|---|---|---|
| `GOOGLE_CLOUD_PROJECT` | Project ID (phải khớp project của SA/key) | `<PROJECT_ID>` |
| `GOOGLE_CLOUD_LOCATION` | Endpoint location | `global` hoặc `us-central1` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path file key - **chỉ khi dùng cách D** | `/app/service-account-key.json` |
| `GEMINI_MODEL` | Tên model | `gemini-2.5-flash` |

> **⚠️ Bẫy hay gặp:** `GOOGLE_CLOUD_PROJECT` phải trùng project mà SA/credential thuộc về. Nếu lệch project, SA sẽ không có quyền -> lỗi 403.

---

### Bước 5: Cài đặt SDK

```bash
pip install "google-genai>=1.51.0" google-auth
# google-cloud-storage nếu upload file lên GCS
```

| Package (Python) | Mục đích |
|---|---|
| `google-genai` | SDK chính gọi Gemini qua Vertex AI (bản thay thế) |
| `google-auth` | Xác thực Service Account / ADC |
| `google-cloud-storage` | Upload file lên GCS (nếu cần) |

> **⚠️ SDK cũ đã bị xóa:** Các module generative-AI của `vertexai` / `google-cloud-aiplatform` (`vertexai.generative_models`, `.language_models`...) **deprecated 24/6/2025, gỡ bỏ 24/6/2026**. Dùng `google-genai`. Với Gemini 3.x cần `google-genai >= 1.51.0`.
>
> Node.js: `npm install @google/genai` (gói `@google-cloud/vertexai` cũ cũng đang bị thay thế bởi `@google/genai`).

---

### Bước 6: Code mẫu

#### Python - Keyless (khuyến nghị, không file key)

```python
import os
from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

# Không truyền credentials= -> SDK tự dùng Application Default Credentials (ADC)
# (từ 'gcloud auth application-default login', attached SA, hoặc impersonation)
client = genai.Client(
    vertexai=True,
    project=os.getenv('GOOGLE_CLOUD_PROJECT'),
    location=os.getenv('GOOGLE_CLOUD_LOCATION', 'global'),
)

response = client.models.generate_content(
    model=os.getenv('GEMINI_MODEL', 'gemini-2.5-flash'),
    contents='Xin chào, hãy giới thiệu bạn là ai?',
    config=types.GenerateContentConfig(max_output_tokens=1024, temperature=0.7),
)
print(response.text)
```

#### Python - Dùng JSON key (cách D)

```python
import os
from dotenv import load_dotenv
from google import genai
from google.oauth2 import service_account

load_dotenv()

creds = service_account.Credentials.from_service_account_file(
    os.getenv('GOOGLE_APPLICATION_CREDENTIALS'),
    scopes=['https://www.googleapis.com/auth/cloud-platform'],
)

client = genai.Client(
    vertexai=True,
    project=os.getenv('GOOGLE_CLOUD_PROJECT'),
    location=os.getenv('GOOGLE_CLOUD_LOCATION', 'global'),
    credentials=creds,
)
# ... gọi generate_content như trên
```

#### REST API (cURL) - Global endpoint

```bash
ACCESS_TOKEN=$(gcloud auth print-access-token)

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

### 🔴 "Service account key creation is disabled" (org policy chặn tạo key)

```
An Organization Policy that blocks service accounts key creation has been enforced
on your organization.  (iam.disableServiceAccountKeyCreation)
```

**Nguyên nhân:** Google bật sẵn constraint `iam.disableServiceAccountKeyCreation` theo "Secure by Default" cho **mọi organization tạo từ 3/5/2024 trở đi** (kể cả org tự sinh cho tài khoản cá nhân). Nó chặn tạo JSON key.

**Cách xử lý (theo thứ tự khuyến nghị):**

1. **Chuyển sang Keyless** (Bước 3, cách A/B/C) - né hoàn toàn, không cần đụng policy, an toàn hơn.
2. **Tắt policy** (chỉ khi buộc phải dùng key). Cần role **`roles/orgpolicy.policyAdmin`** (Organization Policy Administrator) ở **cấp organization**.
   - **Bẫy:** role **Organization Administrator KHÔNG** kèm quyền sửa org policy. Nhưng nếu bạn là Org Admin, bạn **tự cấp** `orgpolicy.policyAdmin` cho mình được (vì có `setIamPolicy` ở org).
   - Các bước: chọn resource = Organization -> **IAM** -> Grant access -> thêm role `Organization Policy Administrator` cho email bạn -> chờ 1-2 phút -> **IAM & Admin -> Organization Policies** -> mở `iam.disableServiceAccountKeyCreation` -> **Edit** -> **Override parent's policy** -> rule **Not enforced** -> **Set policy**.
   - Để least-privilege, nên override ở **cấp project** thay vì cả org.
   - **Cảnh báo:** đây là gỡ 1 lớp guardrail bảo mật Google cố tình bật -> cân nhắc, và cân nhắc bật lại sau khi lấy key.

### ⚡ 429 RESOURCE_EXHAUSTED / Dynamic Shared Quota (DSQ)

Các model Gemini đời mới (2.x, 3.x) trên Vertex chạy theo **Dynamic Shared Quota**:

- **Không có hạn mức RPM/TPM cố định**, và **không xin tăng quota được** (không còn khái niệm quota để nâng). Trích Google: *"There are no quotas with DSQ, and you no longer need to submit quota increase requests."*
- **429 KHÔNG phải bạn vượt hạn mức riêng** - mà là **pool dùng chung đang nghẽn** tại thời điểm đó. 429 dễ xảy ra hơn với input multimodal lớn (audio/video/ảnh).

**Cách giảm 429:**
- **Exponential backoff + retry** (Google khuyến nghị số 1) - chờ 1s, 2s, 4s... + jitter.
- **Giảm số request song song** (concurrent workers).
- **Dùng global endpoint** (`location=global`) - route tới region còn nhiều capacity nhất.
- **Batch Prediction API** cho job bulk offline (pool riêng, không hạn mức cố định) - hợp transcribe/xử lý hàng loạt.
- **Provisioned Throughput** (trả tiền đặt trước GSU) nếu cần capacity đảm bảo cho production - đắt, không hợp job chạy 1 lần.

> Ghi chú: tài khoản free-trial/mới có thể bị throttle sớm hơn theo trải nghiệm thực tế (project mới thường ưu tiên thấp trong pool), nhưng **Google không công bố con số chính thức** - đừng coi là cam kết.

### 🔴 Lỗi 404 "Publisher Model ... was not found" khi dùng Gemini 3.x

```json
{ "error": { "code": 404,
  "message": "Publisher Model `.../locations/us-central1/publishers/google/models/gemini-3.1-pro-preview` was not found",
  "status": "NOT_FOUND" } }
```

**Nguyên nhân:** Các model **Gemini 3.x preview** (`gemini-3.1-pro-preview`, `gemini-3-flash-preview`...) **chỉ chạy trên `global` endpoint**, không có ở regional (us-central1...).

**Cách fix:** đổi `location` sang `global`:
```python
# ❌ SAI - regional không có model 3.x preview
client = genai.Client(vertexai=True, project='<PROJECT_ID>', location='us-central1')
# ✅ ĐÚNG
client = genai.Client(vertexai=True, project='<PROJECT_ID>', location='global')
```
REST: host là `https://aiplatform.googleapis.com/v1/projects/<PROJECT_ID>/locations/global/...` (KHÔNG phải `global-aiplatform...` hay `<region>-aiplatform...`).

> Yêu cầu SDK: `google-genai >= 1.51.0` cho Gemini 3.x.

### ⚡ Regional vs Global Endpoint

| | Regional (us-central1...) | Global |
|---|---|---|
| **Ưu điểm** | Data residency; hỗ trợ tuning, batch prediction, context caching | Nhiều capacity hơn (giảm 429); có đủ model 3.x preview |
| **Nhược điểm** | Một số model preview không có | Không kiểm soát region xử lý; **KHÔNG** hỗ trợ tuning / batch / context caching |
| **Model 3.x preview** | ⚠️ 404 | ✅ Hoạt động |

**Khuyến nghị:** dùng `global` trừ khi cần data residency hoặc cần batch/tuning/context-caching.

### Các model Gemini trên Vertex AI (cập nhật ~7/2026)

| Model | Trạng thái | Ghi chú |
|---|---|---|
| `gemini-2.5-flash` | **GA** | Ổn định, khuyến nghị cho đa số use case |
| `gemini-2.5-pro` | **GA** | Chất lượng cao, đắt hơn, dễ đụng 429 |
| `gemini-2.5-flash-lite` | **GA** | Rẻ nhất, tác vụ đơn giản |
| `gemini-3-flash-preview` | Preview | **Global endpoint bắt buộc** |
| `gemini-3.1-pro-preview` | Preview | **Global endpoint bắt buộc** |
| `gemini-3.1-flash-lite` | Preview | **Global endpoint bắt buộc** |
| ~~`gemini-3-pro-preview`~~ | **Đã khai tử (~3/2026)** | Thay bằng `gemini-3.1-pro-preview` - đừng dùng ID cũ |

> **⚠️ Model đổi rất nhanh.** Gemini 3 **chưa GA** (3.1 Pro vẫn Preview tính đến 7/2026), và họ **Gemini 3.5** đang xuất hiện. Trước khi hardcode ID model, kiểm tra danh sách sống: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models

### Các lỗi thường gặp khác

| Lỗi | Nguyên nhân | Cách fix |
|---|---|---|
| `Service account key creation is disabled` | Org policy chặn tạo key | Dùng Keyless, hoặc tắt `iam.disableServiceAccountKeyCreation` (xem trên) |
| `403 PERMISSION_DENIED` | SA thiếu role, hoặc lệch project | Gán `Vertex AI User`; check `GOOGLE_CLOUD_PROJECT` khớp project của SA |
| `Vertex AI API has not been enabled` | Chưa enable API | `gcloud services enable aiplatform.googleapis.com` |
| `Could not automatically determine credentials` | Chưa có ADC và không có key | Chạy `gcloud auth application-default login`, hoặc set `GOOGLE_APPLICATION_CREDENTIALS` |
| `404 ... Publisher Model was not found` | Model 3.x gọi trên regional | Đổi `location=global` |
| `429 RESOURCE_EXHAUSTED` | Pool DSQ nghẽn | Backoff + retry, giảm concurrent, global endpoint (xem trên) |
| `FAILED_PRECONDITION` | Lần đầu dùng Vertex | Chờ 2-3 phút để Google setup service agents |

### Script test model nào hoạt động

```python
import os
from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

# Keyless: không truyền credentials=. Dùng global để test cả model 3.x preview.
client = genai.Client(
    vertexai=True,
    project=os.getenv('GOOGLE_CLOUD_PROJECT'),
    location='global',
)

models_to_test = [
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.5-flash-lite',
    'gemini-3-flash-preview',
    'gemini-3.1-pro-preview',
]

for m in models_to_test:
    try:
        client.models.generate_content(
            model=m, contents='Xin chào',
            config=types.GenerateContentConfig(max_output_tokens=20),
        )
        print(f'✅ {m}: OK')
    except Exception as e:
        print(f'❌ {m}: {str(e)[:80]}')
```

### So sánh AI Studio vs Vertex AI

| | AI Studio | Vertex AI |
|---|---|---|
| **Xác thực** | API Key (`GOOGLE_API_KEY`) | ADC / Service Account (keyless hoặc key) |
| **Endpoint** | `generativelanguage.googleapis.com` | `aiplatform.googleapis.com` |
| **Billing** | Bill thẳng / free tier | Google Cloud billing (**$300 credit áp dụng ✅**) |
| **Quản lý** | Đơn giản | IAM, logging, monitoring đầy đủ |
| **Phù hợp** | Prototype, cá nhân | Production, team, VPS/CI |

---

> **📚 Tham khảo chính thức:**
> - [Gemini Enterprise Agent Platform (formerly Vertex AI)](https://cloud.google.com/products/gemini-enterprise-agent-platform)
> - [Danh sách model + lifecycle](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models)
> - [Locations / Global endpoint](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/locations)
> - [Dynamic Shared Quota](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/resources/dynamic-shared-quota)
> - [Xử lý lỗi 429](https://cloud.google.com/blog/products/ai-machine-learning/learn-how-to-handle-429-resource-exhaustion-errors-in-your-llms)
> - [Keyless auth / disable SA keys](https://docs.cloud.google.com/iam/docs/keys-disable-enable)
> - [Google Gen AI SDK](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/sdks/overview)
