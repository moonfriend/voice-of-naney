"""Builds the services once per process. Tests inject fakes via `st.session_state`."""

from __future__ import annotations

import hashlib
import uuid
from dataclasses import dataclass
from pathlib import Path

import boto3
import streamlit as st
from supabase import create_client

from naney_admin.adapters.r2_store import R2MediaStore
from naney_admin.adapters.supabase_repo import SupabaseRepository
from naney_admin.config import ConfigError, load_config
from naney_admin.services.lookup_lists import LookupListService
from naney_admin.services.places import PlaceService
from naney_admin.services.recordings import RecordingService
from naney_admin.services.revisions import RevisionService
from naney_admin.services.uploaders import UploaderService

SERVICES_KEY = "services"


@dataclass(frozen=True)
class Services:
    lookups: LookupListService
    uploaders: UploaderService
    recordings: RecordingService
    revisions: RevisionService
    places: PlaceService


PACKAGE_DIR = Path(__file__).resolve().parent


def code_fingerprint(root: Path) -> str:
    """Hash of the package source, so cached services are rebuilt after code changes."""
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*.py")):
        digest.update(str(path.relative_to(root)).encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


@st.cache_resource(max_entries=1)
def _build_services(code_version: str) -> Services:
    config = load_config()
    repo = SupabaseRepository(create_client(config.supabase_url, config.supabase_secret_key))
    s3 = boto3.client(
        "s3",
        endpoint_url=config.r2_endpoint,
        region_name="auto",
        aws_access_key_id=config.r2_access_key_id,
        aws_secret_access_key=config.r2_secret_access_key,
    )
    return Services(
        lookups=LookupListService(repo),
        uploaders=UploaderService(repo, invite_redirect_url=config.invite_redirect_url),
        recordings=RecordingService(repo),
        revisions=RevisionService(
            repo, R2MediaStore(s3, config.r2_bucket), lambda: str(uuid.uuid4())
        ),
        places=PlaceService(repo),
    )


def get_services() -> Services:
    injected = st.session_state.get(SERVICES_KEY)
    if isinstance(injected, Services):
        return injected
    try:
        return _build_services(code_fingerprint(PACKAGE_DIR))
    except ConfigError as error:
        st.error(f"Admin panel is not configured: {error}")
        st.stop()
        raise  # unreachable: st.stop() raises, but keeps type checkers happy
