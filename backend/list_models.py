import os
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()
API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    raise RuntimeError("Bạn phải thiết lập biến môi trường GOOGLE_API_KEY")

genai.configure(api_key=API_KEY)
print("Available models:")
for m in genai.list_models():
    print(f"- {m.name}")
