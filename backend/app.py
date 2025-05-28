import os
import logging
from fastapi import FastAPI, File, UploadFile, HTTPException
from dotenv import load_dotenv
from pdfminer.high_level import extract_text
import docx
import google.genai as genai
from google.genai import types

load_dotenv()

API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    raise RuntimeError("Bạn phải thiết lập biến môi trường GOOGLE_API_KEY")

app = FastAPI(title="Doc Summarizer with Google GenAI")
logger = logging.getLogger("uvicorn.error")

# Khởi tạo client
client = genai.Client(api_key=API_KEY)

def summarize_text(text: str) -> str:
    try:
        # Gọi text.generate cho google-genai v0.8.0
        response = client.text.generate(
            model="text-bison-001",
            prompt=text,
            temperature=0.2,
            max_output_tokens=300,
        )
        return response.result.text
    except Exception as e:
        logger.error("Error calling GenAI: %s", e, exc_info=True)
        raise

def extract_docx(path: str) -> str:
    doc = docx.Document(path)
    return "\n".join(p.text for p in doc.paragraphs if p.text.strip())

@app.post("/summarize/")
async def summarize(file: UploadFile = File(...)):
    ext = file.filename.rsplit(".", 1)[-1].lower()
    if ext not in ("pdf", "docx"):
        raise HTTPException(status_code=400, detail="Chỉ hỗ trợ PDF và DOCX")

    # Lưu file tạm
    tmp_path = f"/tmp/{file.filename}"
    with open(tmp_path, "wb") as f:
        f.write(await file.read())

    # Trích xuất text
    try:
        text = extract_text(tmp_path) if ext == "pdf" else extract_docx(tmp_path)
    except Exception as e:
        logger.error("Error extracting text: %s", e, exc_info=True)
        raise HTTPException(status_code=422, detail="Không thể trích xuất nội dung")

    if not text.strip():
        raise HTTPException(status_code=422, detail="Tài liệu rỗng")

    if len(text) > 50_000:
        text = text[:50_000]

    # Gọi GenAI tóm tắt
    try:
        summary = summarize_text(text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi khi gọi GenAI: {e}")

    return {"summary": summary}
