import boto3
from botocore.stub import Stubber

from naney_admin.adapters.r2_store import R2MediaStore


def make_store() -> tuple[R2MediaStore, Stubber]:
    client = boto3.client(
        "s3",
        endpoint_url="https://acc.r2.cloudflarestorage.com",
        region_name="auto",
        aws_access_key_id="id",
        aws_secret_access_key="secret",
    )
    return R2MediaStore(client, bucket="naney-media"), Stubber(client)


def test_put_sets_the_content_type() -> None:
    store, stubber = make_store()
    stubber.add_response(
        "put_object",
        {},
        {
            "Bucket": "naney-media",
            "Key": "media/a.mp3",
            "Body": b"abc",
            "ContentType": "audio/mpeg",
        },
    )
    with stubber:
        store.put("media/a.mp3", b"abc", "audio/mpeg")
    stubber.assert_no_pending_responses()


def test_delete() -> None:
    store, stubber = make_store()
    stubber.add_response("delete_object", {}, {"Bucket": "naney-media", "Key": "media/a.mp3"})
    with stubber:
        store.delete("media/a.mp3")
    stubber.assert_no_pending_responses()
