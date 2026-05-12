"""App Store Server API + JWS verification, using Apple's official library.

We support two flavors of receipt data delivered by the iOS client:

* StoreKit 2 signed JWS — a single signed transaction. Verified locally
  via cert chain + signature, no Apple round trip needed. Preferred.
* Legacy StoreKit 1 base64 receipt — opaque blob. We parse it to extract
  the `originalTransactionId`, then fetch the canonical transaction via
  App Store Server API.

Either way we end up with a verified `JWSTransactionDecodedPayload` from
which we read product id, expiry, environment, app account token.

Subscription lifecycle (renewals, expirations, refunds, cancellations) is
driven by App Store Server Notifications V2 on a separate webhook — see
`routers/iap.py`. This module also provides `get_subscription_statuses`
for the hourly reconciliation job.
"""
from __future__ import annotations

import base64
import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from threading import Lock
from typing import Optional

import httpx
from appstoreserverlibrary.api_client import AppStoreServerAPIClient, APIException
from appstoreserverlibrary.models.Environment import Environment
from appstoreserverlibrary.models.JWSTransactionDecodedPayload import (
    JWSTransactionDecodedPayload,
)
from appstoreserverlibrary.models.ResponseBodyV2DecodedPayload import (
    ResponseBodyV2DecodedPayload,
)
from appstoreserverlibrary.receipt_utility import ReceiptUtility
from appstoreserverlibrary.signed_data_verifier import (
    SignedDataVerifier,
    VerificationException,
)

from app.config import get_apple_private_key_pem, settings

logger = logging.getLogger(__name__)


# -----------------------------------------------------------------------------
# Apple root certificates — needed to verify JWS cert chains. Downloaded once
# per process at first use. App Store Server Notifications V2 sign against
# G3; the others give us backward compatibility for older transactions.
# We tolerate per-URL failures — if even one loads, the verifier still works
# for the matching cert chain, and the others would only matter for ancient
# transactions that aren't realistic in this app.
# -----------------------------------------------------------------------------
_APPLE_ROOT_CERT_URLS = [
    "https://www.apple.com/certificateauthority/AppleRootCA-G3.cer",
    "https://www.apple.com/certificateauthority/AppleRootCA-G2.cer",
    "https://www.apple.com/appleca/AppleIncRootCertificate.cer",
]
_apple_root_certs: Optional[list[bytes]] = None
_root_lock = Lock()


def _load_apple_root_certs() -> list[bytes]:
    global _apple_root_certs
    with _root_lock:
        if _apple_root_certs is not None:
            return _apple_root_certs
        certs: list[bytes] = []
        with httpx.Client(timeout=10) as client:
            for url in _APPLE_ROOT_CERT_URLS:
                try:
                    resp = client.get(url)
                    resp.raise_for_status()
                    certs.append(resp.content)
                except Exception as e:
                    logger.warning("Could not fetch Apple root %s: %s", url, e)
        if not certs:
            raise RuntimeError(
                "Could not download any Apple root certificates; "
                "App Store JWS verification cannot proceed"
            )
        _apple_root_certs = certs
        logger.info(
            "Loaded %d/%d Apple root certificates",
            len(certs), len(_APPLE_ROOT_CERT_URLS),
        )
        return certs


# -----------------------------------------------------------------------------
# Lazy singletons for the verifier + API client, per environment.
# -----------------------------------------------------------------------------
@dataclass
class _AppleClients:
    verifier: SignedDataVerifier
    api: AppStoreServerAPIClient


_clients_by_env: dict[Environment, _AppleClients] = {}
_clients_lock = Lock()


