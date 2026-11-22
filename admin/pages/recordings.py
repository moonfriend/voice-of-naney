import streamlit as st

from naney_admin.bootstrap import get_services
from naney_admin.domain import RecordingStatus
from naney_admin.ui.feedback import run_action

st.header("Recordings")
services = get_services()

search_col, status_col = st.columns([3, 1])
text = search_col.text_input("Search titles")
status_choice = status_col.selectbox("Status", ["All", *list(RecordingStatus)])
status = None if status_choice == "All" else RecordingStatus(status_choice)

recordings = services.recordings.search(text, status)
if not recordings:
    st.info("No recordings found.")
    st.stop()

st.dataframe(
    [
        {
            "Title": r.title,
            "Kind": r.kind,
            "Status": r.status.value,
            "Place": r.place_name,
            "Uploader": r.uploader_email or "",
            "Created": r.created_at,
        }
        for r in recordings
    ],
    hide_index=True,
    width="stretch",
)

selected = st.selectbox(
    "Recording", recordings, format_func=lambda r: f"{r.title} ({r.status.value})"
)
if selected is None:
    st.stop()

if selected.status == RecordingStatus.PUBLISHED:
    hide_clicked = st.button("Hide from the public map", type="primary")
    if hide_clicked and run_action(lambda: services.recordings.hide(selected.id), "Hidden."):
        st.rerun()
else:
    publish_clicked = st.button("Publish again")
    if publish_clicked and run_action(
        lambda: services.recordings.unhide(selected.id), "Published."
    ):
        st.rerun()

st.subheader("Media revisions")
st.caption("Revision 0 is the original upload and can never be changed or removed.")
st.dataframe(
    [
        {
            "Revision": m.revision_no,
            "Type": m.media_type.value,
            "File": m.object_key,
            "Size (MB)": round(m.size_bytes / 1_048_576, 2),
            "Note": m.note or "",
        }
        for m in services.recordings.media(selected.id)
    ],
    hide_index=True,
    width="stretch",
)

with st.form("revision", clear_on_submit=True):
    st.subheader("Add a revision")
    upload = st.file_uploader(
        "Audio or video file", type=["mp3", "m4a", "aac", "wav", "ogg", "webm", "mp4"]
    )
    note = st.text_input("What changed? (e.g. noise removed)")
    if st.form_submit_button("Upload revision") and upload is not None:
        run_action(
            lambda: services.revisions.add_revision(
                selected.id, upload.getvalue(), upload.type or "", note
            ),
            "Revision added. The public page now plays it; the original stays available.",
        )
