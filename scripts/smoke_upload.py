"""End-to-end smoke test of the live upload path, leaving nothing behind.

temp user -> sign in -> POST /api/uploads -> PUT to R2 -> complete -> GET /media (range)
-> cleanup (object + user). Run: uv run --project admin python scripts/smoke_upload.py
Prints step results only; never prints secrets or tokens.
"""

from __future__ import annotations

import json
import secrets
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "admin"))

import boto3  # noqa: E402
from dotenv import dotenv_values  # noqa: E402

from naney_admin.config import default_secrets_path, load_config  # noqa: E402


def call(method: str, url: str, *, headers: dict[str, str], body: bytes | None = None) -> tuple[int, bytes, dict[str, str]]:
    # Cloudflare's bot filter rejects Python's default User-Agent (error 1010).
    headers = {"user-agent": "naney-smoke-test/1.0", **headers}
    request = urllib.request.Request(url, data=body, method=method, headers=headers)  # noqa: S310
    try:
        with urllib.request.urlopen(request, timeout=30) as response:  # noqa: S310
            return response.status, response.read(), dict(response.headers)
    except urllib.error.HTTPError as error:
        return error.code, error.read(), dict(error.headers)


def main() -> int:
    config = load_config()
    public = dotenv_values(default_secrets_path().parent / "app.public.env")
    publishable = str(public["SUPABASE_PUBLISHABLE_KEY"])
    api = config.app_public_url
    service = {"apikey": config.supabase_secret_key, "content-type": "application/json"}

    email = f"smoke-{secrets.token_hex(4)}@example.invalid"
    password = secrets.token_urlsafe(24)
    status, body, _ = call(
        "POST", f"{config.supabase_url}/auth/v1/admin/users", headers=service,
        body=json.dumps({"email": email, "password": password, "email_confirm": True}).encode(),
    )
    assert status == 200, f"create user failed: {status}"
    user_id = json.loads(body)["id"]
    print("1. temporary user created")
    object_key = None
    try:
        status, body, _ = call(
            "POST", f"{config.supabase_url}/auth/v1/token?grant_type=password",
            headers={"apikey": publishable, "content-type": "application/json"},
            body=json.dumps({"email": email, "password": password}).encode(),
        )
        assert status == 200, f"sign-in failed: {status}"
        token = json.loads(body)["access_token"]
        print("2. signed in with password")

        payload = b"naney smoke test " + secrets.token_bytes(16)
        auth = {"authorization": f"Bearer {token}", "content-type": "application/json"}
        status, body, _ = call(
            "POST", f"{api}/api/uploads", headers=auth,
            body=json.dumps({"purpose": "media", "mime": "audio/mpeg", "size": len(payload)}).encode(),
        )
        assert status == 201, f"create upload failed: {status} {body[:200]!r}"
        ticket = json.loads(body)
        object_key = ticket["objectKey"]
        print(f"3. upload ticket issued ({ticket['method']})")

        status, _, _ = call("PUT", ticket["url"], headers=ticket["headers"], body=payload)
        assert status == 200, f"PUT to R2 failed: {status}"
        print("4. bytes stored in R2 via presigned URL")

        status, _, _ = call("PUT", ticket["url"], headers={"content-type": "text/html"}, body=payload)
        assert status == 403, f"R2 accepted a different content type: {status}"
        print("5. presigned URL refuses a different content type")

        status, body, _ = call("POST", f"{api}/api/uploads/{ticket['uploadId']}/complete", headers=auth, body=b"{}")
        assert status == 200 and json.loads(body)["verified"], f"complete failed: {status}"
        print("6. upload verified by the Worker")

        status, body, headers = call("GET", f"{api}/{object_key}", headers={"range": "bytes=0-4"})
        assert status == 206 and body == payload[:5], f"media range failed: {status}"
        print("7. media served back with byte ranges")

        status, body, _ = call("GET", f"{api}/api/geo/search?q=Tabriz", headers=auth)
        results = json.loads(body).get("results", []) if status == 200 else []
        assert results, f"place search failed: {status}"
        with_area = next((r for r in results if r["hasBoundary"]), None)
        print(f"8. place search works ({len(results)} results)")
        if with_area:
            status, body, _ = call(
                "GET", f"{api}/api/geo/boundary?osm_type={with_area['osmType']}&osm_id={with_area['osmId']}",
                headers=auth,
            )
            assert status in (200, 404), f"boundary failed: {status}"
            kind = json.loads(body).get("geojson", {}).get("type") if status == 200 else "none"
            print(f"9. boundary lookup works ({with_area['name']}: {kind})")
        return 0
    finally:
        if object_key:
            boto3.client(
                "s3", endpoint_url=config.r2_endpoint, region_name="auto",
                aws_access_key_id=config.r2_access_key_id, aws_secret_access_key=config.r2_secret_access_key,
            ).delete_object(Bucket=config.r2_bucket, Key=object_key)
        status, _, _ = call("DELETE", f"{config.supabase_url}/auth/v1/admin/users/{user_id}", headers=service)
        print(f"cleanup: object removed, temporary user deleted ({status})")


if __name__ == "__main__":
    raise SystemExit(main())
