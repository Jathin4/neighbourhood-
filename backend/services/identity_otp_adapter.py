"""OTP delivery behind a swappable adapter (§8: vendors must be replaceable)."""
import logging
from typing import Protocol

import httpx

from app.config import get_settings

log = logging.getLogger("tnn.otp")
settings = get_settings()


class SmsSender(Protocol):
    async def send_otp(self, mobile: str, code: str) -> None: ...


class ConsoleSmsSender:
    """Dev sender: writes the code to the log instead of sending an SMS."""

    async def send_otp(self, mobile: str, code: str) -> None:
        log.info("OTP for %s: %s", mobile, code)


class Fast2SmsSender:
    """Fast2SMS 'otp' route: fixed template, no DLT template registration needed.
    https://www.fast2sms.com/otp-sms/
    """

    def __init__(self, api_key: str):
        self._api_key = api_key

    async def send_otp(self, mobile: str, code: str) -> None:
        number = mobile[-10:]  # route expects a bare 10-digit Indian number, no country code
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(
                "https://www.fast2sms.com/dev/bulkV2",
                params={
                    "authorization": self._api_key,
                    "variables_values": code,
                    "route": "otp",
                    "numbers": number,
                },
            )
        resp.raise_for_status()
        data = resp.json()
        if not data.get("return"):
            raise RuntimeError(f"Fast2SMS did not accept the OTP: {data}")


def get_sms_sender() -> SmsSender:
    if settings.fast2sms_api_key:
        return Fast2SmsSender(settings.fast2sms_api_key)
    return ConsoleSmsSender()
