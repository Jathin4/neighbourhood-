import logging
import uuid
from contextvars import ContextVar

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

log = logging.getLogger("tnn")

correlation_id: ContextVar[str] = ContextVar("correlation_id", default="-")


class AppError(Exception):
    """Domain error rendered through the standard envelope."""

    def __init__(self, code: str, message: str, http_status: int = 400, details=None):
        self.code = code
        self.message = message
        self.http_status = http_status
        self.details = details or []
        super().__init__(message)


def not_found(entity: str) -> AppError:
    return AppError("not_found", f"{entity} not found", status.HTTP_404_NOT_FOUND)


def forbidden(message: str = "Not authorized") -> AppError:
    return AppError("forbidden", message, status.HTTP_403_FORBIDDEN)


def _envelope(code: str, message: str, details, http_status: int) -> JSONResponse:
    return JSONResponse(
        status_code=http_status,
        content={
            "error": {
                "code": code,
                "message": message,
                "details": details,
                "correlation_id": correlation_id.get(),
            }
        },
        headers={"X-Correlation-ID": correlation_id.get()},
    )


def install(app: FastAPI) -> None:
    @app.middleware("http")
    async def _correlation(request: Request, call_next):
        cid = request.headers.get("X-Correlation-ID") or uuid.uuid4().hex
        correlation_id.set(cid)
        request.state.correlation_id = cid
        try:
            response = await call_next(request)
        except Exception:
            log.exception("unhandled error cid=%s path=%s", cid, request.url.path)
            return _envelope("internal_error", "Internal server error", [], 500)
        response.headers["X-Correlation-ID"] = cid
        return response

    @app.exception_handler(AppError)
    async def _app_error(_: Request, exc: AppError):
        return _envelope(exc.code, exc.message, exc.details, exc.http_status)

    @app.exception_handler(RequestValidationError)
    async def _validation(_: Request, exc: RequestValidationError):
        details = [{"loc": e["loc"], "msg": e["msg"]} for e in exc.errors()]
        return _envelope("validation_error", "Request validation failed", details, 422)

    @app.exception_handler(StarletteHTTPException)
    async def _http(_: Request, exc: StarletteHTTPException):
        return _envelope("http_error", str(exc.detail), [], exc.status_code)
