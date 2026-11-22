import pytest

from naney_admin.domain import UserRole
from naney_admin.services.uploaders import UploaderService
from naney_admin.validation import ValidationError
from tests.fakes import FakeUserRepo

REDIRECT = "https://naney.example/set-password"


@pytest.fixture
def repo() -> FakeUserRepo:
    return FakeUserRepo()


@pytest.fixture
def service(repo: FakeUserRepo) -> UploaderService:
    return UploaderService(repo, invite_redirect_url=REDIRECT)


def test_invites_with_normalised_email_and_display_name(
    service: UploaderService, repo: FakeUserRepo
) -> None:
    user_id = service.invite(
        "  Friend@Example.COM ", display_name=" Leila ", role=UserRole.UPLOADER
    )
    assert repo.invited == [f"friend@example.com->{REDIRECT}"]
    user = repo.users[user_id]
    assert (user.display_name, user.role) == ("Leila", UserRole.UPLOADER)


def test_invites_admins(service: UploaderService, repo: FakeUserRepo) -> None:
    user_id = service.invite("el@example.com", display_name=None, role=UserRole.ADMIN)
    assert repo.users[user_id].role == UserRole.ADMIN


@pytest.mark.parametrize("email", ["", "not-an-email", "a@b", "x@y.z w"])
def test_rejects_invalid_emails(service: UploaderService, email: str) -> None:
    with pytest.raises(ValidationError):
        service.invite(email, display_name=None, role=UserRole.UPLOADER)


def test_rejects_inviting_an_existing_user(service: UploaderService) -> None:
    service.invite("friend@example.com", display_name=None, role=UserRole.UPLOADER)
    with pytest.raises(ValidationError, match="already"):
        service.invite("FRIEND@example.com", display_name=None, role=UserRole.UPLOADER)


def test_disables_and_reenables(service: UploaderService, repo: FakeUserRepo) -> None:
    user_id = service.invite("friend@example.com", display_name=None, role=UserRole.UPLOADER)
    service.set_disabled(user_id, disabled=True)
    assert repo.users[user_id].disabled is True
    service.set_disabled(user_id, disabled=False)
    assert repo.users[user_id].disabled is False


def test_changes_role(service: UploaderService, repo: FakeUserRepo) -> None:
    user_id = service.invite("friend@example.com", display_name=None, role=UserRole.UPLOADER)
    service.set_role(user_id, UserRole.ADMIN)
    assert repo.users[user_id].role == UserRole.ADMIN


def test_refuses_to_remove_the_last_active_admin(service: UploaderService) -> None:
    admin_id = service.invite("el@example.com", display_name=None, role=UserRole.ADMIN)
    with pytest.raises(ValidationError, match="last active admin"):
        service.set_role(admin_id, UserRole.UPLOADER)
    with pytest.raises(ValidationError, match="last active admin"):
        service.set_disabled(admin_id, disabled=True)


def test_requires_a_redirect_url() -> None:
    with pytest.raises(ValueError, match="redirect"):
        UploaderService(FakeUserRepo(), invite_redirect_url="")


def test_sets_a_new_password(service: UploaderService, repo: FakeUserRepo) -> None:
    user_id = service.invite("friend@example.com", display_name=None, role=UserRole.UPLOADER)
    service.set_password(user_id, "correct horse", "correct horse")
    assert repo.passwords[user_id] == "correct horse"


@pytest.mark.parametrize(
    ("password", "confirmation", "message"),
    [
        ("short", "short", "at least 8"),
        ("x" * 73, "x" * 73, "at most 72"),
        ("correct horse", "correct hose", "do not match"),
        ("        ", "        ", "at least 8"),
    ],
)
def test_rejects_bad_passwords(
    service: UploaderService, repo: FakeUserRepo, password: str, confirmation: str, message: str
) -> None:
    user_id = service.invite("friend@example.com", display_name=None, role=UserRole.UPLOADER)
    with pytest.raises(ValidationError, match=message):
        service.set_password(user_id, password, confirmation)
    assert repo.passwords == {}


def test_password_errors_never_contain_the_password(service: UploaderService) -> None:
    user_id = service.invite("friend@example.com", display_name=None, role=UserRole.UPLOADER)
    with pytest.raises(ValidationError) as error:
        service.set_password(user_id, "secret-but-short"[:7], "secret-but-short"[:7])
    assert "secret-" not in str(error.value)
