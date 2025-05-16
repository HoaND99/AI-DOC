FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=8080 PYTHONUNBUFFERED=1

# Cấu hình gunicorn bind 0.0.0.0 (mọi interface) và port từ biến môi trường
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:${PORT}", "--workers", "1", "--timeout", "300"]
