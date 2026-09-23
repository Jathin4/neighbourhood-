"""Placeholder for the notifications domain. Endpoints land in the phase that owns it
(requirements doc section 19). The router is mounted now so the module
boundary and URL namespace are fixed from the start."""
from fastapi import APIRouter

router = APIRouter(prefix="/notifications", tags=["notifications"])
