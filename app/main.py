from fastapi import FastAPI
from fastapi.responses import JSONResponse
from prometheus_client import make_asgi_app
from sqlalchemy import create_engine, text
import os

app = FastAPI()

metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

DATABASE_URL = (
    f"postgresql://{os.getenv('DB_USER')}:{os.getenv('password')}"
    f"@{os.getenv('DB_HOST')}:5432/{os.getenv('DB_NAME')}"
)
engine = create_engine(DATABASE_URL)

@app.get("/")
def index():
    return "Hello, world!"

@app.get("/health", tags=["Health"])
def health_check():
    return JSONResponse(content={"status": "ok"})

@app.get("/db-health", tags=["Health"])
def db_health():
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return JSONResponse(content={"status": "ok", "database": "connected"})
    except Exception as e:
        return JSONResponse(status_code=503, content={"status": "error", "database": str(e)})