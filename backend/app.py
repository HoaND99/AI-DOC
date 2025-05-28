import os
import tempfile
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from google.ai.generativelanguage_v1 import GenerativeLanguageServiceClient
from google.api_core.client_options import ClientOptions
from pdfminer.high_level import extract_text as extract_text_pdf
from docx import Document

# Đọc API key từ biến môi trường
API_KEY = os.environ.get("GOOGLE_API_KEY")
if not API_KEY:
    raise RuntimeError("Missing GOOGLE_API_KEY")

# Khởi tạo client, truyền API key qua client_options
client = GenerativeLanguageServiceClient(
    client_options=ClientOptions(api_key=API_KEY)
)

# Model có thể override qua biến GEMINI_MODEL
MODEL = os.environ.get("GEMINI_MODEL", "gemini-1.5-pro-latest")

app = FastAPI(title="Doc Summarizer")



@app.get("/")
async def root():
    return {"status": "ok"}

def summarize_text(text: str) -> str:
    # Gọi API generateText
    response = client.generate_text(
        request={
            "model": MODEL,
            "prompt": {
                "text": f"Tóm tắt đoạn sau bằng tiếng Việt ngắn gọn:\n\n{text}"
            }
        }
    )
    return response.choices[0].text

@app.post("/summarize/")
async def summarize_file(file: UploadFile = File(...)):
    # Chỉ chấp nhận PDF và DOCX
    suffix = file.filename.lower().rsplit(".", 1)[-1]
    if suffix not in ("pdf", "docx"):
        raise HTTPException(400, "Chỉ chấp nhận PDF hoặc DOCX")

    # Lưu tạm file và extract text
    with tempfile.NamedTemporaryFile(suffix="."+suffix, delete=False) as tmp:
        data = await file.read()
        tmp.write(data)
        tmp_path = tmp.name

    if suffix == "pdf":
        raw = extract_text_pdf(tmp_path)
    else:
        doc = Document(tmp_path)
        raw = "\n".join(p.text for p in doc.paragraphs)

    if not raw.strip():
        raise HTTPException(422, "Không trích được nội dung")

    summary = summarize_text(raw)
    return JSONResponse({"summary": summary})
