# Trusted Neighbourhood Network

Neighbourhood community + trusted local-services platform. See
`Trusted_Neighbourhood_Network_Detailed_Developer_Requirements` for the full
spec; this repo is the Phase 0–1 baseline.

```
backend/   FastAPI + async SQLAlchemy. Auth (OTP), RBAC, community / user /
           household / units, CSV resident import, audit log.
app/       Flutter (web + mobile). Auth flow + home dashboard shell.
db/        SQLite database file (tnn.db) — all application data lives here.
```

## Quick start

```bash
# 1. Backend
cd backend
python -m venv .venv && .venv\Scripts\pip install -r requirements-dev.txt
.venv\Scripts\python -m alembic upgrade head
.venv\Scripts\python -m app.cli seed-superadmin +919999999999
.venv\Scripts\uvicorn app.main:app --reload            # :8000, docs at /docs

# 2. App  (needs the Flutter SDK installed)
cd ../app
flutter create . --project-name tnn_app --org com.tnn --platforms=web,android,ios
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Per-component detail: `backend/README.md`, `app/README.md`.

## Status

| | Done | Deferred |
|---|---|---|
| **Backend** | OTP auth + JWT refresh/rotation, capability RBAC, communities/units/memberships, CSV import, audit, error envelope, 14 tests, Alembic, committed `openapi.json` | issues, marketplace, bookings, payments, notifications, admin (mounted, empty); Redis/Celery/S3; Postgres (SQLite for now) |
| **App** | login → OTP → dashboard shell, profile, community list, 401 auto-refresh | everything past the shell; not yet compiled (no SDK on this machine) |
