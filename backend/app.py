import os
import logging
from fastapi import FastAPI, File, UploadFile, HTTPException
from dotenv import load_dotenv
from pdfminer.high_level import extract_text
import docx
import google_genai as genai
from google_genai import types

load_dotenv()
API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    raise RuntimeError("Thiếu biến môi trường GOOGLE_API_KEY")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()
client = genai.Client(api_key=API_KEY)

def extract_text_from_docx(file_bytes: bytes) -> str:
    doc = docx.Document(io.BytesIO(file_bytes))
    return "\n".join(p.text for p in doc.paragraphs)

def summarize_text(text: str) -> str:
    response = client.generate_content(
        model="gemini-2.5-turbo",
        prompt=text,
        max_output_tokens=300,
        temperature=0.2
    )
    return response.text

@app.post("/summarize")
async def summarize(file: UploadFile = File(...)):
    content = await file.read()
    if file.filename.lower().endswith(".pdf"):
        text = extract_text(content)
    elif file.filename.lower().endswith(".docx"):
        text = extract_text_from_docx(content)
    else:
        raise HTTPException(status_code=415, detail="Chỉ hỗ trợ PDF hoặc DOCX")

    if not text.strip():
        raise HTTPException(status_code=422, detail="Tài liệu rỗng")

    text = text[:50000]
    try:
        summary = summarize_text(text)
    except Exception as e:
        logger.error("Error summarizing text: %s", e, exc_info=True)
        raise HTTPException(status_code=500, detail="Lỗi khi gọi GenAI: " + str(e))

    return {"summary": summary}
