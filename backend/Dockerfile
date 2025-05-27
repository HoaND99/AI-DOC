FROM python:3.11-slim

WORKDIR /app


COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


COPY . .

# Cloud Run injects PORT env (mặc định 8080)
EXPOSE 8080

# shell form để $PORT expand
CMD ["sh", "-c", "uvicorn app:app --host 0.0.0.0 --port $PORT"]
