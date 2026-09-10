from fastapi import APIRouter

from app.modules.admin.router import router as admin_router
from app.modules.bookings.router import router as bookings_router
from app.modules.community.router import router as communities_router
from app.modules.identity.router import auth_router, users_router
from app.modules.issues.router import router as issues_router
from app.modules.marketplace.router import router as marketplace_router
from app.modules.notifications.router import router as notifications_router
from app.modules.payments.router import router as payments_router

api_v1 = APIRouter(prefix="/api/v1")

for r in (
    auth_router,
    users_router,
    communities_router,
    issues_router,
    marketplace_router,
    bookings_router,
    payments_router,
    notifications_router,
    admin_router,
):
    api_v1.include_router(r)
