"""Voice of Naney — local admin panel entry point.

Run with: uv run streamlit run app.py   (bound to 127.0.0.1 by .streamlit/config.toml)
"""

import streamlit as st

st.set_page_config(page_title="Naney Admin", page_icon="🎙️", layout="wide")
st.title("Voice of Naney — Admin")

navigation = st.navigation(
    [
        st.Page("pages/recordings.py", title="Recordings", icon="🎙️", default=True),
        st.Page("pages/uploaders.py", title="Uploaders", icon="👥"),
        st.Page("pages/cultures.py", title="Cultures", icon="🧭"),
        st.Page("pages/languages.py", title="Languages", icon="🗣️"),
        st.Page("pages/places.py", title="Places", icon="🗺️"),
    ]
)
navigation.run()
