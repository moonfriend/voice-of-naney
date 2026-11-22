import streamlit as st

from naney_admin.bootstrap import get_services
from naney_admin.ui.feedback import run_action

st.header("Places")
service = get_services().places

places = service.list()
if not places:
    st.info("No places yet. Uploaders create them when they choose an origin area.")
    st.stop()

st.dataframe(
    [
        {
            "English": p.name_en or "",
            "Persian": p.name_fa or "",
            "Kind": p.kind,
            "OpenStreetMap": p.osm_ref or "drawn by uploader",
            "Recordings": p.recording_count,
        }
        for p in places
    ],
    hide_index=True,
    width="stretch",
)

selected = st.selectbox("Place", places, format_func=lambda p: p.name_en or p.name_fa or f"#{p.id}")
if selected is not None:
    with st.form("rename-place"):
        name_en = st.text_input("English name", value=selected.name_en or "")
        name_fa = st.text_input("Persian name (فارسی)", value=selected.name_fa or "")
        if st.form_submit_button("Save"):
            run_action(lambda: service.rename(selected.id, name_en, name_fa), "Saved.")
