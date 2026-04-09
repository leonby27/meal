import asyncio
import logging
import os
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.database import engine, Base, async_session
from app.routers import auth, recognize, products, sync

logger = logging.getLogger(__name__)

SELF_PING_INTERVAL = int(os.getenv("SELF_PING_INTERVAL", "240"))


async def _init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables verified / created")


async def _keep_alive():
    """Ping ourselves to prevent the container from sleeping."""
    url = os.getenv("SELF_URL", "").rstrip("/")
    if not url:
        logger.info("SELF_URL not set — keep-alive disabled")
        return
    logger.info("Keep-alive started: pinging %s every %ds", url, SELF_PING_INTERVAL)
    async with httpx.AsyncClient(timeout=10) as client:
        while True:
            await asyncio.sleep(SELF_PING_INTERVAL)
            try:
                r = await client.get(f"{url}/health")
                logger.debug("Keep-alive ping: %s", r.status_code)
            except Exception as e:
                logger.warning("Keep-alive ping failed: %s", e)


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await asyncio.wait_for(_init_db(), timeout=15)
    except Exception as e:
        logger.error("DB init failed (app will still start): %s", e)
    ping_task = asyncio.create_task(_keep_alive())
    yield
    ping_task.cancel()
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
