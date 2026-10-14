from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import init_db
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


@app.get("/health", tags=["Health"])
async def health_check():
    db_status = "connected"
    try:
        from sqlalchemy import text
        async with async_engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"connecting ({type(e).__name__})"

    return {
        "status": "ok",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "database": db_status
    }


@app.get("/", tags=["Root"])
async def root():
    return {
        "message": "Benvenuto in CorpNexus API - Corporate Intelligence System",
        "docs": "/docs",
        "health": "/health"
    }
