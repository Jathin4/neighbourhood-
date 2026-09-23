import pytest

from services.identity_otp_adapter import ConsoleSmsSender, Fast2SmsSender, get_sms_sender

pytestmark = pytest.mark.asyncio


async def test_console_sender_never_raises(caplog):
    await ConsoleSmsSender().send_otp("+919000000000", "123456")


def test_no_api_key_falls_back_to_console(monkeypatch):
    from services import identity_otp_adapter as otp_adapter

    monkeypatch.setattr(otp_adapter.settings, "fast2sms_api_key", None)
    assert isinstance(get_sms_sender(), ConsoleSmsSender)


def test_api_key_selects_fast2sms(monkeypatch):
    from services import identity_otp_adapter as otp_adapter

    monkeypatch.setattr(otp_adapter.settings, "fast2sms_api_key", "dummy-key")
    assert isinstance(get_sms_sender(), Fast2SmsSender)


async def test_fast2sms_raises_when_gateway_rejects(monkeypatch):
    import httpx

    class FakeResponse:
        def raise_for_status(self):
            pass

        def json(self):
            return {"return": False, "message": "bad number"}

    class FakeClient:
        async def __aenter__(self):
            return self

        async def __aexit__(self, *a):
            return False

        async def get(self, *a, **kw):
            return FakeResponse()

    monkeypatch.setattr(httpx, "AsyncClient", lambda **kw: FakeClient())

    with pytest.raises(RuntimeError):
        await Fast2SmsSender("dummy-key").send_otp("+919812345678", "123456")
