from __future__ import annotations

from naney_admin.domain import Uploader, UserRole
from naney_admin.ports import UserRepo
from naney_admin.validation import ValidationError, normalise_email, optional_text

MIN_PASSWORD_LENGTH = 8
# Supabase hashes passwords with bcrypt, which only uses the first 72 bytes.
MAX_PASSWORD_BYTES = 72


class UploaderService:
    """Invite-only accounts. Sign-up is disabled, so this is the only way people get in."""

    def __init__(self, repo: UserRepo, invite_redirect_url: str) -> None:
        if not invite_redirect_url:
            raise ValueError("An invite redirect URL is required.")
        self._repo = repo
        self._redirect = invite_redirect_url

    def list(self) -> list[Uploader]:
        return self._repo.list_uploaders()

    def invite(self, email: str, display_name: str | None, role: UserRole) -> str:
        address = normalise_email(email)
        if any(user.email.lower() == address for user in self._repo.list_uploaders()):
            raise ValidationError(f"{address} is already invited.")
        name = optional_text(display_name, "Display name", 100)
        user_id = self._repo.invite(address, self._redirect)
        self._repo.update_profile(user_id, role=role, display_name=name)
        return user_id

    def set_password(self, user_id: str, password: str, confirmation: str) -> None:
        """Lets an admin reset a forgotten password. Messages never echo the password."""
        if len(password.strip()) < MIN_PASSWORD_LENGTH:
            raise ValidationError(
                f"The password must have at least {MIN_PASSWORD_LENGTH} characters."
            )
        if len(password.encode()) > MAX_PASSWORD_BYTES:
            raise ValidationError(f"The password must be at most {MAX_PASSWORD_BYTES} characters.")
        if password != confirmation:
            raise ValidationError("The two passwords do not match.")
        self._repo.set_password(user_id, password)

    def set_role(self, user_id: str, role: UserRole) -> None:
        if role != UserRole.ADMIN:
            self._ensure_not_last_admin(user_id)
        self._repo.update_profile(user_id, role=role)

    def set_disabled(self, user_id: str, *, disabled: bool) -> None:
        if disabled:
            self._ensure_not_last_admin(user_id)
        self._repo.update_profile(user_id, disabled=disabled)

    def _ensure_not_last_admin(self, user_id: str) -> None:
        active_admins = [
            user
            for user in self._repo.list_uploaders()
            if user.role == UserRole.ADMIN and not user.disabled
        ]
        if [admin.id for admin in active_admins] == [user_id]:
            raise ValidationError("You cannot remove the last active admin.")
