FROM python:3.12-slim
WORKDIR /app
COPY parts_mst/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY shared ./shared
COPY parts_mst ./parts_mst
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1
EXPOSE 8000
CMD ["uvicorn", "parts_mst.main:app", "--host", "0.0.0.0", "--port", "8000"]
