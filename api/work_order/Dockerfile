FROM python:3.12-slim
WORKDIR /app
COPY work_order/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY shared ./shared
COPY work_order ./work_order
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1
EXPOSE 8000
CMD ["uvicorn", "work_order.main:app", "--host", "0.0.0.0", "--port", "8000"]
