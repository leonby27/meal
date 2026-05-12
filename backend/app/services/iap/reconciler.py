"""Hourly safety net: re-query Apple/Google for subscriptions whose local
`expires_at` is in the past.

In normal operation App Store Server Notifications V2 / Google RTDN keep
everything in sync. A missed webhook (network blip, restart during
delivery, Apple/Google side outage) would leave a stale "still active"
row in the DB; this task catches those.
"""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime

from appstoreserverlibrary.models.Environment import Environment

from app.config import settings
from app.database import async_session
from app.models.entitlement import Entitlement
from app.services.iap import apple as apple_iap
from app.services.iap import entitlement as ent_svc
from app.services.iap import google as google_iap
from sqlalchemy import select

logger = logging.getLogger(__name__)

RECONCILE_INTERVAL_SECONDS = 60 * 60  # 1 hour


async def _reconcile_apple(db, now: datetime) -> int:
    stmt = (
        select(Entitlement)
        .where(Entitlement.store == "apple")
        .where(Entitlement.expires_at.is_not(None))
        .where(Entitlement.expires_at < now)
        .where(Entitlement.revoked_at.is_(None))
    )
    rows = (await db.execute(stmt)).scalars().all()
    refreshed = 0
    for row in rows:
        try:
            first = (
                Environment.SANDBOX
                if row.environment == "sandbox"
                else Environment.PRODUCTION
            )
            second = (
                Environment.PRODUCTION
                if first is Environment.SANDBOX
                else Environment.SANDBOX
            )
            payload, env = apple_iap.lookup_transaction(
                row.latest_transaction_id or row.original_transaction_id,
                first=first,
                second=second,
            )
            tx = apple_iap.transaction_to_dict(payload, env)
            await ent_svc.upsert_apple(
                db,
                user_id=row.user_id,
                app_account_token=row.app_account_token,
                tx=tx,
                # Best-effort: webhook delivers the precise auto-renew /
                # grace state, but for reconciliation we carry the row's
                # current values forward and let the next event correct.
                auto_renew_enabled=row.auto_renew_enabled,
                is_in_grace_period=row.is_in_grace_period,
            )
            refreshed += 1
        except Exception as e:
            logger.warning(
                "Apple reconcile failed for %s: %s",
                row.original_transaction_id,
                e,
            )
    return refreshed


async def _reconcile_google(db, now: datetime) -> int:
    if not google_iap.is_configured():
        return 0
    stmt = (
        select(Entitlement)
        .where(Entitlement.store == "google")
        .where(Entitlement.expires_at.is_not(None))
        .where(Entitlement.expires_at < now)
        .where(Entitlement.revoked_at.is_(None))
    )
    rows = (await db.execute(stmt)).scalars().all()
    refreshed = 0
    for row in rows:
        try:
            state = google_iap.fetch_subscription_state(
                settings.google_play_package_name,
                row.original_transaction_id,
            )
            await ent_svc.upsert_google(
                db,
                user_id=row.user_id,
                app_account_token=row.app_account_token,
                state=state,
            )
            refreshed += 1
        except Exception as e:
            logger.warning(
                "Google reconcile failed for %s: %s",
                row.original_transaction_id,
                e,
            )
    return refreshed


async def _reconcile_once() -> int:
    now = datetime.utcnow()
    async with async_session() as db:
        apple_n = await _reconcile_apple(db, now)
        google_n = await _reconcile_google(db, now)
        return apple_n + google_n


async def run_loop():
    """Run forever — schedule from `main.py` lifespan."""
    logger.info(
        "Entitlement reconciler started (every %ds)", RECONCILE_INTERVAL_SECONDS
    )
    while True:
        try:
            await asyncio.sleep(RECONCILE_INTERVAL_SECONDS)
            n = await _reconcile_once()
            if n:
                logger.info("Reconciler refreshed %d expired entitlements", n)
        except asyncio.CancelledError:
            raise
        except Exception as e:
            logger.exception("Reconciler iteration crashed: %s", e)
