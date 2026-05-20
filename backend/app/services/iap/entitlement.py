"""Pure-data layer over the `entitlements` table.

`is_active` is computed here in one place and read by both the router (for
client responses) and the cron job (for picking which rows to recheck).
"""
from __future__ import annotations

from datetime import datetime, timedelta
from typing import TYPE_CHECKING, Optional

from sqlalchemy import or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.entitlement import Entitlement

if TYPE_CHECKING:
    from app.services.iap.google import GoogleSubscriptionState

# Mapping from store productId → friendly plan name used by the client UI.
# Kept here (not on the client) so we can add yearly_premium_2026, promo
# variants etc. without shipping a new app version.
_PRODUCT_TO_PLAN = {
    "weekly_premium": "weekly",
    "yearly_premium": "yearly",
}


def product_to_plan(product_id: str) -> str:
    return _PRODUCT_TO_PLAN.get(product_id, product_id)


def is_active(e: Entitlement, now: Optional[datetime] = None) -> bool:
    """Single source of truth. Mirror exactly on the client (read-only)."""
    if e.revoked_at is not None:
        return False
    if e.store == "promo":
        # Promo grants are lifetime; expires_at is NULL.
        return e.expires_at is None or (now or datetime.utcnow()) < e.expires_at
    if e.expires_at is None:
        return False
    moment = now or datetime.utcnow()
    cushion = timedelta(hours=settings.entitlement_grace_hours)
    return moment < (e.expires_at + cushion)


async def upsert_apple(
    db: AsyncSession,
    *,
    user_id: Optional[str],
    app_account_token: str,
    tx: dict,
    auto_renew_enabled: bool = True,
    is_in_grace_period: bool = False,
) -> Entitlement:
    """Insert or update the entitlement row for an Apple transaction.

    `tx` is the flattened dict from `apple.transaction_to_dict()`.
    Uniqueness is on (store, original_transaction_id), so a fresh row is
    created exactly once per subscription regardless of renewals.

    /verify and the App Store webhook race each other on first purchase, so
    we retry once on IntegrityError — the second pass finds the row the
    other writer created and falls into the update branch.
    """
    for attempt in range(2):
        stmt = select(Entitlement).where(
            Entitlement.store == "apple",
            Entitlement.original_transaction_id == tx["original_transaction_id"],
        )
        row = (await db.execute(stmt)).scalar_one_or_none()

        if row is None:
            row = Entitlement(
                user_id=user_id,
                app_account_token=app_account_token,
                store="apple",
                product_id=tx["product_id"],
                plan=product_to_plan(tx["product_id"]),
                original_transaction_id=tx["original_transaction_id"],
                latest_transaction_id=tx["transaction_id"],
                expires_at=tx["expires_at"],
                is_in_trial=tx["is_in_trial"],
                is_in_grace_period=is_in_grace_period,
                auto_renew_enabled=auto_renew_enabled,
                environment=tx["environment"],
                revoked_at=tx["revocation_date"],
                last_event_at=datetime.utcnow(),
            )
            db.add(row)
        else:
            row.latest_transaction_id = tx["transaction_id"] or row.latest_transaction_id
            row.product_id = tx["product_id"]
            row.plan = product_to_plan(tx["product_id"])
            row.expires_at = tx["expires_at"]
            row.is_in_trial = tx["is_in_trial"]
            row.is_in_grace_period = is_in_grace_period
            row.auto_renew_enabled = auto_renew_enabled
            row.environment = tx["environment"]
            row.revoked_at = tx["revocation_date"]
            row.last_event_at = datetime.utcnow()
            if user_id and not row.user_id:
                row.user_id = user_id

        try:
            await db.commit()
            await db.refresh(row)
            return row
        except IntegrityError:
            await db.rollback()
            if attempt == 1:
                raise
    raise RuntimeError("unreachable")


async def upsert_google(
    db: AsyncSession,
    *,
    user_id: Optional[str],
    app_account_token: str,
    state: "GoogleSubscriptionState",
) -> Entitlement:
    """Insert or update the entitlement row for a Google subscription.

    Google issues a fresh purchaseToken on upgrade/downgrade; `state.linked_
    purchase_token` points back at the previous one. We migrate the old row's
    `user_id` forward so a freshly upgraded sub stays attributed to the same
    user even if /verify hasn't been called yet.
    """
    for attempt in range(2):
        stmt = select(Entitlement).where(
            Entitlement.store == "google",
            Entitlement.original_transaction_id == state.purchase_token,
        )
        row = (await db.execute(stmt)).scalar_one_or_none()

        effective_user_id = user_id
        if row is None and state.linked_purchase_token:
            old_stmt = select(Entitlement).where(
                Entitlement.store == "google",
                Entitlement.original_transaction_id == state.linked_purchase_token,
            )
            old_row = (await db.execute(old_stmt)).scalar_one_or_none()
            if old_row is not None and effective_user_id is None:
                effective_user_id = old_row.user_id

        if row is None:
            row = Entitlement(
                user_id=effective_user_id,
                app_account_token=app_account_token,
                store="google",
                product_id=state.product_id,
                plan=product_to_plan(state.product_id),
                original_transaction_id=state.purchase_token,
                latest_transaction_id=state.latest_order_id,
                expires_at=state.expires_at,
                is_in_trial=state.is_in_trial,
                is_in_grace_period=state.is_in_grace_period,
                auto_renew_enabled=state.auto_renew_enabled,
                environment=state.environment,
                revoked_at=datetime.utcnow() if state.revoked else None,
                last_event_at=datetime.utcnow(),
            )
            db.add(row)
        else:
            row.latest_transaction_id = state.latest_order_id or row.latest_transaction_id
            row.product_id = state.product_id
            row.plan = product_to_plan(state.product_id)
            row.expires_at = state.expires_at
            row.is_in_trial = state.is_in_trial
            row.is_in_grace_period = state.is_in_grace_period
            row.auto_renew_enabled = state.auto_renew_enabled
            row.environment = state.environment
            if state.revoked and row.revoked_at is None:
                row.revoked_at = datetime.utcnow()
            row.last_event_at = datetime.utcnow()
            if effective_user_id and not row.user_id:
                row.user_id = effective_user_id

        try:
            await db.commit()
            await db.refresh(row)
            return row
        except IntegrityError:
            await db.rollback()
            if attempt == 1:
                raise
    raise RuntimeError("unreachable")


