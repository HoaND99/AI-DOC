import os
import tempfile
from flask import Flask, request, jsonify
import requests
from google.auth import default
from google.auth.transport.requests import AuthorizedSession

app = Flask(__name__)

# Đọc từ env
MODEL = os.getenv("GEMINI_MODEL")
ENDPOINT = os.getenv("GEMINI_ENDPOINT", "generateContent")

if not MODEL:
    raise RuntimeError("Bạn phải set GEMINI_MODEL")

BASE_URL = (
    "https://generativelanguage.googleapis.com/v1beta/"
    f"models/{MODEL}:{ENDPOINT}"
)

# Tự authenticate qua SA key JSON
creds, _ = default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
authed_session = AuthorizedSession(creds)

def call_gemini(text: str) -> str:
    if ENDPOINT == "generateContent":
        payload = {
            # payload format mới: dùng field 'text'
            "text": text,
            "temperature": 0.2,
            "maxOutputTokens": 512,
            "candidateCount": 1,
        }
    else:
        payload = {
            "messages": [{"author": "user", "content": text}],
            "temperature": 0.2,
            "maxOutputTokens": 512,
            "candidateCount": 1,
        }

    resp = authed_session.post(BASE_URL, json=payload)
    resp.raise_for_status()
    data = resp.json()
    cands = data.get("candidates", [])
    if not cands:
        return ""
    if ENDPOINT == "generateContent":
        return cands[0].get("output", "")
    else:
        return cands[0].get("message", {}).get("content", "")

@app.route("/summarize", methods=["POST"])
def summarize():
    # Lưu file tạm nếu cần
    f = request.files.get("file")
    if not f:
        return jsonify(error="Không tìm thấy file"), 400

    with tempfile.NamedTemporaryFile(suffix=".txt", delete=False) as tmp:
        f.save(tmp.name)
        tmp.seek(0)
        content = tmp.read().decode("utf-8", errors="ignore")

    try:
        summary = call_gemini(content)
        return jsonify(summary=summary)
    except Exception as e:
        return jsonify(error=str(e), detail=getattr(e, "response", {}).text), 500

if __name__ == "__main__":
    # Chỉ chạy dev server
    app.run(host="0.0.0.0", port=8080, debug=True)
