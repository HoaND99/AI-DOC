import os, tempfile
from fastapi import FastAPI, UploadFile, File, HTTPException
from google.auth import default
from google.auth.transport.requests import AuthorizedSession
from pdfminer.high_level import extract_text as extract_text_pdf
from docx import Document

app = FastAPI()
MODEL = os.getenv("GEMINI_MODEL")
if not MODEL:
    raise RuntimeError("Bạn phải set GEMINI_MODEL")
BASE_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"
creds, _ = default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
authed_session = AuthorizedSession(creds)

def call_gemini(text: str) -> str:
    payload = {"text": text, "temperature":0.2, "maxOutputTokens":512, "candidateCount":1}
    resp = authed_session.post(BASE_URL, json=payload); resp.raise_for_status()
    return resp.json()["candidates"][0]["output"]

@app.post("/summarize")
async def summarize(file: UploadFile = File(...)):
    ext = file.filename.rsplit(".",1)[-1].lower()
    with tempfile.NamedTemporaryFile(suffix="."+ext, delete=False) as tmp:
        data = await file.read(); tmp.write(data); path=tmp.name
    if ext=="pdf":
        text = extract_text_pdf(path)
    elif ext in ("docx","doc"):
        doc=Document(path); text="\n".join(p.text for p in doc.paragraphs)
    else:
        try: text = data.decode("utf-8",errors="ignore")
        except: raise HTTPException(400,"Unsupported format")
    return {"summary": call_gemini(text)}

if __name__=="__main__":
    import uvicorn; uvicorn.run("app:app",host="0.0.0.0",port=8080,reload=True)
