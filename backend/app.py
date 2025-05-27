import os
import tempfile
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pdfminer.high_level import extract_text as extract_text_pdf
from docx import Document
from google.ai import generativelanguage as gl
from google.api_core.client_options import ClientOptions

# Đọc API key từ biến môi trường
API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    raise RuntimeError("Missing GOOGLE_API_KEY environment variable")

# Khởi tạo client Gemini
client_options = ClientOptions(api_key=API_KEY)
client = gl.GenerativeLanguageServiceClient(client_options=client_options)

# Model dùng để tóm tắt
MODEL = os.getenv("GEMINI_MODEL", "models/text-bison-001")

app = FastAPI(title="Doc Summarizer")

# Cho phép gọi từ Flutter/Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST", "GET", "OPTIONS"],
    allow_headers=["*"],
)

@app.post("/summarize")
async def summarize(file: UploadFile = File(...)):
    # Chỉ chấp nhận pdf hoặc docx
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in {".pdf", ".docx"}:
        raise HTTPException(status_code=400, detail="Unsupported file type")
    
    # Lưu tạm file
    suffix = ".pdf" if ext == ".pdf" else ".docx"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        contents = await file.read()
        tmp.write(contents)
        tmp_path = tmp.name

    # Trích xuất văn bản
    try:
        if ext == ".pdf":
            text = extract_text_pdf(tmp_path)
        else:
            doc = Document(tmp_path)
            text = "\n".join(p.text for p in doc.paragraphs)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to extract text: {e}")

    if not text.strip():
        raise HTTPException(status_code=400, detail="No text found in document")

    # Gọi Gemini để tóm tắt
    try:
        request = gl.GenerateTextRequest(
            model=MODEL,
            prompt=f"Tóm tắt ngắn gọn nội dung sau bằng tiếng Việt:\n\n{text}",
            temperature=0.3,
            max_output_tokens=500,
        )
        response = client.generate_text(request=request)
        summary = response.text.strip()
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"GenAI error: {e}")

    return {"summary": summary}
