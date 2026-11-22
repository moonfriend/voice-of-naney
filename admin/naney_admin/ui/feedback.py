from __future__ import annotations

from collections.abc import Callable

import streamlit as st

from naney_admin.validation import ValidationError


def run_action(action: Callable[[], object], success: str) -> bool:
    """Runs an admin action, showing validation problems instead of a stack trace."""
    try:
        action()
    except ValidationError as error:
        st.error(str(error))
        return False
    st.success(success)
    return True
