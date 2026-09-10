"""OTP delivery behind a swappable adapter (§8: vendors must be replaceable)."""
import logging
from typing import Protocol

log = logging.getLogger("tnn.otp")


class SmsSender(Protocol):
    async def send_otp(self, mobile: str, code: str) -> None: ...


class ConsoleSmsSender:
    """Dev sender: writes the code to the log instead of sending an SMS."""

    async def send_otp(self, mobile: str, code: str) -> None:
        log.info("OTP for %s: %s", mobile, code)


def get_sms_sender() -> SmsSender:
    # Swap here for a real provider adapter (Twilio / MSG91 / Gupshup ...).
    return ConsoleSmsSender()
