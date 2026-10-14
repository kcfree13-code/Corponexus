import asyncio
from app.core.database import AsyncSessionLocal, init_db
from app.api.v1.system import seed_database


async def seed():
    print("Inizializzazione database...")
    await init_db()

    async with AsyncSessionLocal() as db:
        res = await seed_database(force=True, db=db)
        print("Seed completato:", res.get("message"))
        print("Aziende disponibili:", res.get("companies"))


if __name__ == "__main__":
    asyncio.run(seed())
