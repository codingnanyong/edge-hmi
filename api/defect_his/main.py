"""FastAPI app for defect_his only. Defect detail by reason per production record."""
from fastapi import FastAPI

from defect_his.router import router

app = FastAPI(title="edge-hmi defect_his API", version="1.0.1")
app.include_router(router)
