import os
from fastapi import FastAPI, HTTPException, File, UploadFile
from google_genai import Client as GenAIClient
from google_genai import types as genai_types
from pdfminer.high_level import extract_text as extract_pdf_text
import docx
app = FastAPI()

# Lấy API key từ biến môi trường
API_KEY = os.environ.get("GOOGLE_API_KEY")
if not API_KEY:
    raise RuntimeError("Bạn phải thiết lập biến môi trường GOOGLE_API_KEY")

# Khởi tạo client
genai = GenAIClient(api_key=API_KEY)

def summarize_text(text: str) -> str:
    """Gọi Gemini API để tóm tắt văn bản."""
    try:
        response = genai.generate_content(
            model="gemini-2.5-turbo",
            contents=text,
            config=genai_types.GenerateContentConfig(
                max_output_tokens=300,
                temperature=0.2,
            ),
        )
        return response.text
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"GenAI error: {e}")


def extract_docx_text(file_path: str) -> str:
    doc = docx.Document(file_path)
    return "\n".join([p.text for p in doc.paragraphs])


@app.post("/summarize/")
async def upload_and_summarize(file: UploadFile = File(...)):
    """
    Nhận 1 file PDF hoặc DOCX, trích xuất văn bản,
    gọi GenAI tóm tắt và trả về kết quả.
    """
    # lưu tạm file lên disk
    ext = file.filename.split(".")[-1].lower()


    tmp_path = f"/tmp/{file.filename}"
    with open(tmp_path, "wb") as f:
        f.write(await file.read())


    # trích xuất text
    if ext == "pdf":
        text = extract_pdf_text(tmp_path)
    elif ext in ("docx", "doc"):
        text = extract_docx_text(tmp_path)
    else:
        raise HTTPException(status_code=400, detail="Chỉ hỗ trợ PDF và DOCX")

    # nếu quá dài, có thể cắt bớt
    if len(text) > 100_000:
        text = text[:100_000]

    # tóm tắt
    summary = summarize_text(text)
    return {"summary": summary}
