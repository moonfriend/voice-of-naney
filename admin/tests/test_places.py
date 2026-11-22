import pytest

from naney_admin.domain import Place
from naney_admin.services.places import PlaceService
from naney_admin.validation import ValidationError
from tests.fakes import FakePlaceRepo


@pytest.fixture
def repo() -> FakePlaceRepo:
    repo = FakePlaceRepo()
    repo.places[1] = Place(1, "Tabriz", None, "city", "relation/123", 2)
    return repo


def test_renames_with_both_languages(repo: FakePlaceRepo) -> None:
    PlaceService(repo).rename(1, " Tabriz ", " تبریز ")
    assert (repo.places[1].name_en, repo.places[1].name_fa) == ("Tabriz", "تبریز")


def test_one_name_is_enough(repo: FakePlaceRepo) -> None:
    PlaceService(repo).rename(1, "", "تبریز")
    assert repo.places[1].name_en is None


def test_needs_at_least_one_name(repo: FakePlaceRepo) -> None:
    with pytest.raises(ValidationError):
        PlaceService(repo).rename(1, " ", None)
