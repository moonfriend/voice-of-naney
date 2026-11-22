from __future__ import annotations

from collections.abc import Callable

from naney_admin.domain import MediaRevision
from naney_admin.ports import MediaStore, RecordingRepo
from naney_admin.validation import ValidationError, media_rule_for, optional_text


class RevisionService:
    """Adds a new media file next to the original (revision 0 is never touched)."""

    def __init__(self, repo: RecordingRepo, store: MediaStore, new_id: Callable[[], str]) -> None:
        self._repo = repo
        self._store = store
        self._new_id = new_id

    def add_revision(
        self, recording_id: str, data: bytes, mime: str, note: str | None
    ) -> MediaRevision:
        normalised_mime, rule = media_rule_for(mime, len(data))
        existing = self._repo.list_media(recording_id)
        if not existing:
            raise ValidationError("Recording not found.")

        revision = MediaRevision(
            recording_id=recording_id,
            revision_no=max(media.revision_no for media in existing) + 1,
            media_type=rule.media_type,
            object_key=f"media/{self._new_id()}.{rule.extension}",
            mime=normalised_mime,
            size_bytes=len(data),
            note=optional_text(note, "Note", 1000),
        )
        self._store.put(revision.object_key, data, normalised_mime)
        try:
            self._repo.insert_media(revision)
        except Exception:
            # Don't leave an orphaned file behind if the database rejected the revision.
            self._store.delete(revision.object_key)
            raise
        return revision
