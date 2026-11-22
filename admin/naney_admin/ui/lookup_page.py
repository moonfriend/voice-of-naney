from __future__ import annotations

import streamlit as st

from naney_admin.bootstrap import get_services
from naney_admin.domain import LookupTable
from naney_admin.ui.feedback import run_action


def render_lookup_page(table: LookupTable, title: str, singular: str) -> None:
    st.header(title)
    service = get_services().lookups

    with st.form(f"add-{table}", clear_on_submit=True):
        st.subheader(f"Add a {singular}")
        name_en = st.text_input("English name")
        name_fa = st.text_input("Persian name (فارسی)")
        if st.form_submit_button("Add"):
            run_action(lambda: service.add(table, name_en, name_fa), f"Added {name_en.strip()}.")

    items = service.list(table)
    if not items:
        st.info(f"No {title.lower()} yet. Uploaders will only see active ones.")
        return

    st.dataframe(
        [{"English": i.name_en, "Persian": i.name_fa, "Active": i.active} for i in items],
        hide_index=True,
        width="stretch",
    )

    st.subheader(f"Edit a {singular}")
    selected = st.selectbox(
        singular.capitalize(),
        items,
        format_func=lambda item: f"{item.name_en} — {item.name_fa}",
        key=f"edit-{table}-select",
    )
    if selected is None:
        return
    with st.form(f"edit-{table}"):
        new_en = st.text_input("English name", value=selected.name_en)
        new_fa = st.text_input("Persian name (فارسی)", value=selected.name_fa)
        active = st.checkbox("Active (shown to uploaders)", value=selected.active)
        if st.form_submit_button("Save"):

            def save() -> None:
                service.rename(table, selected.id, new_en, new_fa)
                service.set_active(table, selected.id, active=active)

            run_action(save, "Saved.")
