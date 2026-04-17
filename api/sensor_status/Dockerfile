FROM python:3.12-slim
WORKDIR /app
COPY sensor_status/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY shared ./shared
COPY sensor_status ./sensor_status
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1
EXPOSE 8000
CMD ["uvicorn", "sensor_status.main:app", "--host", "0.0.0.0", "--port", "8000"]
