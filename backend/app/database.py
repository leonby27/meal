import ssl

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from app.config import settings


def _build_engine_kwargs() -> dict:
    kwargs: dict = {"echo": False}

    is_postgres = settings.database_url.startswith("postgresql")
    if is_postgres:
        kwargs.update(
            pool_size=5,
            max_overflow=10,
            pool_timeout=30,
            pool_recycle=1800,
            pool_pre_ping=True,
        )
        connect_args: dict = {"timeout": 10}
        if settings.database_ssl:
            ssl_ctx = ssl.create_default_context()
            ssl_ctx.check_hostname = False
            ssl_ctx.verify_mode = ssl.CERT_NONE
            connect_args["ssl"] = ssl_ctx
        kwargs["connect_args"] = connect_args

    return kwargs


engine = create_async_engine(settings.database_url, **_build_engine_kwargs())
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()
