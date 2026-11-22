"""Supabase (service role) implementation of the admin repositories.

The secret key bypasses row-level security, which is why this panel only ever runs locally.
"""

from __future__ import annotations

import re
from datetime import datetime
from typing import Any

from supabase import Client

from naney_admin.domain import (
    LookupItem,
    LookupTable,
    MediaRevision,
    MediaType,
    Place,
    RecordingStatus,
    RecordingSummary,
    Uploader,
    UserRole,
)

_USERS_PAGE_SIZE = 200
_SEARCH_LIMIT = 200
# PostgREST filter syntax characters; stripped so search text cannot alter the query.
_UNSAFE_SEARCH = re.compile(r"[%_*,()\\.:]")

Row = dict[str, Any]


def _parse_time(value: object) -> datetime | None:
    if isinstance(value, datetime):
        return value
    if isinstance(value, str) and value:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    return None


def _rows(response: object) -> list[Row]:
    data = getattr(response, "data", None)
    return list(data) if isinstance(data, list) else []


class SupabaseRepository:
    def __init__(self, client: Client) -> None:
        self._client = client

    # ------------------------------------------------------------ cultures & languages
    def list_items(self, table: LookupTable) -> list[LookupItem]:
        response = (
            self._client.table(table).select("id,name_en,name_fa,active").order("name_en").execute()
        )
        return [LookupItem(**row) for row in _rows(response)]

    def insert_item(self, table: LookupTable, name_en: str, name_fa: str) -> LookupItem:
        response = (
            self._client.table(table).insert({"name_en": name_en, "name_fa": name_fa}).execute()
        )
        row = _rows(response)[0]
        return LookupItem(
            id=row["id"], name_en=row["name_en"], name_fa=row["name_fa"], active=row["active"]
        )

    def update_item(
        self,
        table: LookupTable,
        item_id: int,
        *,
        name_en: str | None = None,
        name_fa: str | None = None,
        active: bool | None = None,
    ) -> None:
        changes: Row = {}
        if name_en is not None:
            changes["name_en"] = name_en
        if name_fa is not None:
            changes["name_fa"] = name_fa
        if active is not None:
            changes["active"] = active
        if changes:
            self._client.table(table).update(changes).eq("id", item_id).execute()

    # ------------------------------------------------------------ users
    def _auth_users(self) -> list[Any]:
        users: list[Any] = []
        page = 1
        while True:
            batch = self._client.auth.admin.list_users(page=page, per_page=_USERS_PAGE_SIZE)
            users.extend(batch)
            if len(batch) < _USERS_PAGE_SIZE:
                return users
            page += 1

    def _emails_by_id(self) -> dict[str, str]:
        return {str(user.id): str(user.email or "") for user in self._auth_users()}

    def list_uploaders(self) -> list[Uploader]:
        profiles = {
            str(row["id"]): row
            for row in _rows(self._client.table("profiles").select("*").execute())
        }
        uploaders = []
        for user in self._auth_users():
            profile = profiles.get(str(user.id))
            if profile is None:
                continue
            uploaders.append(
                Uploader(
                    id=str(user.id),
                    email=str(user.email or ""),
                    display_name=profile.get("display_name"),
                    role=UserRole(profile["role"]),
                    disabled=bool(profile["disabled"]),
                    invited_at=_parse_time(getattr(user, "invited_at", None)),
                    last_sign_in_at=_parse_time(getattr(user, "last_sign_in_at", None)),
                )
            )
        return sorted(uploaders, key=lambda uploader: uploader.email)

    def invite(self, email: str, redirect_to: str) -> str:
        response = self._client.auth.admin.invite_user_by_email(email, {"redirect_to": redirect_to})
        if response.user is None:
            raise RuntimeError("Supabase did not return the invited user.")
        return str(response.user.id)

    def set_password(self, user_id: str, password: str) -> None:
        self._client.auth.admin.update_user_by_id(user_id, {"password": password})

    def update_profile(
        self,
        user_id: str,
        *,
        role: UserRole | None = None,
        disabled: bool | None = None,
        display_name: str | None = None,
    ) -> None:
        changes: Row = {}
        if role is not None:
            changes["role"] = role.value
        if disabled is not None:
            changes["disabled"] = disabled
        if display_name is not None:
            changes["display_name"] = display_name
        if changes:
            self._client.table("profiles").update(changes).eq("id", user_id).execute()

    # ------------------------------------------------------------ recordings & media
    def search(self, text: str, status: RecordingStatus | None) -> list[RecordingSummary]:
        query = self._client.table("recordings").select(
            "id,title,kind,status,created_at,created_by,places(name_en,name_fa)"
        )
        safe_text = _UNSAFE_SEARCH.sub(" ", text).strip()
        if safe_text:
            query = query.ilike("title", f"%{safe_text}%")
        if status is not None:
            query = query.eq("status", status.value)
        rows = _rows(query.order("created_at", desc=True).limit(_SEARCH_LIMIT).execute())
        emails = self._emails_by_id() if rows else {}
        return [
            RecordingSummary(
                id=str(row["id"]),
                title=row["title"],
                kind=row["kind"],
                status=RecordingStatus(row["status"]),
                place_name=(row.get("places") or {}).get("name_en")
                or (row.get("places") or {}).get("name_fa")
                or "",
                uploader_email=emails.get(str(row["created_by"])),
                created_at=_parse_time(row["created_at"]) or datetime.min,
            )
            for row in rows
        ]

    def set_status(self, recording_id: str, status: RecordingStatus) -> None:
        self._client.table("recordings").update({"status": status.value}).eq(
            "id", recording_id
        ).execute()

    def list_media(self, recording_id: str) -> list[MediaRevision]:
        response = (
            self._client.table("recording_media")
            .select("recording_id,revision_no,media_type,object_key,mime,size_bytes,note")
            .eq("recording_id", recording_id)
            .order("revision_no")
            .execute()
        )
        return [
            MediaRevision(
                recording_id=str(row["recording_id"]),
                revision_no=int(row["revision_no"]),
                media_type=MediaType(row["media_type"]),
                object_key=row["object_key"],
                mime=row["mime"],
                size_bytes=int(row["size_bytes"]),
                note=row.get("note"),
            )
            for row in _rows(response)
        ]

    def insert_media(self, revision: MediaRevision) -> None:
        self._client.table("recording_media").insert(
            {
                "recording_id": revision.recording_id,
                "revision_no": revision.revision_no,
                "media_type": revision.media_type.value,
                "object_key": revision.object_key,
                "mime": revision.mime,
                "size_bytes": revision.size_bytes,
                "note": revision.note,
            }
        ).execute()

    # ------------------------------------------------------------ places
    def list_places(self) -> list[Place]:
        response = (
            self._client.table("places")
            .select("id,name_en,name_fa,kind,osm_type,osm_id,recordings(count)")
            .order("id")
            .execute()
        )
        places = []
        for row in _rows(response):
            counts = row.get("recordings") or [{"count": 0}]
            osm_ref = f"{row['osm_type']}/{row['osm_id']}" if row.get("osm_id") else None
            places.append(
                Place(
                    id=int(row["id"]),
                    name_en=row.get("name_en"),
                    name_fa=row.get("name_fa"),
                    kind=row["kind"],
                    osm_ref=osm_ref,
                    recording_count=int(counts[0].get("count", 0)),
                )
            )
        return places

    def rename(self, place_id: int, name_en: str | None, name_fa: str | None) -> None:
        self._client.table("places").update({"name_en": name_en, "name_fa": name_fa}).eq(
            "id", place_id
        ).execute()
