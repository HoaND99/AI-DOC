import os
import io
import requests
from flask import Flask, request, jsonify
from PyPDF2 import PdfReader
from docx import Document

app = Flask(__name__)

# Đọc key và model từ biến môi trường
API_KEY    = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "models/gemini-1.5-pro-latest")

def extract_text_from_pdf(file_stream):
    reader = PdfReader(file_stream)
    text = []
    for page in reader.pages:
        text.append(page.extract_text() or "")
    return "\n".join(text)

def extract_text_from_docx(file_stream):
    doc = Document(file_stream)
    text = [p.text for p in doc.paragraphs]
    return "\n".join(text)

@app.route("/summarize", methods=["POST"])
def summarize():
    # Lấy file upload
    f = request.files.get("file")
    if not f:
        return jsonify({"error": "No file provided"}), 400

    filename = f.filename.lower()
    # Chọn extractor theo extension
    if filename.endswith(".pdf"):
        content = extract_text_from_pdf(f.stream)
    elif filename.endswith(".docx"):
        # docx reader cần một BytesIO hoặc file path, dùng stream.read()
        content = extract_text_from_docx(io.BytesIO(f.read()))
    else:
        # .txt hoặc bất kỳ extension khác coi như text
        content = f.read().decode("utf-8", errors="ignore")
    
    # Gọi Gemini để tóm tắt
    summary = call_gemini(content)
    return jsonify({"summary": summary})

def call_gemini(text: str) -> str:
    if not API_KEY:
        raise RuntimeError("Missing GEMINI_API_KEY environment variable")

    # Build URL
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/"
        f"{GEMINI_MODEL}:generateContent?key={API_KEY}"
    )
    # Debug: in ra model + URL
    app.logger.info(f"Using model: {GEMINI_MODEL}")
    app.logger.info(f"Calling URL: {url}")

    headers = {"Content-Type": "application/json; charset=UTF-8"}
    payload = {
        "prompt": {
            "text": (
                "Please provide a concise summary of the following text:\n\n"
                f"{text}"
            )
        },
        # Thay tham số nếu cần (temperature, maxOutputTokens,...)
        "temperature": 0.5,
        "maxOutputTokens": 512
    }

    resp = requests.post(url, headers=headers, json=payload)
    resp.raise_for_status()
    data = resp.json()

    # Trả về chuỗi summary
    return data.get("candidates", [{}])[0].get("content", "")

if __name__ == "__main__":
    # Port từ env hoặc mặc định 8080
    port = int(os.getenv("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
