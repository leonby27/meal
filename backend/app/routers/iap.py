"""IAP endpoints — verify, query, link, webhooks, promo.

Endpoints in this file are the only place the client should touch for
subscription state. The local `is_premium` flag in the Flutter app is
deprecated: it now only acts as an offline cache of the latest answer
from `GET /entitlement`.

Webhook URLs to register in App Store Connect / Play Console:
  - Apple: POST https://bodymealapp.ru/api/iap/apple/webhook
  - Google: POST https://bodymealapp.ru/api/iap/google/webhook  (Pub/Sub push)

Both webhooks accept Apple's / Google's payload verbatim and do their own
signature verification — they require no auth header.
"""
from __future__ import annotations

import logging
import traceback
from collections import deque
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_promo_codes, settings
from app.database import get_db
from app.models.entitlement import Entitlement
from app.routers.deps import get_current_user_id, get_optional_user_id
from app.services.iap import apple as apple_iap
from app.services.iap import entitlement as ent_svc

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/iap", tags=["iap"])


# =============================================================================
# Schemas
# =============================================================================


class VerifyRequest(BaseModel):
    """Sent by the client right after a successful purchase OR restore.

    `app_account_token` is a UUID the client mints once per install and
    binds to every purchase via `PurchaseParam.applicationUserName` — that
    same value comes back inside the signed Apple transaction, letting us
    match webhook events to the right device even before the user logs in.
    """
    store: str  # 'apple' | 'google'
    product_id: str
    server_verification_data: str
    app_account_token: str
    environment_hint: Optional[str] = None  # 'sandbox' | 'production'


class EntitlementResponse(BaseModel):
    is_active: bool
    plan: Optional[str] = None
    store: Optional[str] = None
    product_id: Optional[str] = None
    expires_at: Optional[datetime] = None
    auto_renew_enabled: Optional[bool] = None
    is_in_trial: Optional[bool] = None
    is_in_grace_period: Optional[bool] = None
    environment: Optional[str] = None


class LinkRequest(BaseModel):
    app_account_token: str


class LinkResponse(BaseModel):
    linked_count: int
    entitlement: EntitlementResponse


class PromoRedeemRequest(BaseModel):
    code: str
    app_account_token: str


# =============================================================================
# Helpers
# =============================================================================


def _to_response(row: Optional[Entitlement]) -> EntitlementResponse:
    if row is None:
        return EntitlementResponse(is_active=False)
    return EntitlementResponse(
        is_active=ent_svc.is_active(row),
        plan=row.plan,
        store=row.store,
        product_id=row.product_id,
        expires_at=row.expires_at,
        auto_renew_enabled=row.auto_renew_enabled,
        is_in_trial=row.is_in_trial,
        is_in_grace_period=row.is_in_grace_period,
        environment=row.environment,
    )


async def _current_state(
    db: AsyncSession,
    user_id: Optional[str],
    app_account_token: Optional[str],
) -> EntitlementResponse:
    rows = await ent_svc.find_for_principal(
        db, user_id=user_id, app_account_token=app_account_token
    )
    return _to_response(ent_svc.pick_best(rows))


# =============================================================================
# Debug — ring buffer of recent Apple webhook traffic + library versions,
# so we can diagnose without shell access to the container.
# Not gated; payloads aren't secret (Apple signs them, anyone with our URL
# would see the same), and read-only access can't hurt anything.
# =============================================================================
_recent_apple_webhooks: deque = deque(maxlen=20)


def _record_webhook(body: dict, status_code: int, response: dict):
    # Keep the whole signedPayload so we can reproduce locally — it's not
    # secret (Apple's signed envelope, public over the wire) and the
    # buffer is capped at 20 entries.
    _recent_apple_webhooks.append(
        {
            "at": datetime.utcnow().isoformat(),
            "status": status_code,
            "body": body,
            "response": response,
        }
    )


@router.get("/debug/recent-apple-webhooks")
async def debug_recent_apple_webhooks():
    return {"count": len(_recent_apple_webhooks), "items": list(_recent_apple_webhooks)}


