from fastapi import APIRouter

from modules.admin import router as admin_router
from modules.bookings import router as bookings_router
from modules.community import router as communities_router
from modules.identity import auth_router, users_router
from modules.issues import router as issues_router
from modules.marketplace import router as marketplace_router
from modules.notifications import router as notifications_router
from modules.payments import router as payments_router

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
