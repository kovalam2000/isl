FROM python:3.12-slim

WORKDIR /app

# Install dependencies first (layer is cached unless requirements change)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code and frontend
COPY app/ app/
COPY frontend/ frontend/

# PORT is injected by Railway / Render / Fly.io at runtime
ENV PORT=8000
EXPOSE 8000

# Shell form so ${PORT} is expanded at container start
CMD python3 -m uvicorn app.main:app --host 0.0.0.0 --port ${PORT}
