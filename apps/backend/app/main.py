from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import init_db, async_engine
from app.api.v1 import api_v1_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize DB tables on startup gracefully
    try:
        await init_db()
        print("Database tables initialized successfully.")
    except Exception as e:
        print(f"Warning: Database not ready during startup ({e}). Continuing startup...")
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="CorpNexus Corporate Intelligence & Graph Engine Backend. Zero-Inference, Source Provenance, Permanent Cache.",
    lifespan=lifespan
)

# CORS configuration for Flutter Android and Web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API v1 routes
app.include_router(api_v1_router, prefix=settings.API_V1_STR)


from fastapi import Request
from fastapi.responses import HTMLResponse, JSONResponse
from app.web_console import WEB_CONSOLE_HTML

@app.get("/health", tags=["Health"])
async def health_check():
    db_status = "connected"
    try:
        from sqlalchemy import text
        async with async_engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"connecting ({type(e).__name__}: {str(e)})"

    return {
        "status": "ok",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "database": db_status
    }


@app.get("/", tags=["Root"], response_class=HTMLResponse)
async def root(request: Request):
    """
    Serves the Cyber-Forensic Web Intelligence Console for browser users.
    If explicitly requested as application/json, returns API metadata.
    """
    accept = request.headers.get("accept", "")
    if "application/json" in accept and "text/html" not in accept:
        return JSONResponse(
            content={
                "message": "Benvenuto in CorpNexus API - Corporate Intelligence System",
                "docs": "/docs",
                "health": "/health",
                "explorer": "/explorer"
            }
        )
    return HTMLResponse(content=WEB_CONSOLE_HTML)


@app.get("/explorer", tags=["Web Console"], response_class=HTMLResponse)
@app.get("/app", tags=["Web Console"], response_class=HTMLResponse)
async def web_console():
    return HTMLResponse(content=WEB_CONSOLE_HTML)
