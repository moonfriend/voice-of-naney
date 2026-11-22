import streamlit as st

from naney_admin.bootstrap import get_services
from naney_admin.domain import UserRole
from naney_admin.ui.feedback import run_action

st.header("Uploaders")
service = get_services().uploaders

with st.form("invite", clear_on_submit=True):
    st.subheader("Invite someone")
    email = st.text_input("Email")
    display_name = st.text_input("Display name (optional)")
    role = st.radio("Role", list(UserRole), format_func=str.capitalize, horizontal=True, index=1)
    if st.form_submit_button("Send invite"):
        run_action(
            lambda: service.invite(email, display_name, UserRole(role)),
            "Invite sent. They will receive an email to set their password.",
        )

users = service.list()
if not users:
    st.info("Nobody has been invited yet.")
    st.stop()

st.dataframe(
    [
        {
            "Email": u.email,
            "Name": u.display_name or "",
            "Role": u.role.value,
            "Disabled": u.disabled,
            "Invited": u.invited_at,
            "Last sign-in": u.last_sign_in_at,
        }
        for u in users
    ],
    hide_index=True,
    width="stretch",
)

st.subheader("Change access")
selected = st.selectbox("Person", users, format_func=lambda u: u.email)
if selected is not None:
    with st.form("access"):
        new_role = st.radio(
            "Role",
            list(UserRole),
            index=list(UserRole).index(selected.role),
            format_func=str.capitalize,
            horizontal=True,
        )
        disabled = st.checkbox("Disabled (cannot upload or edit)", value=selected.disabled)
        if st.form_submit_button("Save"):

            def save() -> None:
                service.set_role(selected.id, UserRole(new_role))
                service.set_disabled(selected.id, disabled=disabled)

            run_action(save, "Saved.")

    with st.form("password", clear_on_submit=True):
        st.subheader(f"Change password for {selected.email}")
        st.caption("For people who forgot theirs. They can sign in with it right away.")
        new_password = st.text_input("New password", type="password")
        repeated = st.text_input("Repeat new password", type="password")
        if st.form_submit_button("Change password"):
            run_action(
                lambda: service.set_password(selected.id, new_password, repeated),
                "Password changed. Share it with them privately, not by email or chat.",
            )
