from pathlib import Path

import pytest

from naney_admin.config import AdminConfig, ConfigError, default_secrets_path, load_config

COMPLETE = """
SUPABASE_URL=https://proj.supabase.co/
SUPABASE_SECRET_KEY=sb_secret_x
CLOUDFLARE_ACCOUNT_ID=acc
R2_BUCKET=naney-media
R2_ACCESS_KEY_ID=id
R2_SECRET_ACCESS_KEY=secret
APP_PUBLIC_URL=https://naney.example/
"""


def write(tmp_path: Path, content: str) -> Path:
    path = tmp_path / "server.secrets.env"
    path.write_text(content)
    return path


def test_loads_a_complete_file(tmp_path: Path) -> None:
    config = load_config(write(tmp_path, COMPLETE))
    assert config == AdminConfig(
        supabase_url="https://proj.supabase.co",
        supabase_secret_key="sb_secret_x",
        r2_account_id="acc",
        r2_bucket="naney-media",
        r2_access_key_id="id",
        r2_secret_access_key="secret",
        app_public_url="https://naney.example",
    )
    assert config.invite_redirect_url == "https://naney.example/set-password"


def test_names_missing_keys_without_values(tmp_path: Path) -> None:
    with pytest.raises(ConfigError) as error:
        load_config(write(tmp_path, "SUPABASE_URL=https://x.co\nR2_SECRET_ACCESS_KEY=topsecret\n"))
    assert "SUPABASE_SECRET_KEY" in str(error.value)
    assert "topsecret" not in str(error.value)


def test_missing_file_is_a_clear_error(tmp_path: Path) -> None:
    with pytest.raises(ConfigError, match="not found"):
        load_config(tmp_path / "nope.env")


def test_repr_never_shows_secrets(tmp_path: Path) -> None:
    text = repr(load_config(write(tmp_path, COMPLETE)))
    assert "sb_secret_x" not in text
    assert "secret'" not in text


def test_default_path_is_outside_the_repo() -> None:
    path = default_secrets_path()
    repo_root = Path(__file__).resolve().parents[2]
    assert path.name == "server.secrets.env"
    assert repo_root not in path.parents


def test_env_var_overrides_the_default(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.setenv("NANEY_SECRETS_DIR", str(tmp_path))
    assert default_secrets_path() == tmp_path / "server.secrets.env"
