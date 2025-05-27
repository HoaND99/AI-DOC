import os
import tempfile
from fastapi import FastAPI, UploadFile, File, HTTPException
import google.genai as genai
from pdfminer.high_level import extract_text as extract_text_pdf
from docx import Document

app = FastAPI()
# Khởi tạo GenAI client, đọc API key từ biến môi trường
client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))
# Model Gemini để tóm tắt, có thể ghi đè qua biến môi trường
MODEL = os.getenv("GEMINI_MODEL", "gemini-1.5-pro-latest")

@app.post("/summarize")
async def summarize(file: UploadFile = File(...)):
    if not file:
        raise HTTPException(status_code=400, detail="Không có file được gửi")

    ext = file.filename.rsplit('.', 1)[-1].lower()
    with tempfile.NamedTemporaryFile(suffix=f".{ext}", delete=False) as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name

    # Trích xuất văn bản
    if ext == "pdf":
        text = extract_text_pdf(tmp_path)
    elif ext in ("doc", "docx"):
        doc = Document(tmp_path)
        text = "\n".join(p.text for p in doc.paragraphs)
    else:
        raise HTTPException(status_code=400, detail="Định dạng file không được hỗ trợ")

    # Chuẩn bị prompt chỉ tóm tắt thuần tuý
    directive = (
        "Hãy tóm tắt nội dung sau thành một đoạn văn bản duy nhất, "
        "không kèm thêm bình luận, gợi ý hay phân tích nào khác:\n\n"
    )
    prompt = directive + text

    # Gọi Gemini API để tóm tắt
    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=prompt,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    return {"summary": response.text}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8080)),
        reload=True
    )
