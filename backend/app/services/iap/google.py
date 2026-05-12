"""Google Play subscription verification.

Uses Google Play Developer API v3 — specifically
`androidpublisher.purchases.subscriptionsv2.get`, which returns a single
`SubscriptionPurchaseV2` document covering the whole sub: lineItems with
expiry, autoRenew flag, offer details, grace/hold/paused/expired state,
test-vs-real flag, and externalAccountIdentifiers (Google's analogue of
Apple's `appAccountToken`).

Notifications arrive via Real-time Developer Notifications (RTDN) pushed
from Cloud Pub/Sub as base64 JSON envelopes. We never trust the inner
notification body for entitlement state — it's only a "go look again"
signal. On every event we re-query `subscriptionsv2.get` for fresh truth.

Setup needed once before this code does anything:
  1. Create a GCP service account, grant it the role
     "Service Account User" in the linked Play project.
  2. In Play Console → API access, grant that service account
     "View financial data" (read-only is enough for entitlement use).
  3. Download the JSON key, set `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
     (paste full JSON) or `GOOGLE_PLAY_SERVICE_ACCOUNT_PATH` (mounted file).
  4. Create a Pub/Sub topic, link it under Monetization setup in Play
     Console as the RTDN target.
  5. Create a push subscription on that topic pointing at
     `https://bodymealapp.ru/api/iap/google/webhook`.
"""
from __future__ import annotations

import base64
import json
import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from threading import Lock
from typing import Optional

from app.config import settings

logger = logging.getLogger(__name__)


# -----------------------------------------------------------------------------
# Errors
# -----------------------------------------------------------------------------
class GoogleNotConfigured(RuntimeError):
    """Raised when a Google call is made but service-account creds are absent."""


# -----------------------------------------------------------------------------
# Normalized state — what the entitlement upsert path consumes
# -----------------------------------------------------------------------------
@dataclass
class GoogleSubscriptionState:
    purchase_token: str
    product_id: str
    expires_at: Optional[datetime]
    auto_renew_enabled: bool
    is_in_grace_period: bool
    is_in_trial: bool
    app_account_token: Optional[str]
    environment: str  # 'sandbox' | 'production'
    revoked: bool
    linked_purchase_token: Optional[str]
    latest_order_id: Optional[str]


# Google's SubscriptionState enum values, as strings in the v2 API responses.
_STATE_IN_GRACE_PERIOD = "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"
_STATE_EXPIRED = "SUBSCRIPTION_STATE_EXPIRED"


# -----------------------------------------------------------------------------
# Service-account auth + Play API client (lazy, thread-safe singleton)
# -----------------------------------------------------------------------------
_play_client = None
_play_client_lock = Lock()


def is_configured() -> bool:
    return bool(
        settings.google_play_service_account_json
        or settings.google_play_service_account_path
    )


def _load_credentials():
    from google.oauth2 import service_account

    scopes = ["https://www.googleapis.com/auth/androidpublisher"]
    if settings.google_play_service_account_json:
        info = json.loads(settings.google_play_service_account_json)
        return service_account.Credentials.from_service_account_info(
            info, scopes=scopes
        )
    if settings.google_play_service_account_path:
        return service_account.Credentials.from_service_account_file(
            settings.google_play_service_account_path, scopes=scopes
        )
    return None


def _get_play_client():
    global _play_client
    with _play_client_lock:
        if _play_client is not None:
            return _play_client
        creds = _load_credentials()
        if creds is None:
            raise GoogleNotConfigured(
                "Google Play service account not configured"
            )
        from googleapiclient.discovery import build
        _play_client = build(
            "androidpublisher",
            "v3",
            credentials=creds,
            cache_discovery=False,
        )
        return _play_client


# -----------------------------------------------------------------------------
# Parsing helpers
# -----------------------------------------------------------------------------
def _parse_rfc3339(s: Optional[str]) -> Optional[datetime]:
    """Google v2 returns RFC3339 strings. Normalize to naive UTC datetimes
    so they slot into our DateTime columns the same way Apple's millis do."""
    if not s:
        return None
    # Python's fromisoformat handles 'Z' suffix only from 3.11; fall back.
    iso = s.replace("Z", "+00:00")
    dt = datetime.fromisoformat(iso)
    return dt.astimezone(timezone.utc).replace(tzinfo=None)


