import os
from fastapi import FastAPI, File, UploadFile, HTTPException
from dotenv import load_dotenv
from pdfminer.high_level import extract_text
import docx
from google import genai
from google.genai import types

load_dotenv()  # đọc biến môi trường từ .env

# Khởi tạo FastAPI
app = FastAPI(title="Doc Summarizer with Google GenAI")

# Khởi tạo client GenAI
# Cấu hình API key cho Gemini Developer API
api_key = os.getenv("GOOGLE_API_KEY")
if not api_key:
    raise RuntimeError("Bạn phải thiết lập biến môi trường GOOGLE_API_KEY")

client = genai.Client(api_key=api_key)

def summarize_text(text: str) -> str:
    """Gọi GenAI để tóm tắt văn bản."""
    response = client.models.generate_content(
        model="gemini-2.5-turbo",
        contents=text,
        config=types.GenerateContentConfig(
            max_output_tokens=300,
            temperature=0.2,
        ),
    )
    return response.text

def extract_docx(file_path: str) -> str:
    """Trích xuất text từ DOCX."""
    doc = docx.Document(file_path)
    full_text = [para.text for para in doc.paragraphs]
    return "\n".join(full_text)

@app.post("/summarize/")
async def summarize(file: UploadFile = File(...)):
    # chỉ cho phép PDF và DOCX
    ext = file.filename.split(".")[-1].lower()
    if ext not in ("pdf", "docx"):
        raise HTTPException(status_code=400, detail="Chỉ hỗ trợ PDF và DOCX")
    
    # lưu tạm
    tmp_path = f"/tmp/{file.filename}"
    with open(tmp_path, "wb") as f:
        f.write(await file.read())
    
    # trích xuất text
    if ext == "pdf":
        text = extract_text(tmp_path)
    else:
        text = extract_docx(tmp_path)
    
    if not text.strip():
        raise HTTPException(status_code=422, detail="Không thể trích xuất nội dung từ tài liệu")

    # nếu quá dài, có thể cắt bớt
    if len(text) > 50_000:
        text = text[:50_000]

    # gọi GenAI tóm tắt
    summary = summarize_text(text)
    return {"summary": summary}
