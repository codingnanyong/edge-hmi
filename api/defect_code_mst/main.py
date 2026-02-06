"""FastAPI app for defect_code_mst only. Defect reason code definition."""
from fastapi import FastAPI

from defect_code_mst.router import router

app = FastAPI(title="edge-hmi defect_code_mst API", version="1.0.1")
app.include_router(router)
