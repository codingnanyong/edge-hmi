"""FastAPI app for work_order only. Work order (생산 지시) master."""
from fastapi import FastAPI

from work_order.router import router

app = FastAPI(title="edge-hmi work_order API", version="1.0.1")
app.include_router(router)
