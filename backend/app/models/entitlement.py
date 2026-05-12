import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Entitlement(Base):
    """Server-side source of truth for a user's premium access.

    One row per (store, original_transaction_id) — i.e. one Apple subscription
    or one Google subscription regardless of how many renewals it has had.
    Promo grants live here too with `store='promo'`.

    `user_id` is nullable so guest purchases work: the row is created against
    the device's `app_account_token` (a stable UUID we mint client-side and
    pass into the StoreKit/Play transaction), and later `POST /api/iap/link`
    binds it to the user once they sign in. Webhooks from Apple/Google always
    find the row via either `user_id` or `app_account_token`.
    """

    __tablename__ = "entitlements"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    app_account_token: Mapped[str] = mapped_column(String(64), index=True)

    store: Mapped[str] = mapped_column(String(16))  # 'apple' | 'google' | 'promo'
    product_id: Mapped[str] = mapped_column(String(128))
    plan: Mapped[str] = mapped_column(String(32))  # 'weekly' | 'yearly' | 'promo_lifetime'

    # Apple: originalTransactionId. Google: purchaseToken. Promo: code.
    original_transaction_id: Mapped[str] = mapped_column(String(255))
    latest_transaction_id: Mapped[Optional[str]] = mapped_column(
        String(255), nullable=True
    )

    # Whole-day precision is enough for entitlement gating; we store DateTime
    # because Apple gives ms-precision and we keep it as-is for cron filters.
    expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    is_in_trial: Mapped[bool] = mapped_column(Boolean, default=False)
    is_in_grace_period: Mapped[bool] = mapped_column(Boolean, default=False)
    auto_renew_enabled: Mapped[bool] = mapped_column(Boolean, default=False)

    # 'sandbox' for TestFlight and StoreKit testing, 'production' for the App
    # Store. Stored so we never grant sandbox access in prod by accident.
    environment: Mapped[str] = mapped_column(String(16), default="production")

    revoked_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )
    last_event_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    __table_args__ = (
        UniqueConstraint(
            "store", "original_transaction_id",
            name="uq_entitlements_store_original_tx",
        ),
        Index("ix_entitlements_expires_at", "expires_at"),
    )
