FROM python:3.11-slim

# set a more predictable Python environment
ENV PYTHONUNBUFFERED=1

WORKDIR /app


COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


COPY . .

# tell Cloud Run which port to listen on
ENV PORT=8080
EXPOSE 8080

# run Uvicorn on 0.0.0.0:8080
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
