from fastapi import FastAPI
from fastapi.responses import JSONResponse
from prometheus_client import make_asgi_app

app = FastAPI()

metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

@app.get("/")
def index():
    return "Hello, world!"

@app.get("/health", tags=["Health"])
def health_check():
    return JSONResponse(content={"status": "ok"})