@router.get("/debug/versions")
async def debug_versions():
    out: dict[str, str] = {}
    for pkg in (
        "app-store-server-library",
        "google-api-python-client",
        "cryptography",
        "pyjwt",
        "pyopenssl",
    ):
        try:
            from importlib.metadata import version as _v
            out[pkg] = _v(pkg)
        except Exception as e:
            out[pkg] = f"err: {e}"
    out["apple_app_apple_id_set"] = str(bool(settings.apple_app_apple_id))
    out["apple_bundle_id"] = settings.apple_bundle_id
    return out


# =============================================================================
# Verify — called after purchase or restore
# =============================================================================


@router.post("/verify", response_model=EntitlementResponse)
async def verify(
    req: VerifyRequest,
    user_id: Optional[str] = Depends(get_optional_user_id),
    db: AsyncSession = Depends(get_db),
) -> EntitlementResponse:
    if req.store == "apple":
        try:
            payload, env = apple_iap.verify_signed_transaction(
                req.server_verification_data,
                environment_hint=req.environment_hint,
            )
        except RuntimeError as e:
            # Creds missing on this deployment — surface as 503 so the
            # client can retry later (and so we don't masquerade as 500).
            logger.error("Apple IAP not configured: %s", e)
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"Apple IAP not configured: {e}",
            )
        except ValueError as e:
            logger.warning("Apple verification rejected: %s", e)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Apple verification failed: {e}",
            )

        tx = apple_iap.transaction_to_dict(payload, env)

        # If the client lied about the token, prefer what Apple says — that's
        # what the webhook will use too, so the rows must match.
        token = tx["app_account_token"] or req.app_account_token

        row = await ent_svc.upsert_apple(
            db,
            user_id=user_id,
            app_account_token=token,
            tx=tx,
        )
        return _to_response(row)

    if req.store == "google":
        from app.services.iap import google as google_iap
        try:
            state = google_iap.verify_purchase_token(
                package_name=settings.google_play_package_name,
                product_id=req.product_id,
                purchase_token=req.server_verification_data,
            )
        except google_iap.GoogleNotConfigured as e:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=str(e),
            )
        except Exception as e:
            logger.warning("Google verification rejected: %s", e)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Google verification failed: {e}",
            )

        token = state.app_account_token or req.app_account_token
        row = await ent_svc.upsert_google(
            db, user_id=user_id, app_account_token=token, state=state,
        )
        return _to_response(row)

    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail=f"Unknown store: {req.store}",
    )


# =============================================================================
# Read current state
# =============================================================================


@router.get("/entitlement", response_model=EntitlementResponse)
async def get_entitlement(
    app_account_token: Optional[str] = None,
    user_id: Optional[str] = Depends(get_optional_user_id),
    db: AsyncSession = Depends(get_db),
) -> EntitlementResponse:
    """Returns the best entitlement for this caller.

    Auth header is optional: guests pass `?app_account_token=...`,
    signed-in users get both joined automatically.
    """
    if not user_id and not app_account_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provide either Authorization or app_account_token",
        )
    return await _current_state(db, user_id, app_account_token)


# =============================================================================
# Link anonymous purchases to a freshly-logged-in user
# =============================================================================


@router.post("/link", response_model=LinkResponse)
async def link(
    req: LinkRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
) -> LinkResponse:
    count = await ent_svc.link_anonymous_to_user(
        db, app_account_token=req.app_account_token, user_id=user_id
    )
    state = await _current_state(db, user_id, req.app_account_token)
    return LinkResponse(linked_count=count, entitlement=state)


# =============================================================================
# Promo codes
# =============================================================================


@router.post("/promo/redeem", response_model=EntitlementResponse)
async def redeem_promo(
    req: PromoRedeemRequest,
    user_id: Optional[str] = Depends(get_optional_user_id),
    db: AsyncSession = Depends(get_db),
) -> EntitlementResponse:
    code = req.code.strip()
    if code not in get_promo_codes():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid promo code",
        )
    row = await ent_svc.upsert_promo(
        db,
        user_id=user_id,
        app_account_token=req.app_account_token,
        code=code,
    )
    return _to_response(row)


