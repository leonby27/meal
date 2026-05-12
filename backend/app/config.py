from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://user:password@localhost:5432/mealtracker"
    database_ssl: bool = True
    secret_key: str = "change-me-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 days

    google_client_id: str = ""

    timeweb_ai_agent_id: str = ""
    timeweb_ai_token: str = ""
    timeweb_ai_base_url: str = "https://agent.timeweb.cloud/api/v1/cloud-ai/agents"

    max_recognitions_per_day: int = 20

    # -------------------------------------------------------------------------
    # In-App Purchases — Apple
    # -------------------------------------------------------------------------
    # Bundle ID of the iOS app (must match the receipt's bundle id).
    apple_bundle_id: str = "by.mealtracker.mealTracker"
    # The app's numeric ID in App Store Connect (NOT the bundle id). Required
    # by the App Store Server library for the Production verifier — Apple
    # includes appAppleId in every notification and the lib cross-checks it.
    # Find it in App Store Connect → My Apps → <app> → App Information →
    # "Apple ID" field (10-digit number).
    apple_app_apple_id: int = 0
    # App Store Connect API key (used for App Store Server API requests).
    apple_issuer_id: str = ""
    apple_key_id: str = ""
    # ES256 private key, in PEM. Three ways to pass it, pick whatever
    # the env var editor handles best (never commit any of them):
    #   - `apple_private_key_pem` — multi-line PEM, including
    #     `-----BEGIN/END PRIVATE KEY-----` framing.
    #   - `apple_private_key_pem_b64` — single-line base64 of the full
    #     PEM. Use when the env editor strips newlines.
    #   - `apple_private_key_path` — path to a mounted .p8 file.
    apple_private_key_pem: str = ""
    apple_private_key_pem_b64: str = ""
    apple_private_key_path: str = ""
    # When true, all App Store calls go to the sandbox endpoint. Production
    # builds set this to false; TestFlight purchases still resolve as
    # `environment=Sandbox` in the verified payload so the server picks the
    # right endpoint automatically — this flag is only a forced override.
    apple_force_sandbox: bool = False
    # Promo codes that immediately grant lifetime access (matches the legacy
    # hard-coded list on the client). Comma-separated.
    promo_codes: str = "8259,2170"

    # -------------------------------------------------------------------------
    # In-App Purchases — Google Play (placeholder; wired in a later release)
    # -------------------------------------------------------------------------
    google_play_package_name: str = "by.mealtracker.calories"
    google_play_service_account_json: str = ""
    google_play_service_account_path: str = ""

    # Treat entitlements as still active for this many hours after the last
    # known `expires_at` to absorb webhook delays and brief outages. Apple's
    # own grace period is signaled by `is_in_grace_period` on the renewal
    # info; this is a small extra cushion on top.
    entitlement_grace_hours: int = 24

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()


def get_apple_private_key_pem() -> str:
    """Resolve the Apple ES256 private key from env or a mounted file.

    Three input shapes are accepted on every variable, in this order:
      - raw multi-line PEM (starts with `-----BEGIN`),
      - escaped-newline PEM (the editor turned `\\n` into the two
        literal characters `\\n` — we expand them back),
      - base64 of the PEM file (no `-----BEGIN`, decodes to a PEM).
    Lookup order:
      1. `apple_private_key_pem`     — first, with auto-detect above.
      2. `apple_private_key_pem_b64` — explicit base64.
      3. `apple_private_key_path`    — mounted secret file.
    """
    import base64

    def _normalize(blob: str) -> str:
        blob = blob.strip()
        if blob.startswith("-----BEGIN"):
            return blob
        if "\\n" in blob and "-----BEGIN" in blob.replace("\\n", "\n"):
            return blob.replace("\\n", "\n")
        # Last resort: maybe the editor collapsed everything and we got
        # base64. Try decode; if it yields a PEM, use it.
        try:
            decoded = base64.b64decode(blob, validate=False).decode("utf-8").strip()
            if decoded.startswith("-----BEGIN"):
                return decoded
        except Exception:
            pass
        return blob  # Let the caller fail loudly with a clear PEM error.

    if settings.apple_private_key_pem:
        return _normalize(settings.apple_private_key_pem)
    if settings.apple_private_key_pem_b64:
        return _normalize(settings.apple_private_key_pem_b64)
    if settings.apple_private_key_path:
        with open(settings.apple_private_key_path, "r", encoding="utf-8") as f:
            return f.read()
    return ""


def get_promo_codes() -> set[str]:
    return {code.strip() for code in settings.promo_codes.split(",") if code.strip()}
