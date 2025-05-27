FROM python:3.11-slim
WORKDIR /app

# Copy và cài dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source
COPY . .

# Port expose (không bắt buộc nhưng rõ ràng)
EXPOSE 8080

# Chạy uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
