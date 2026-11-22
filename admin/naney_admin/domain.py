"""Plain data types shared by services, adapters and pages."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from typing import Literal

LookupTable = Literal["cultures", "languages"]


class UserRole(StrEnum):
    ADMIN = "admin"
    UPLOADER = "uploader"


class RecordingStatus(StrEnum):
    PUBLISHED = "published"
    HIDDEN = "hidden"


class MediaType(StrEnum):
    AUDIO = "audio"
    VIDEO = "video"


@dataclass(frozen=True)
class LookupItem:
    id: int
    name_en: str
    name_fa: str
    active: bool


@dataclass(frozen=True)
class Uploader:
    id: str
    email: str
    display_name: str | None
    role: UserRole
    disabled: bool
    invited_at: datetime | None
    last_sign_in_at: datetime | None


@dataclass(frozen=True)
class RecordingSummary:
    id: str
    title: str
    kind: str
    status: RecordingStatus
    place_name: str
    uploader_email: str | None
    created_at: datetime


@dataclass(frozen=True)
class MediaRevision:
    recording_id: str
    revision_no: int
    media_type: MediaType
    object_key: str
    mime: str
    size_bytes: int
    note: str | None


@dataclass(frozen=True)
class Place:
    id: int
    name_en: str | None
    name_fa: str | None
    kind: str
    osm_ref: str | None
    recording_count: int
