"""In-memory stand-ins for Supabase and R2 so services are tested without the network."""

from __future__ import annotations

from dataclasses import replace
from datetime import UTC, datetime

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

NOW = datetime(2026, 11, 22, 12, 0, tzinfo=UTC)


class FakeLookupRepo:
    def __init__(self) -> None:
        self.items: dict[LookupTable, dict[int, LookupItem]] = {"cultures": {}, "languages": {}}
        self._next_id = 1

    def list_items(self, table: LookupTable) -> list[LookupItem]:
        return sorted(self.items[table].values(), key=lambda item: item.name_en.lower())

    def insert_item(self, table: LookupTable, name_en: str, name_fa: str) -> LookupItem:
        item = LookupItem(id=self._next_id, name_en=name_en, name_fa=name_fa, active=True)
        self.items[table][item.id] = item
        self._next_id += 1
        return item

    def update_item(
        self,
        table: LookupTable,
        item_id: int,
        *,
        name_en: str | None = None,
        name_fa: str | None = None,
        active: bool | None = None,
    ) -> None:
        item = self.items[table][item_id]
        self.items[table][item_id] = replace(
            item,
            name_en=name_en if name_en is not None else item.name_en,
            name_fa=name_fa if name_fa is not None else item.name_fa,
            active=active if active is not None else item.active,
        )


class FakeUserRepo:
    def __init__(self) -> None:
        self.users: dict[str, Uploader] = {}
        self.invited: list[str] = []
        self.passwords: dict[str, str] = {}

    def list_uploaders(self) -> list[Uploader]:
        return sorted(self.users.values(), key=lambda user: user.email)

    def invite(self, email: str, redirect_to: str) -> str:
        user_id = f"user-{len(self.users) + 1}"
        self.invited.append(f"{email}->{redirect_to}")
        self.users[user_id] = Uploader(
            id=user_id,
            email=email,
            display_name=None,
            role=UserRole.UPLOADER,
            disabled=False,
            invited_at=NOW,
            last_sign_in_at=None,
        )
        return user_id

    def set_password(self, user_id: str, password: str) -> None:
        if user_id not in self.users:
            raise KeyError(user_id)
        self.passwords[user_id] = password

    def update_profile(
        self,
        user_id: str,
        *,
        role: UserRole | None = None,
        disabled: bool | None = None,
        display_name: str | None = None,
    ) -> None:
        user = self.users[user_id]
        self.users[user_id] = replace(
            user,
            role=role if role is not None else user.role,
            disabled=disabled if disabled is not None else user.disabled,
            display_name=display_name if display_name is not None else user.display_name,
        )


class FakeRecordingRepo:
    def __init__(self) -> None:
        self.recordings: dict[str, RecordingSummary] = {}
        self.media: dict[str, list[MediaRevision]] = {}
        self.fail_next_insert = False

    def add_recording(self, recording: RecordingSummary, original: MediaRevision) -> None:
        self.recordings[recording.id] = recording
        self.media[recording.id] = [original]

    def search(self, text: str, status: RecordingStatus | None) -> list[RecordingSummary]:
        needle = text.lower()
        return [
            recording
            for recording in self.recordings.values()
            if needle in recording.title.lower() and (status is None or recording.status == status)
        ]

    def set_status(self, recording_id: str, status: RecordingStatus) -> None:
        self.recordings[recording_id] = replace(self.recordings[recording_id], status=status)

    def list_media(self, recording_id: str) -> list[MediaRevision]:
        return sorted(self.media.get(recording_id, []), key=lambda media: media.revision_no)

    def insert_media(self, revision: MediaRevision) -> None:
        if self.fail_next_insert:
            self.fail_next_insert = False
            raise RuntimeError("database unavailable")
        existing = self.media.setdefault(revision.recording_id, [])
        if any(media.revision_no == revision.revision_no for media in existing):
            raise RuntimeError("duplicate revision")
        existing.append(revision)


class FakePlaceRepo:
    def __init__(self) -> None:
        self.places: dict[int, Place] = {}

    def list_places(self) -> list[Place]:
        return sorted(self.places.values(), key=lambda place: place.id)

    def rename(self, place_id: int, name_en: str | None, name_fa: str | None) -> None:
        self.places[place_id] = replace(self.places[place_id], name_en=name_en, name_fa=name_fa)


class FakeMediaStore:
    def __init__(self) -> None:
        self.objects: dict[str, tuple[bytes, str]] = {}

    def put(self, key: str, data: bytes, content_type: str) -> None:
        self.objects[key] = (data, content_type)

    def delete(self, key: str) -> None:
        self.objects.pop(key, None)
