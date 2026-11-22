"""Boundaries to Supabase and R2; services depend on these, not on SDKs."""

from __future__ import annotations

from typing import Protocol

from naney_admin.domain import (
    LookupItem,
    LookupTable,
    MediaRevision,
    Place,
    RecordingStatus,
    RecordingSummary,
    Uploader,
    UserRole,
)


class LookupRepo(Protocol):
    def list_items(self, table: LookupTable) -> list[LookupItem]: ...

    def insert_item(self, table: LookupTable, name_en: str, name_fa: str) -> LookupItem: ...

    def update_item(
        self,
        table: LookupTable,
        item_id: int,
        *,
        name_en: str | None = None,
        name_fa: str | None = None,
        active: bool | None = None,
    ) -> None: ...


class UserRepo(Protocol):
    def list_uploaders(self) -> list[Uploader]: ...

    def invite(self, email: str, redirect_to: str) -> str: ...

    def set_password(self, user_id: str, password: str) -> None: ...

    def update_profile(
        self,
        user_id: str,
        *,
        role: UserRole | None = None,
        disabled: bool | None = None,
        display_name: str | None = None,
    ) -> None: ...


class RecordingRepo(Protocol):
    def search(self, text: str, status: RecordingStatus | None) -> list[RecordingSummary]: ...

    def set_status(self, recording_id: str, status: RecordingStatus) -> None: ...

    def list_media(self, recording_id: str) -> list[MediaRevision]: ...

    def insert_media(self, revision: MediaRevision) -> None: ...


class PlaceRepo(Protocol):
    def list_places(self) -> list[Place]: ...

    def rename(self, place_id: int, name_en: str | None, name_fa: str | None) -> None: ...


class MediaStore(Protocol):
    def put(self, key: str, data: bytes, content_type: str) -> None: ...

    def delete(self, key: str) -> None: ...
