import urllib.parse
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from app.core.config import settings

# Normalize scheme for asyncpg
raw_url = settings.DATABASE_URL
if raw_url.startswith("postgres://"):
    raw_url = raw_url.replace("postgres://", "postgresql+asyncpg://", 1)
elif raw_url.startswith("postgresql://") and not raw_url.startswith("postgresql+asyncpg://"):
    raw_url = raw_url.replace("postgresql://", "postgresql+asyncpg://", 1)

# Handle SSL parameters for asyncpg compatibility (e.g. Vercel Postgres / Neon / Supabase)
parsed = urllib.parse.urlparse(raw_url)
query_params = urllib.parse.parse_qs(parsed.query)
connect_args = {}

if "sslmode" in query_params or any(c in parsed.netloc for c in ["neon.tech", "vercel-storage.com", "supabase", "rlwy.net", "aws"]):
    connect_args["ssl"] = True

# Strip parameters from psycopg/libpq query string that asyncpg does not accept (e.g. sslmode, channel_binding)
unsupported_asyncpg_params = {"sslmode", "channel_binding", "endpoint"}
clean_params = {k: v for k, v in query_params.items() if k not in unsupported_asyncpg_params}
clean_query = urllib.parse.urlencode(clean_params, doseq=True)
db_url = urllib.parse.urlunparse(parsed._replace(query=clean_query))

async_engine = create_async_engine(
    db_url,
    echo=False,
    future=True,
    pool_pre_ping=True,
    connect_args=connect_args
)

AsyncSessionLocal = async_sessionmaker(
    bind=async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)

Base = declarative_base()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    async with async_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