def _get_clients(environment: Environment) -> _AppleClients:
    with _clients_lock:
        cached = _clients_by_env.get(environment)
        if cached is not None:
            return cached

        if not settings.apple_issuer_id or not settings.apple_key_id:
            raise RuntimeError("Apple IAP credentials are not configured")
        pem = get_apple_private_key_pem()
        if not pem:
            raise RuntimeError("Apple private key is not configured")

        root_certs = _load_apple_root_certs()
        # The library refuses to build a Production verifier without an
        # explicit app_apple_id (it cross-checks against the notification
        # payload). Sandbox doesn't enforce this; if we haven't been given
        # an ID yet we still allow sandbox-only operation so TestFlight
        # works without the user having to fill in App Store Connect first.
        verifier_kwargs = {
            "root_certificates": root_certs,
            "enable_online_checks": False,
            "environment": environment,
            "bundle_id": settings.apple_bundle_id,
        }
        if settings.apple_app_apple_id:
            verifier_kwargs["app_apple_id"] = settings.apple_app_apple_id
        elif environment == Environment.PRODUCTION:
            raise RuntimeError(
                "APPLE_APP_APPLE_ID env var is required for production "
                "App Store verification (find it in App Store Connect → "
                "App Information → Apple ID, a 10-digit number)"
            )
        verifier = SignedDataVerifier(**verifier_kwargs)
        api = AppStoreServerAPIClient(
            signing_key=pem.encode("utf-8"),
            key_id=settings.apple_key_id,
            issuer_id=settings.apple_issuer_id,
            bundle_id=settings.apple_bundle_id,
            environment=environment,
        )
        _clients_by_env[environment] = _AppleClients(verifier=verifier, api=api)
        return _clients_by_env[environment]


# -----------------------------------------------------------------------------
# Public helpers
# -----------------------------------------------------------------------------
def _is_jws(blob: str) -> bool:
    """A signed JWS is `header.payload.signature`, three short base64 parts."""
    if blob.count(".") != 2:
        return False
    # Receipts are typically >>1000 chars of base64 with no dots.
    return all(len(part) > 0 and "/" not in part for part in blob.split("."))


def verify_signed_transaction(
    server_verification_data: str,
    environment_hint: Optional[str] = None,
) -> tuple[JWSTransactionDecodedPayload, Environment]:
    """Verify a client-supplied transaction blob and return its decoded form.

    Handles both StoreKit 2 (signed JWS) and StoreKit 1 (legacy receipt).
    `environment_hint` is the environment the *client* thinks it's in — used
    to choose which environment to try first. We fall back to the other on
    failure because Apple uses the same root certs in both envs.
    """
    first, second = _env_order(environment_hint)

    if _is_jws(server_verification_data):
        return _verify_jws(server_verification_data, first, second)
    return _resolve_receipt(server_verification_data, first, second)


def _env_order(hint: Optional[str]) -> tuple[Environment, Environment]:
    if settings.apple_force_sandbox:
        return Environment.SANDBOX, Environment.PRODUCTION
    if hint and hint.lower() == "sandbox":
        return Environment.SANDBOX, Environment.PRODUCTION
    return Environment.PRODUCTION, Environment.SANDBOX


def _verify_jws(
    jws: str, first: Environment, second: Environment
) -> tuple[JWSTransactionDecodedPayload, Environment]:
    """The library raises VerificationException for signed-data issues but
    other failure modes (malformed JWS base64, missing header fields)
    surface as binascii / KeyError / TypeError. From a caller's perspective
    they all mean "this blob is unusable" — we treat them as one bucket and
    let the caller return 400."""
    last_err: Optional[Exception] = None
    for env in (first, second):
        try:
            clients = _get_clients(env)
            payload = clients.verifier.verify_and_decode_signed_transaction(jws)
            return payload, env
        except VerificationException as e:
            last_err = e
        except Exception as e:
            last_err = e
    raise ValueError(f"Failed to verify signed transaction: {last_err}")


def _resolve_receipt(
    receipt_b64: str, first: Environment, second: Environment
) -> tuple[JWSTransactionDecodedPayload, Environment]:
    """Legacy StoreKit 1 receipt: parse out transaction id, fetch via API."""
    try:
        # Validate it really is base64 — guards against random strings.
        base64.b64decode(receipt_b64, validate=True)
    except Exception as e:
        raise ValueError(f"server_verification_data is not a valid JWS or receipt: {e}")

    utility = ReceiptUtility()
    transaction_id = utility.extract_transaction_id_from_app_receipt(receipt_b64)
    if not transaction_id:
        raise ValueError("Could not extract transactionId from receipt")
    return lookup_transaction(transaction_id, first, second)


