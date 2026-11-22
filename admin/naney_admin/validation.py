"""Input rules. Mirrors the database constraints so admins get friendly messages first."""

from __future__ import annotations

import re
from dataclasses import dataclass

from naney_admin.domain import MediaType


class ValidationError(ValueError):
    """An admin input problem that the UI should show as-is."""


MB = 1024 * 1024
_EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$")


def require_name(value: str, field: str, max_length: int = 100) -> str:
    cleaned = value.strip()
    if not cleaned:
        raise ValidationError(f"{field} is required.")
    if len(cleaned) > max_length:
        raise ValidationError(f"{field} must be at most {max_length} characters.")
    return cleaned


def optional_text(value: str | None, field: str, max_length: int) -> str | None:
    if value is None or not value.strip():
        return None
    cleaned = value.strip()
    if len(cleaned) > max_length:
        raise ValidationError(f"{field} must be at most {max_length} characters.")
    return cleaned


def normalise_email(value: str) -> str:
    cleaned = value.strip().lower()
    if not _EMAIL.match(cleaned):
        raise ValidationError("Please enter a valid email address.")
    return cleaned


@dataclass(frozen=True)
class MediaRule:
    media_type: MediaType
    extension: str
    max_bytes: int


# Same allow-list and limits as the Worker's upload policy.
MEDIA_RULES: dict[str, MediaRule] = {
    "audio/mpeg": MediaRule(MediaType.AUDIO, "mp3", 50 * MB),
    "audio/mp4": MediaRule(MediaType.AUDIO, "m4a", 50 * MB),
    "audio/x-m4a": MediaRule(MediaType.AUDIO, "m4a", 50 * MB),
    "audio/aac": MediaRule(MediaType.AUDIO, "aac", 50 * MB),
    "audio/wav": MediaRule(MediaType.AUDIO, "wav", 50 * MB),
    "audio/x-wav": MediaRule(MediaType.AUDIO, "wav", 50 * MB),
    "audio/ogg": MediaRule(MediaType.AUDIO, "ogg", 50 * MB),
    "audio/webm": MediaRule(MediaType.AUDIO, "webm", 50 * MB),
    "audio/flac": MediaRule(MediaType.AUDIO, "flac", 50 * MB),
    "audio/x-flac": MediaRule(MediaType.AUDIO, "flac", 50 * MB),
    "video/mp4": MediaRule(MediaType.VIDEO, "mp4", 500 * MB),
    "video/webm": MediaRule(MediaType.VIDEO, "webm", 500 * MB),
    "video/quicktime": MediaRule(MediaType.VIDEO, "mov", 500 * MB),
    "video/x-m4v": MediaRule(MediaType.VIDEO, "m4v", 500 * MB),
}


def media_rule_for(mime: str, size: int) -> tuple[str, MediaRule]:
    normalised = mime.split(";")[0].strip().lower()
    rule = MEDIA_RULES.get(normalised)
    if rule is None:
        raise ValidationError(f"Unsupported file type: {mime or 'unknown'}.")
    if size <= 0:
        raise ValidationError("The file is empty.")
    if size > rule.max_bytes:
        raise ValidationError(f"The file is too large (max {rule.max_bytes // MB} MB).")
    return normalised, rule
