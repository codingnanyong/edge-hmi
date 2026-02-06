FROM python:3.12-slim
WORKDIR /app
COPY defect_code_mst/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY shared ./shared
COPY defect_code_mst ./defect_code_mst
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1
EXPOSE 8000
CMD ["uvicorn", "defect_code_mst.main:app", "--host", "0.0.0.0", "--port", "8000"]
