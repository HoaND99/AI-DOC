import os, tempfile
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pdfminer.high_level import extract_text as extract_text_pdf
from docx import Document

from google.api_core.client_options import ClientOptions
from google.ai.generativelanguage_v1.services.generative_language_service import GenerativeLanguageServiceClient
from google.ai.generativelanguage_v1.types import GenerateTextRequest

# API key
API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    raise RuntimeError("Missing GOOGLE_API_KEY")

# Init client
client_opts = ClientOptions(api_key=API_KEY)
client = GenerativeLanguageServiceClient(client_options=client_opts)
MODEL = os.getenv("GEMINI_MODEL", "models/text-bison-001")

app = FastAPI(title="Doc Summarizer")
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
)

@app.get("/")
async def health():
    return {"status": "ok"}



@app.post("/summarize")
async def summarize(file: UploadFile = File(...)):

    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in (".pdf", ".docx"):
        raise HTTPException(400, "Unsupported file type")

    # save
    with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as tmp:
        data = await file.read()
        tmp.write(data)
        path = tmp.name

    # extract
    try:
        text = extract_text_pdf(path) if ext == ".pdf" else "\n".join(p.text for p in Document(path).paragraphs)
    except Exception as e:
        raise HTTPException(500, f"Extract failed: {e}")

    if not text.strip():
        raise HTTPException(400, "No text found")

    # generate Vietnamese summary
    try:
        req = GenerateTextRequest(
            model=MODEL,
            prompt=f"Tóm tắt ngắn gọn nội dung sau bằng tiếng Việt:\n\n{text}",
            temperature=0.3,
            max_output_tokens=500,
        )
        res = client.generate_text(request=req)
        summary = res.text.strip()
    except Exception as e:
        raise HTTPException(502, f"GenAI error: {e}")

    return {"summary": summary}
