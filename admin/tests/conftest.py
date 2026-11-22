from pathlib import Path

import pytest


@pytest.fixture(autouse=True)
def isolated_secrets(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    """Tests must never read the real secrets folder or reach real services."""
    monkeypatch.setenv("NANEY_SECRETS_DIR", str(tmp_path / "no-secrets-here"))
