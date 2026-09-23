"""Resident service requests, matched to providers by category (requirements
doc section 19). A booking starts unclaimed (open lead pool); the first
matching provider to accept it claims it."""
import uuid

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.deps import current_user
from models.user import User
from schemas.bookings import BookingActionIn, BookingIn, BookingOut
from services import bookings as service

router = APIRouter(prefix="/bookings", tags=["bookings"])


@router.post("", response_model=BookingOut, status_code=201)
async def create_booking(
    body: BookingIn,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    booking = await service.create_booking(db, user.id, body.category, body.title, body.note)
    return await service.serialize_one(db, booking)


@router.get("/mine", response_model=list[BookingOut])
async def list_mine(
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    bookings = await service.list_my_bookings(db, user.id)
    return await service.serialize_many(db, bookings)


@router.get("/leads", response_model=list[BookingOut])
async def list_leads(
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    bookings = await service.list_leads(db, user.id)
    return await service.serialize_many(db, bookings)


@router.patch("/{id}", response_model=BookingOut)
async def act_on_booking(
    id: uuid.UUID,
    body: BookingActionIn,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    booking = await service.act_on_booking(db, id, user.id, body.action)
    return await service.serialize_one(db, booking)
