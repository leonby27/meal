import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.database import engine, Base, async_session
from app.routers import auth, recognize, products, sync

logger = logging.getLogger(__name__)


async def _init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables verified / created")


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await asyncio.wait_for(_init_db(), timeout=15)
    except Exception as e:
        logger.error("DB init failed (app will still start): %s", e)
    yield
    await engine.dispose()


app = FastAPI(
    title="MealTracker API",
    version="1.0.0",
    description="API для приложения учёта питания",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(recognize.router)
app.include_router(products.router)
app.include_router(sync.router)


@app.get("/")
async def root():
    return {"status": "ok"}


@app.get("/health")
async def health():
    try:
        async with async_session() as session:
            await session.execute(text("SELECT 1"))
        return {"status": "ok", "database": "connected"}
    except Exception as e:
        logger.error("Health check DB failure: %s", e)
        return {"status": "degraded", "database": "unavailable"}