# =============================================================================
# Apple webhook — App Store Server Notifications V2
# =============================================================================


@router.post("/apple/webhook")
async def apple_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    """Receives App Store Server Notifications V2.

    The body is `{"signedPayload": "<JWS>"}`. We verify, decode, and update
    the matching entitlement row. Apple retries failed deliveries for up
    to 3 days, so as long as we either succeed or 5xx, we won't miss
    events permanently — but we should always try to be idempotent.
    """
    body = await request.json()
    signed = body.get("signedPayload")
    if not signed:
        resp = {"detail": "signedPayload missing"}
        _record_webhook(body, 400, resp)
        raise HTTPException(status_code=400, detail=resp["detail"])

    try:
        notification, env = apple_iap.verify_notification(signed)
    except RuntimeError as e:
        # Creds missing — return 503 so Apple retries (up to 3 days). By
        # then we either have creds set or accept the data loss for a
        # handful of events in the window.
        logger.error("Apple webhook hit but IAP not configured: %s", e)
        resp = {"detail": f"Apple IAP not configured: {e}"}
        _record_webhook(body, 503, resp)
        raise HTTPException(status_code=503, detail=resp["detail"])
    except ValueError as e:
        tb = traceback.format_exc()
        logger.warning("Apple webhook verification failed: %s\n%s", e, tb)
        resp = {"detail": f"Invalid notification: {e}", "trace": tb.splitlines()[-12:]}
        _record_webhook(body, 400, resp)
        raise HTTPException(status_code=400, detail=resp)

    data = notification.data
    if data is None or data.signedTransactionInfo is None:
        # Test notifications + types like CONSUMPTION_REQUEST land here:
        # no transaction info, just acknowledge.
        logger.info(
            "Apple notification %s/%s with no transaction info",
            notification.notificationType, notification.subtype,
        )
        resp = {
            "ok": True,
            "notificationType": str(notification.notificationType),
            "subtype": str(notification.subtype),
        }
        _record_webhook(body, 200, resp)
        return resp

    # Decode the embedded transaction via the matching environment client.
    tx_payload = apple_iap.decode_signed_transaction(data.signedTransactionInfo, env)
    tx = apple_iap.transaction_to_dict(tx_payload, env)

    # Renewal info tells us whether the user re-enabled auto-renew, is in
    # the grace period, etc.
    auto_renew = True
    is_grace = False
    if data.signedRenewalInfo:
        from appstoreserverlibrary.models.AutoRenewStatus import AutoRenewStatus
        renewal = apple_iap.decode_signed_renewal_info(data.signedRenewalInfo, env)
        auto_renew = renewal.autoRenewStatus == AutoRenewStatus.ON
        # gracePeriodExpiresDate is set while we're in the grace period.
        is_grace = renewal.gracePeriodExpiresDate is not None

    # Look up by original_transaction_id — webhook may arrive before the
    # client's /verify call for fresh purchases. For legacy subs that were
    # purchased without an appAccountToken, we still update the row (we
    # keyed by transaction id, not token). Only truly orphan webhooks
    # (no existing row AND no token) get dropped.
    stmt = select(Entitlement).where(
        Entitlement.store == "apple",
        Entitlement.original_transaction_id == tx["original_transaction_id"],
    )
    existing = (await db.execute(stmt)).scalar_one_or_none()

    token = tx["app_account_token"]
    if not token and existing is not None:
        token = existing.app_account_token
    if not token:
        logger.error(
            "Apple notification has no appAccountToken and no existing row: %s",
            tx["original_transaction_id"],
        )
        return {"ok": True, "warning": "orphan_notification"}

    user_id = existing.user_id if existing else None

    await ent_svc.upsert_apple(
        db,
        user_id=user_id,
        app_account_token=token,
        tx=tx,
        auto_renew_enabled=auto_renew,
        is_in_grace_period=is_grace,
    )

    logger.info(
        "Apple notification processed: type=%s subtype=%s product=%s expires=%s",
        notification.notificationType,
        notification.subtype,
        tx["product_id"],
        tx["expires_at"],
    )
    resp = {"ok": True}
    _record_webhook(body, 200, resp)
    return resp


