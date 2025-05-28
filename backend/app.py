import os
from fastapi import FastAPI, File, UploadFile, HTTPException
from dotenv import load_dotenv
from pdfminer.high_level import extract_text
import docx
import google.genai as genai
from google.genai import types

load_dotenv()  # Đọc GOOGLE_API_KEY từ .env

API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    raise RuntimeError("Bạn phải thiết lập biến môi trường GOOGLE_API_KEY")

# Khởi tạo FastAPI
app = FastAPI(title="Doc Summarizer with Google GenAI")

# Khởi tạo client GenAI
client = genai.Client(api_key=API_KEY)

def summarize_text(text: str) -> str:
    """Gọi GenAI để tóm tắt văn bản."""
    response = client.generate_text(
        model="gemini-2.5-turbo",
        prompt=text,
        temperature=0.2,
        max_output_tokens=300
    )
    return response.text

def extract_docx(file_path: str) -> str:
    """Trích xuất text từ DOCX."""
    doc = docx.Document(file_path)
    return "\n".join(para.text for para in doc.paragraphs)

@app.post("/summarize/")
async def summarize(file: UploadFile = File(...)):

    ext = file.filename.split(".")[-1].lower()
    if ext not in ("pdf", "docx"):
        raise HTTPException(status_code=400, detail="Chỉ hỗ trợ PDF và DOCX")
    

    tmp_path = f"/tmp/{file.filename}"
    with open(tmp_path, "wb") as f:
        f.write(await file.read())
    

    if ext == "pdf":
        text = extract_text(tmp_path)
    else:
        text = extract_docx(tmp_path)
    
    if not text.strip():
        raise HTTPException(status_code=422, detail="Không thể trích xuất nội dung từ tài liệu")


    if len(text) > 50_000:
        text = text[:50_000]


    summary = summarize_text(text)
    return {"summary": summary}
