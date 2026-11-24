FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && useradd -m appuser
COPY app.py .
USER appuser
CMD ["gunicorn","-b","0.0.0.0:8443","app:app"]
