"""Smoke tests: each page renders with fake services and its main actions work."""

from pathlib import Path

import pytest
from streamlit.testing.v1 import AppTest

from naney_admin.bootstrap import SERVICES_KEY, Services
from naney_admin.domain import MediaRevision, MediaType, Place, RecordingStatus, RecordingSummary
from naney_admin.services.lookup_lists import LookupListService
from naney_admin.services.places import PlaceService
from naney_admin.services.recordings import RecordingService
from naney_admin.services.revisions import RevisionService
from naney_admin.services.uploaders import UploaderService
from tests.fakes import (
    NOW,
    FakeLookupRepo,
    FakeMediaStore,
    FakePlaceRepo,
    FakeRecordingRepo,
    FakeUserRepo,
)

PAGES = Path(__file__).resolve().parent.parent / "pages"
REC_ID = "11111111-1111-4111-8111-111111111111"


class World:
    def __init__(self) -> None:
        self.lookups = FakeLookupRepo()
        self.users = FakeUserRepo()
        self.recordings = FakeRecordingRepo()
        self.places = FakePlaceRepo()
        self.store = FakeMediaStore()
        self.recordings.add_recording(
            RecordingSummary(
                REC_ID, "Lay lay", "lullaby", RecordingStatus.PUBLISHED, "Tabriz", None, NOW
            ),
            MediaRevision(REC_ID, 0, MediaType.AUDIO, "media/o.mp3", "audio/mpeg", 10, None),
        )
        self.places.places[1] = Place(1, "Tabriz", None, "city", "relation/1", 1)

    def services(self) -> Services:
        return Services(
            lookups=LookupListService(self.lookups),
            uploaders=UploaderService(
                self.users, invite_redirect_url="https://naney.test/set-password"
            ),
            recordings=RecordingService(self.recordings),
            revisions=RevisionService(self.recordings, self.store, lambda: "new-id"),
            places=PlaceService(self.places),
        )


@pytest.fixture
def world() -> World:
    return World()


def run_page(world: World, name: str) -> AppTest:
    app = AppTest.from_file(str(PAGES / f"{name}.py"))
    app.session_state[SERVICES_KEY] = world.services()
    return app.run()


@pytest.mark.parametrize("name", ["recordings", "uploaders", "cultures", "languages", "places"])
def test_every_page_renders(world: World, name: str) -> None:
    app = run_page(world, name)
    assert not app.exception


def test_adding_a_culture(world: World) -> None:
    app = run_page(world, "cultures")
    app.text_input[0].input("Kurdish")
    app.text_input[1].input("کرد")
    app.button[0].click().run()
    assert not app.exception
    assert [item.name_en for item in world.lookups.list_items("cultures")] == ["Kurdish"]
    assert app.success[0].value == "Added Kurdish."


def test_adding_a_duplicate_culture_shows_an_error(world: World) -> None:
    world.lookups.insert_item("cultures", "Kurdish", "کرد")
    app = run_page(world, "cultures")
    app.text_input[0].input("kurdish")
    app.text_input[1].input("کرد")
    app.button[0].click().run()
    assert "already exists" in app.error[0].value


def test_inviting_an_uploader(world: World) -> None:
    app = run_page(world, "uploaders")
    app.text_input[0].input("friend@example.com")
    app.button[0].click().run()
    assert not app.exception
    assert world.users.invited == ["friend@example.com->https://naney.test/set-password"]


def test_hiding_a_recording(world: World) -> None:
    app = run_page(world, "recordings")
    hide = next(button for button in app.button if button.label == "Hide from the public map")
    hide.click().run()
    assert not app.exception
    assert world.recordings.recordings[REC_ID].status == RecordingStatus.HIDDEN


def test_app_without_secrets_shows_a_configuration_error() -> None:
    app = AppTest.from_file(str(PAGES.parent / "app.py")).run()
    assert not app.exception
    assert "not configured" in app.error[0].value
