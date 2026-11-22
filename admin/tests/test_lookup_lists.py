import pytest

from naney_admin.services.lookup_lists import LookupListService
from naney_admin.validation import ValidationError
from tests.fakes import FakeLookupRepo


@pytest.fixture
def service() -> LookupListService:
    return LookupListService(FakeLookupRepo())


def test_adds_trimmed_bilingual_names(service: LookupListService) -> None:
    item = service.add("cultures", "  Kurdish ", " کرد ")
    assert (item.name_en, item.name_fa, item.active) == ("Kurdish", "کرد", True)
    assert service.list("cultures") == [item]


@pytest.mark.parametrize(
    ("name_en", "name_fa"), [("", "کرد"), ("Kurdish", "  "), ("x" * 101, "کرد")]
)
def test_rejects_missing_or_too_long_names(
    service: LookupListService, name_en: str, name_fa: str
) -> None:
    with pytest.raises(ValidationError):
        service.add("cultures", name_en, name_fa)


def test_rejects_duplicates_case_insensitively(service: LookupListService) -> None:
    service.add("languages", "Gilaki", "گیلکی")
    with pytest.raises(ValidationError, match="already exists"):
        service.add("languages", "gilaki", "گیلکی")


def test_lists_are_independent(service: LookupListService) -> None:
    service.add("cultures", "Kurdish", "کرد")
    service.add("languages", "Kurdish", "کردی")
    assert len(service.list("cultures")) == 1
    assert len(service.list("languages")) == 1


def test_renames_and_deactivates_without_deleting(service: LookupListService) -> None:
    item = service.add("cultures", "Lur", "لر")
    service.rename("cultures", item.id, "Lor", "لُر")
    service.set_active("cultures", item.id, active=False)
    [updated] = service.list("cultures")
    assert (updated.name_en, updated.name_fa, updated.active) == ("Lor", "لُر", False)


def test_rename_rejects_a_clash_with_another_item(service: LookupListService) -> None:
    service.add("cultures", "Lur", "لر")
    other = service.add("cultures", "Bakhtiari", "بختیاری")
    with pytest.raises(ValidationError, match="already exists"):
        service.rename("cultures", other.id, "LUR", "لر")


def test_rename_to_the_same_name_is_allowed(service: LookupListService) -> None:
    item = service.add("cultures", "Lur", "لر")
    service.rename("cultures", item.id, "Lur", "لُر")
    assert service.list("cultures")[0].name_fa == "لُر"
