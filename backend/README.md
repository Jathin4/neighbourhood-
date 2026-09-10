# TNN Backend

FastAPI + SQLAlchemy (async). All data lives in a single SQLite file at
`../db/tnn.db` per project requirement — swap `DATABASE_URL` to
`postgresql+asyncpg://…` later and nothing else changes.

## Run

```bash
cd backend
python -m venv .venv
.venv\Scripts\pip install -r requirements-dev.txt      # PowerShell / cmd
# source .venv/bin/activate && pip install -r requirements-dev.txt   # bash

copy .env.example .env            # optional; sane defaults already apply

.venv\Scripts\python -m alembic upgrade head           # create/upgrade schema
.venv\Scripts\python -m app.cli seed-superadmin +919999999999   # first admin
.venv\Scripts\uvicorn app.main:app --reload             # http://localhost:8000
```

Docs at `http://localhost:8000/docs`. In `ENV=dev` the schema is also
auto-created on startup, so `alembic upgrade` is only strictly needed for
non-dev.

## Test

```bash
.venv\Scripts\python -m pytest        # 14 tests, in-memory SQLite
.venv\Scripts\python -m ruff check .
```

## What's implemented (Phase 0–1)

| Area | Endpoints |
|---|---|
| Auth | `POST /api/v1/auth/otp/request` · `otp/verify` · `refresh` · `logout` |
| Users | `GET/PATCH /api/v1/users/me` |
| Communities | `POST/GET /api/v1/communities` · `GET/PATCH /communities/{id}` |
| Units | `GET/POST /api/v1/communities/{id}/units` |
| Membership | `POST/GET /communities/{id}/members` · `PATCH /members/{mid}` · `POST /members/import` (CSV) |

- **OTP**: 6-digit, hashed at rest, 5-min TTL, 5 attempts, 5/hour rate limit.
  Dev returns the code as `debug_code` (`OTP_DEBUG=true`); production swaps
  `ConsoleSmsSender` for a real adapter in `modules/identity/otp_adapter.py`.
- **Tokens**: 15-min JWT access, opaque refresh with rotation + reuse
  detection (a reused refresh token revokes the whole chain).
- **RBAC** (`app/rbac.py`): capability-based. Platform roles
  (`super_admin`, `platform_ops`) + per-community membership roles
  (`community_admin`, `committee_member`, `resident`); committee members
  carry extra per-membership capabilities. Enforced server-side on every
  protected route via `deps.require(cap)`.
- **Tenant isolation**: community-scoped routes resolve the caller's *active*
  membership for the `{community_id}` in the path; cross-community access is
  refused.
- **Audit**: sensitive admin actions append to `audit_logs` with the
  request `correlation_id`.
- **Errors**: single envelope `{error:{code,message,details,correlation_id}}`,
  `X-Correlation-ID` on every response.

`openapi.json` is committed and regenerated with
`python scripts/dump_openapi.py`.

## Not yet built

Module folders `issues`, `marketplace`, `bookings`, `payments`,
`notifications`, `admin` are mounted but empty — each is a later phase
(requirements §19). Redis/Celery/S3 deferred until a feature needs them.
