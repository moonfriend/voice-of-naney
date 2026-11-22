from __future__ import annotations

from naney_admin.domain import LookupItem, LookupTable
from naney_admin.ports import LookupRepo
from naney_admin.validation import ValidationError, require_name


class LookupListService:
    """Curated cultures/languages.

    Items are deactivated, never deleted, because recordings refer to them.
    """

    def __init__(self, repo: LookupRepo) -> None:
        self._repo = repo

    def list(self, table: LookupTable) -> list[LookupItem]:
        return self._repo.list_items(table)

    def add(self, table: LookupTable, name_en: str, name_fa: str) -> LookupItem:
        english = require_name(name_en, "English name")
        persian = require_name(name_fa, "Persian name")
        self._ensure_unique(table, english, exclude_id=None)
        return self._repo.insert_item(table, english, persian)

    def rename(self, table: LookupTable, item_id: int, name_en: str, name_fa: str) -> None:
        english = require_name(name_en, "English name")
        persian = require_name(name_fa, "Persian name")
        self._ensure_unique(table, english, exclude_id=item_id)
        self._repo.update_item(table, item_id, name_en=english, name_fa=persian)

    def set_active(self, table: LookupTable, item_id: int, *, active: bool) -> None:
        self._repo.update_item(table, item_id, active=active)

    def _ensure_unique(self, table: LookupTable, name_en: str, exclude_id: int | None) -> None:
        clash = any(
            item.name_en.lower() == name_en.lower() and item.id != exclude_id
            for item in self._repo.list_items(table)
        )
        if clash:
            raise ValidationError(f"'{name_en}' already exists.")