async def upsert_promo(
    db: AsyncSession,
    *,
    user_id: Optional[str],
    app_account_token: str,
    code: str,
) -> Entitlement:
    """Promo redemption: grants 7 days of premium, stackable.

    Each call adds a week to whichever is later — the current expiry or
    "now" — so re-entering a code mid-week doesn't waste remaining time
    and re-entering after expiry simply starts a fresh week. There's no
    cap on how many times the same code can be redeemed; the codes
    themselves are the access control (we trust [config.get_promo_codes]
    to be small and curated).

    The unique constraint (store, original_transaction_id) is satisfied
    by a synthetic `code:token` id so the same code can live on
    different devices without colliding.

    Legacy rows with `expires_at=NULL` (older lifetime-promo behavior)
    are preserved as-is — we don't downgrade an existing lifetime grant.
    """
    synthetic_id = f"{code}:{app_account_token}"
    stmt = select(Entitlement).where(
        Entitlement.store == "promo",
        Entitlement.original_transaction_id == synthetic_id,
    )
    row = (await db.execute(stmt)).scalar_one_or_none()

    now = datetime.utcnow()
    week = timedelta(days=7)

    if row is not None:
        # Don't downgrade a legacy lifetime grant (expires_at IS NULL).
        if row.expires_at is not None:
            base = row.expires_at if row.expires_at > now else now
            row.expires_at = base + week
        if user_id and not row.user_id:
            row.user_id = user_id
        # Re-redeeming after a revoke is an explicit user signal — they
        # typed the code again on the paywall, knowing it grants premium.
        # Clear `revoked_at` so the grant is actually live: otherwise
        # is_active() would return False even though we just extended
        # expires_at, and the user would see a silent no-op. The promo
        # codes are the access control; a re-redemption that wasn't
        # supposed to work would fail at the code-lookup gate in the
        # router, not here.
        row.revoked_at = None
        row.last_event_at = now
        await db.commit()
        await db.refresh(row)
        return row

    row = Entitlement(
        user_id=user_id,
        app_account_token=app_account_token,
        store="promo",
        product_id=f"promo_{code}",
        plan="promo",
        original_transaction_id=synthetic_id,
        expires_at=now + week,
        is_in_trial=False,
        is_in_grace_period=False,
        auto_renew_enabled=False,
        environment="production",
        last_event_at=now,
    )
    db.add(row)
    try:
        await db.commit()
        await db.refresh(row)
    except IntegrityError:
        # Concurrent redemption by the same device — refetch the winner.
        # We don't try to add yet another week here: the concurrent caller
        # already added one and a single user double-clicking shouldn't
        # double-stack.
        await db.rollback()
        row = (await db.execute(stmt)).scalar_one()
    return row


async def find_for_principal(
    db: AsyncSession,
    *,
    user_id: Optional[str],
    app_account_token: Optional[str],
) -> list[Entitlement]:
    """All entitlements that should be considered for this caller.

    Authenticated user sees everything bound to user_id PLUS anonymous rows
    that match their device token (covers a guest who just signed in but
    has not yet called /link, or a multi-device user).
    """
    if not user_id and not app_account_token:
        return []
    conditions = []
    if user_id:
        conditions.append(Entitlement.user_id == user_id)
    if app_account_token:
        conditions.append(Entitlement.app_account_token == app_account_token)
    stmt = select(Entitlement).where(or_(*conditions))
    rows = (await db.execute(stmt)).scalars().all()
    return list(rows)


def pick_best(rows: list[Entitlement]) -> Optional[Entitlement]:
    """Choose the entitlement to report to the client.

    Order: active wins; among active, the one expiring latest (or
    lifetime) wins; among inactive, the one expiring latest wins (so the
    client can show "expired on …" rather than the oldest stale row).
    """
    if not rows:
        return None
    now = datetime.utcnow()
    active = [r for r in rows if is_active(r, now)]
    pool = active or rows

    def sort_key(r: Entitlement) -> tuple[int, datetime]:
        # Lifetime (expires_at NULL) sorts above any timed row.
        if r.expires_at is None:
            return (1, datetime.max)
        return (0, r.expires_at)

    return max(pool, key=sort_key)


async def link_anonymous_to_user(
    db: AsyncSession, *, app_account_token: str, user_id: str
) -> int:
    """Bind every anonymous row for this device to the given user."""
    stmt = select(Entitlement).where(
        Entitlement.app_account_token == app_account_token,
        Entitlement.user_id.is_(None),
    )
    rows = (await db.execute(stmt)).scalars().all()
    for row in rows:
        row.user_id = user_id
    if rows:
        await db.commit()
    return len(rows)
