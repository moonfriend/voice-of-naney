from __future__ import annotations

from naney_admin.domain import Place
from naney_admin.ports import PlaceRepo
from naney_admin.validation import ValidationError, optional_text


class PlaceService:
    def __init__(self, repo: PlaceRepo) -> None:
        self._repo = repo

    def list(self) -> list[Place]:
        return self._repo.list_places()

    def rename(self, place_id: int, name_en: str | None, name_fa: str | None) -> None:
        english = optional_text(name_en, "English name", 200)
        persian = optional_text(name_fa, "Persian name", 200)
        if english is None and persian is None:
            raise ValidationError("A place needs at least one name.")
        self._repo.rename(place_id, english, persian)