def lookup_transaction(
    transaction_id: str,
    first: Environment = Environment.PRODUCTION,
    second: Environment = Environment.SANDBOX,
) -> tuple[JWSTransactionDecodedPayload, Environment]:
    """Fetch a single transaction by id, trying prod then sandbox."""
    last_err: Optional[Exception] = None
    for env in (first, second):
        try:
            clients = _get_clients(env)
            response = clients.api.get_transaction_info(transaction_id)
            signed = response.signedTransactionInfo
            if not signed:
                raise ValueError("Empty signedTransactionInfo from Apple")
            payload = clients.verifier.verify_and_decode_signed_transaction(signed)
            return payload, env
        except (APIException, VerificationException) as e:
            last_err = e
        except Exception as e:
            last_err = e
    raise ValueError(f"Could not look up transaction {transaction_id}: {last_err}")


def decode_signed_transaction(signed: str, environment: Environment) -> JWSTransactionDecodedPayload:
    """Decode a JWS we already trust the environment of (e.g. from a verified notification)."""
    return _get_clients(environment).verifier.verify_and_decode_signed_transaction(signed)


def decode_signed_renewal_info(signed: str, environment: Environment):
    """Decode a renewal-info JWS we already trust the environment of."""
    return _get_clients(environment).verifier.verify_and_decode_signed_renewal_info(signed)


def get_subscription_statuses(original_transaction_id: str, environment: Environment):
    """All statuses for a subscription group — used by the hourly reconciler."""
    clients = _get_clients(environment)
    response = clients.api.get_all_subscription_statuses(original_transaction_id)
    # The response contains lastTransactions[] of signed payloads; we let the
    # caller decide which one is newest.
    return response


def verify_notification(signed_payload: str) -> tuple[ResponseBodyV2DecodedPayload, Environment]:
    """Verify an App Store Server Notifications V2 webhook payload."""
    last_err: Optional[Exception] = None
    for env in (Environment.PRODUCTION, Environment.SANDBOX):
        try:
            clients = _get_clients(env)
            payload = clients.verifier.verify_and_decode_notification(signed_payload)
            # Apple stamps the notification with its environment; cross-check
            # against the verifier we picked so a sandbox event verified by
            # the prod verifier (theoretically impossible — same root certs
            # but different chains — but be defensive) is rejected here.
            payload_env = (payload.data.environment if payload.data else None) or (
                payload.summary.environment if payload.summary else None
            )
            if payload_env is not None and payload_env != env:
                continue
            return payload, env
        except VerificationException as e:
            last_err = e
        except Exception as e:
            # Same rationale as in _verify_jws: a malformed payload can
            # raise any number of underlying errors; bucket them all as
            # "unusable input" so the caller can return a clean 400.
            last_err = e
    raise ValueError(f"Could not verify notification: {last_err}")


# -----------------------------------------------------------------------------
# Convenience helpers for callers that need to read fields off the payload.
# -----------------------------------------------------------------------------
def transaction_to_dict(payload: JWSTransactionDecodedPayload, environment: Environment) -> dict:
    """Flatten the fields the entitlement upsert needs."""
    return {
        "original_transaction_id": payload.originalTransactionId,
        "transaction_id": payload.transactionId,
        "product_id": payload.productId,
        "app_account_token": str(payload.appAccountToken) if payload.appAccountToken else None,
        "expires_at": _ms_to_dt(payload.expiresDate),
        "purchase_date": _ms_to_dt(payload.purchaseDate),
        "is_in_trial": _is_in_trial(payload),
        "revocation_date": _ms_to_dt(payload.revocationDate),
        "environment": environment.value.lower(),
    }


def _ms_to_dt(ms: Optional[int]) -> Optional[datetime]:
    if ms is None:
        return None
    return datetime.fromtimestamp(ms / 1000, tz=timezone.utc).replace(tzinfo=None)


def _is_in_trial(payload: JWSTransactionDecodedPayload) -> bool:
    from appstoreserverlibrary.models.OfferType import OfferType
    return payload.offerType == OfferType.INTRODUCTORY_OFFER
