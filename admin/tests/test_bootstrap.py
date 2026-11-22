from pathlib import Path

from naney_admin.bootstrap import code_fingerprint


def test_fingerprint_changes_when_code_changes(tmp_path: Path) -> None:
    module = tmp_path / "service.py"
    module.write_text("def a() -> None: ...\n")
    before = code_fingerprint(tmp_path)
    module.write_text("def a() -> None: ...\ndef b() -> None: ...\n")
    assert code_fingerprint(tmp_path) != before


def test_fingerprint_is_stable_without_changes(tmp_path: Path) -> None:
    (tmp_path / "service.py").write_text("x = 1\n")
    assert code_fingerprint(tmp_path) == code_fingerprint(tmp_path)