# =============================================================================
# Google webhook — Real-time Developer Notifications (Pub/Sub push)
# =============================================================================


@router.post("/google/webhook")
async def google_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    """Receives Google Real-time Developer Notifications via Pub/Sub push.

    The envelope is the standard Pub/Sub push body; the inner notification
    carries either `subscriptionNotification`, `voidedPurchaseNotification`,
    or `testNotification`. We treat every event as a "go look again" signal
    and re-query `subscriptionsv2.get` for the authoritative state instead
    of trusting any field in the event itself.

    We always return 200 (unless the API call genuinely fails). Pub/Sub
    retries on non-2xx, and unlike Apple a stuck retry has no automatic
    cutoff — so anything we can't process gets logged and ack'd.
    """
    from app.services.iap import google as google_iap

    body = await request.json()
    notification = google_iap.parse_rtdn_envelope(body)
    if notification is None:
        return {"ok": True, "ignored": "no_payload"}

    package_name = (
        notification.get("packageName") or settings.google_play_package_name
    )

    if notification.get("testNotification"):
        logger.info("Google RTDN test notification received")
        return {"ok": True}

    voided = notification.get("voidedPurchaseNotification") or {}
    if voided:
        purchase_token = voided.get("purchaseToken")
        if purchase_token:
            stmt = select(Entitlement).where(
                Entitlement.store == "google",
                Entitlement.original_transaction_id == purchase_token,
            )
            row = (await db.execute(stmt)).scalar_one_or_none()
            if row is not None and row.revoked_at is None:
                row.revoked_at = datetime.utcnow()
                row.last_event_at = datetime.utcnow()
                await db.commit()
        return {"ok": True}

    sub = notification.get("subscriptionNotification") or {}
    if not sub:
        return {"ok": True, "ignored": "unrecognized_notification"}

    purchase_token = sub.get("purchaseToken")
    if not purchase_token:
        return {"ok": True, "ignored": "no_purchase_token"}

    if not google_iap.is_configured():
        # Creds missing — ack so Pub/Sub stops retrying; the reconciler
        # will catch up once env vars are set.
        logger.warning(
            "Google RTDN received but service account not configured "
            "(token=%s)", purchase_token,
        )
        return {"ok": True, "ignored": "google_not_configured"}

    try:
        state = google_iap.fetch_subscription_state(package_name, purchase_token)
    except Exception as e:
        logger.warning(
            "Google RTDN lookup failed for token=%s: %s", purchase_token, e
        )
        # 500 → Pub/Sub will retry. For permanent failures the reconciler
        # would still try later, but transient API blips deserve a retry.
        raise HTTPException(status_code=500, detail="Play API lookup failed")

    # Preserve user_id if we know it; for a webhook arriving before /verify,
    # the row goes in anonymous and /link binds it later.
    stmt = select(Entitlement).where(
        Entitlement.store == "google",
        Entitlement.original_transaction_id == purchase_token,
    )
    existing = (await db.execute(stmt)).scalar_one_or_none()
    bound_user_id = existing.user_id if existing else None

    token = state.app_account_token
    if not token and existing is not None:
        token = existing.app_account_token
    if not token:
        logger.error(
            "Google RTDN missing obfuscatedExternalAccountId and no existing "
            "row: %s", purchase_token,
        )
        return {"ok": True, "warning": "orphan_notification"}

    await ent_svc.upsert_google(
        db, user_id=bound_user_id, app_account_token=token, state=state,
    )

    logger.info(
        "Google notification processed: type=%s product=%s expires=%s",
        sub.get("notificationType"),
        state.product_id,
        state.expires_at,
    )
    return {"ok": True}
