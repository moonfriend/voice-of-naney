from __future__ import annotations

from naney_admin.domain import MediaRevision, RecordingStatus, RecordingSummary
from naney_admin.ports import RecordingRepo


class RecordingService:
    """No pre-moderation: recordings publish immediately and admins can hide them afterwards."""

    def __init__(self, repo: RecordingRepo) -> None:
        self._repo = repo

    def search(self, text: str, status: RecordingStatus | None) -> list[RecordingSummary]:
        return self._repo.search(text.strip(), status)

    def hide(self, recording_id: str) -> None:
        self._repo.set_status(recording_id, RecordingStatus.HIDDEN)

    def unhide(self, recording_id: str) -> None:
        self._repo.set_status(recording_id, RecordingStatus.PUBLISHED)

    def media(self, recording_id: str) -> list[MediaRevision]:
        return self._repo.list_media(recording_id)
