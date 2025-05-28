import os
import io
import logging
from fastapi import FastAPI, File, UploadFile, HTTPException
from dotenv import load_dotenv
from pdfminer.high_level import extract_text
import docx
import google_genai  # dùng google-genai v0.8.0

# Load biến môi trường từ .env
load_dotenv()
API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    raise RuntimeError("Bạn phải thiết lập biến môi trường GOOGLE_API_KEY")

# Khởi tạo FastAPI và logger
app = FastAPI(title="Doc Summarizer with Google GenAI")
logger = logging.getLogger("uvicorn.error")

# Khởi tạo client GenAI
client = google_genai.Client(api_key=API_KEY)

def summarize_text(text: str) -> str:
    """Gọi GenAI để tóm tắt văn bản."""
    # với google-genai v0.8.0, phương thức nằm ở client.text.generate
    response = client.text.generate(
        model="text-bison-001",        # hoặc "chat-bison-001" với client.chat.generate
        prompt=text,
        temperature=0.2,
        max_output_tokens=300,
    )
    # kết quả nằm trong response.result.text
    return response.result.text

def extract_docx(path: str) -> str:
    """Trích xuất text từ DOCX."""
    doc = docx.Document(path)
    return "\n".join(p.text for p in doc.paragraphs if p.text.strip())

@app.post("/summarize/")
async def summarize(file: UploadFile = File(...)):
    # Kiểm tra định dạng
    ext = file.filename.rsplit(".", 1)[-1].lower()
    if ext not in ("pdf", "docx"):
        raise HTTPException(status_code=400, detail="Chỉ hỗ trợ PDF và DOCX")

    # Lưu tạm file
    tmp_path = f"/tmp/{file.filename}"
    with open(tmp_path, "wb") as f:
        f.write(await file.read())

    # Trích xuất text
    try:
        if ext == "pdf":
            text = extract_text(tmp_path)
        else:
            text = extract_docx(tmp_path)
    except Exception as e:
        logger.error("Error extracting text: %s", e, exc_info=True)
        raise HTTPException(status_code=422, detail="Không thể trích xuất nội dung từ tài liệu")

    if not text.strip():
        raise HTTPException(status_code=422, detail="Tài liệu rỗng")

    # Giới hạn độ dài input
    if len(text) > 50_000:
        text = text[:50_000]

    # Gọi GenAI để tóm tắt
    try:
        summary = summarize_text(text)
    except Exception as e:
        logger.error("Error summarizing text: %s", e, exc_info=True)
        raise HTTPException(status_code=500, detail="Lỗi khi gọi GenAI: " + str(e))

    return {"summary": summary}