def _parse_subscription_v2(resp: dict, purchase_token: str) -> GoogleSubscriptionState:
    line_items = resp.get("lineItems") or []
    if not line_items:
        raise ValueError("Google subscriptionsv2.get returned no lineItems")

    # On upgrade the API can briefly return two line items; the one with the
    # latest expiry is the live plan.
    def expiry(item: dict) -> datetime:
        return _parse_rfc3339(item.get("expiryTime")) or datetime.min

    active = max(line_items, key=expiry)
    expires_at = _parse_rfc3339(active.get("expiryTime"))
    product_id = active.get("productId", "")
    auto_renew_enabled = bool(
        (active.get("autoRenewingPlan") or {}).get("autoRenewEnabled", False)
    )

    state = resp.get("subscriptionState", "")
    is_in_grace_period = state == _STATE_IN_GRACE_PERIOD
    # Google delivers EXPIRED for both ran-out and refunded subs. Refunds also
    # come through `voidedPurchaseNotification` separately — we set revoked
    # only on the explicit voided path so the column reflects user intent
    # (refund) rather than natural expiry.
    revoked = False

    # Google's offer model: a paid base plan with optional offers. A free
    # trial is an offer phase on the base plan; the API doesn't tell us
    # *which* phase we're in, only that an offer was applied. So treating
    # any active `offerId` as "trial-ish" is a best-effort signal — the
    # client should not rely on it for entitlement gating, only for UI copy.
    offer_details = active.get("offerDetails") or {}
    is_in_trial = bool(offer_details.get("offerId"))

    ext_ids = resp.get("externalAccountIdentifiers") or {}
    app_account_token = (
        ext_ids.get("obfuscatedExternalAccountId")
        or ext_ids.get("externalAccountId")
    )

    environment = "sandbox" if resp.get("testPurchase") else "production"

    return GoogleSubscriptionState(
        purchase_token=purchase_token,
        product_id=product_id,
        expires_at=expires_at,
        auto_renew_enabled=auto_renew_enabled,
        is_in_grace_period=is_in_grace_period,
        is_in_trial=is_in_trial,
        app_account_token=app_account_token,
        environment=environment,
        revoked=revoked,
        linked_purchase_token=resp.get("linkedPurchaseToken"),
        latest_order_id=resp.get("latestOrderId"),
    )


# -----------------------------------------------------------------------------
# Public API — used by router and reconciler
# -----------------------------------------------------------------------------
def verify_purchase_token(
    package_name: str, product_id: str, purchase_token: str
) -> GoogleSubscriptionState:
    """Look up a freshly-purchased Google subscription.

    Identical to `fetch_subscription_state` — kept as a separate name so the
    call site reads naturally ("verify this thing the client just sent us"
    vs. "refresh what we already know about this token").
    """
    return fetch_subscription_state(package_name, purchase_token)


def fetch_subscription_state(
    package_name: str, purchase_token: str
) -> GoogleSubscriptionState:
    client = _get_play_client()
    resp = (
        client.purchases()
        .subscriptionsv2()
        .get(packageName=package_name, token=purchase_token)
        .execute()
    )
    return _parse_subscription_v2(resp, purchase_token)


def acknowledge_purchase(package_name: str, purchase_token: str) -> None:
    """Google requires us to acknowledge purchases within 3 days, otherwise
    they're auto-refunded. The client SHOULD acknowledge via the StoreKit/
    BillingClient API, but server-side is the safe net.
    """
    client = _get_play_client()
    try:
        client.purchases().subscriptions().acknowledge(
            packageName=package_name,
            subscriptionId="",  # ignored when token is set on v3 endpoint
            token=purchase_token,
            body={},
        ).execute()
    except Exception as e:
        # Already acknowledged → 400. Idempotent so we swallow.
        logger.info("acknowledge_purchase (likely already acked): %s", e)


# -----------------------------------------------------------------------------
# RTDN payload parsing
# -----------------------------------------------------------------------------
def parse_rtdn_envelope(envelope: dict) -> Optional[dict]:
    """Decode a Pub/Sub push envelope into the inner notification dict.

    Returns None for envelopes that don't carry a payload (test pings).
    The inner dict has shape:
        {
          "version": "1.0",
          "packageName": "...",
          "eventTimeMillis": "1700000000000",
          "subscriptionNotification": {...},     # OR
          "voidedPurchaseNotification": {...},   # OR
          "testNotification": {...}
        }
    """
    message = (envelope.get("message") or {})
    data_b64 = message.get("data")
    if not data_b64:
        return None
    try:
        decoded = base64.b64decode(data_b64).decode("utf-8")
        return json.loads(decoded)
    except Exception as e:
        logger.warning("Could not decode Google RTDN data: %s", e)
        return None


# RTDN subscriptionNotification.notificationType values we care about.
# (1) RECOVERED, (2) RENEWED, (3) CANCELED, (4) PURCHASED, (5) ON_HOLD,
# (6) IN_GRACE_PERIOD, (7) RESTARTED, (8) PRICE_CHANGE_CONFIRMED,
# (9) DEFERRED, (10) PAUSED, (11) PAUSE_SCHEDULE_CHANGED, (12) REVOKED,
# (13) EXPIRED. All of them trigger the same action — refetch from the API.
