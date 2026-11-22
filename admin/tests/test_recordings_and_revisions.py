import pytest

from naney_admin.domain import MediaRevision, MediaType, RecordingStatus, RecordingSummary
from naney_admin.services.recordings import RecordingService
from naney_admin.services.revisions import RevisionService
from naney_admin.validation import ValidationError
from tests.fakes import NOW, FakeMediaStore, FakeRecordingRepo

REC_ID = "11111111-1111-4111-8111-111111111111"


@pytest.fixture
def repo() -> FakeRecordingRepo:
    repo = FakeRecordingRepo()
    repo.add_recording(
        RecordingSummary(
            id=REC_ID,
            title="Lay lay",
            kind="lullaby",
            status=RecordingStatus.PUBLISHED,
            place_name="Tabriz",
            uploader_email="friend@example.com",
            created_at=NOW,
        ),
        MediaRevision(
            recording_id=REC_ID,
            revision_no=0,
            media_type=MediaType.AUDIO,
            object_key="media/original.mp3",
            mime="audio/mpeg",
            size_bytes=1000,
            note=None,
        ),
    )
    return repo


def test_search_filters_by_text_and_status(repo: FakeRecordingRepo) -> None:
    service = RecordingService(repo)
    assert [r.id for r in service.search("lay", None)] == [REC_ID]
    assert service.search("lay", RecordingStatus.HIDDEN) == []
    assert service.search("nothing", None) == []


def test_hide_and_unhide(repo: FakeRecordingRepo) -> None:
    service = RecordingService(repo)
    service.hide(REC_ID)
    assert repo.recordings[REC_ID].status == RecordingStatus.HIDDEN
    service.unhide(REC_ID)
    assert repo.recordings[REC_ID].status == RecordingStatus.PUBLISHED


class TestRevisions:
    @pytest.fixture
    def store(self) -> FakeMediaStore:
        return FakeMediaStore()

    @pytest.fixture
    def service(self, repo: FakeRecordingRepo, store: FakeMediaStore) -> RevisionService:
        return RevisionService(repo, store, new_id=lambda: "22222222-2222-4222-8222-222222222222")

    def test_adds_the_next_revision_alongside_the_original(
        self, service: RevisionService, repo: FakeRecordingRepo, store: FakeMediaStore
    ) -> None:
        revision = service.add_revision(
            REC_ID, b"cleaned audio", "audio/mpeg", note=" noise removed "
        )

        assert revision.revision_no == 1
        assert revision.object_key == "media/22222222-2222-4222-8222-222222222222.mp3"
        assert revision.note == "noise removed"
        assert store.objects[revision.object_key] == (b"cleaned audio", "audio/mpeg")
        assert [m.revision_no for m in repo.list_media(REC_ID)] == [0, 1]
        assert repo.list_media(REC_ID)[0].object_key == "media/original.mp3"

    def test_a_video_revision_is_typed_as_video(self, service: RevisionService) -> None:
        revision = service.add_revision(REC_ID, b"v", "video/mp4", note=None)
        assert revision.media_type == MediaType.VIDEO

    @pytest.mark.parametrize("mime", ["image/png", "application/pdf", "text/html"])
    def test_rejects_non_media_types(self, service: RevisionService, mime: str) -> None:
        with pytest.raises(ValidationError, match="type"):
            service.add_revision(REC_ID, b"x", mime, note=None)

    def test_rejects_empty_and_oversized_files(self, service: RevisionService) -> None:
        with pytest.raises(ValidationError):
            service.add_revision(REC_ID, b"", "audio/mpeg", note=None)
        with pytest.raises(ValidationError, match="too large"):
            service.add_revision(REC_ID, b"x" * (50 * 1024 * 1024 + 1), "audio/mpeg", note=None)

    def test_rejects_unknown_recordings(self, service: RevisionService) -> None:
        with pytest.raises(ValidationError, match="not found"):
            service.add_revision(
                "33333333-3333-4333-8333-333333333333", b"x", "audio/mpeg", note=None
            )

    def test_removes_the_stored_file_if_the_database_insert_fails(
        self, service: RevisionService, repo: FakeRecordingRepo, store: FakeMediaStore
    ) -> None:
        repo.fail_next_insert = True
        with pytest.raises(RuntimeError):
            service.add_revision(REC_ID, b"x", "audio/mpeg", note=None)
        assert store.objects == {}
        assert len(repo.list_media(REC_ID)) == 1
