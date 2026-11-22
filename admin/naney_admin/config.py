"""Loads server-only secrets from the folder next to the repo (never from inside it)."""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

from dotenv import dotenv_values

REQUIRED_KEYS = (
    "SUPABASE_URL",
    "SUPABASE_SECRET_KEY",
    "CLOUDFLARE_ACCOUNT_ID",
    "R2_BUCKET",
    "R2_ACCESS_KEY_ID",
    "R2_SECRET_ACCESS_KEY",
    "APP_PUBLIC_URL",
)


class ConfigError(RuntimeError):
    """Configuration problem. Messages name keys, never values."""


@dataclass(frozen=True)
class AdminConfig:
    supabase_url: str
    supabase_secret_key: str = field(repr=False)
    r2_account_id: str
    r2_bucket: str
    r2_access_key_id: str = field(repr=False)
    r2_secret_access_key: str = field(repr=False)
    app_public_url: str

    @property
    def invite_redirect_url(self) -> str:
        return f"{self.app_public_url}/set-password"

    @property
    def r2_endpoint(self) -> str:
        return f"https://{self.r2_account_id}.r2.cloudflarestorage.com"


def default_secrets_path() -> Path:
    override = os.environ.get("NANEY_SECRETS_DIR")
    if override:
        return Path(override) / "server.secrets.env"
    # admin/naney_admin/config.py -> projects/naney-secrets/
    projects_dir = Path(__file__).resolve().parents[3]
    return projects_dir / "naney-secrets" / "server.secrets.env"


def load_config(path: Path | None = None) -> AdminConfig:
    secrets_path = path or default_secrets_path()
    if not secrets_path.is_file():
        raise ConfigError(f"Secrets file not found: {secrets_path}")
    values = {key: (value or "").strip() for key, value in dotenv_values(secrets_path).items()}
    missing = [key for key in REQUIRED_KEYS if not values.get(key)]
    if missing:
        raise ConfigError(f"Missing in {secrets_path.name}: {', '.join(missing)}")
    return AdminConfig(
        supabase_url=values["SUPABASE_URL"].rstrip("/"),
        supabase_secret_key=values["SUPABASE_SECRET_KEY"],
        r2_account_id=values["CLOUDFLARE_ACCOUNT_ID"],
        r2_bucket=values["R2_BUCKET"],
        r2_access_key_id=values["R2_ACCESS_KEY_ID"],
        r2_secret_access_key=values["R2_SECRET_ACCESS_KEY"],
        app_public_url=values["APP_PUBLIC_URL"].rstrip("/"),
    )
