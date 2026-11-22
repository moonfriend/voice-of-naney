from __future__ import annotations

from naney_admin.domain import Uploader, UserRole
from naney_admin.ports import UserRepo
from naney_admin.validation import ValidationError, normalise_email, optional_text


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
