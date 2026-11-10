"""Create, or check, the content of the upgrade test, with the REST API.

Run inside a backend pod, by tests/upgrade.sh::

    python - create|check <admin password> < tests/upgrade_content.py

``create`` adds a page and a file, whose data is a blob. ``check`` reads
them back, and fails if they differ.

Only the Python standard library is used, so that the script runs with the
Python of the ``plone-backend`` image.
"""

import base64
import json
import sys
import urllib.error
import urllib.request


SITE = "http://localhost:8080/Plone"
TITLE = "Upgrade test"
BLOB = b"A blob that must survive the upgrade.\n"


def request(path: str, password: str, body: dict | None = None, raw: bool = False):
    """Send a request to the site as the ``admin`` user.

    :param path: path below the site.
    :param password: password of the ``admin`` user.
    :param body: JSON body, sent with POST.
    :param raw: return the body as bytes, instead of decoded JSON.
    :returns: the decoded JSON, or the bytes of the body.
    """
    credentials = base64.b64encode(f"admin:{password}".encode()).decode()
    headers = {"Authorization": f"Basic {credentials}", "Accept": "application/json"}
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode()
    req = urllib.request.Request(f"{SITE}{path}", data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=60) as response:
        content = response.read()
    return content if raw else json.loads(content)


def create(password: str) -> None:
    request("/", password, {
        "@type": "Document",
        "id": "upgrade-test",
        "title": TITLE,
    })
    request("/", password, {
        "@type": "File",
        "id": "upgrade-file",
        "title": "Upgrade file",
        "file": {
            "data": base64.b64encode(BLOB).decode(),
            "encoding": "base64",
            "filename": "upgrade.txt",
            "content-type": "text/plain",
        },
    })
    print("Created the page /upgrade-test and the file /upgrade-file")


def check(password: str) -> None:
    title = request("/upgrade-test", password)["title"]
    assert title == TITLE, f"the page has the title {title!r}"
    data = request("/upgrade-file/@@download/file", password, raw=True)
    assert data == BLOB, f"the file has the data {data!r}"
    print("The page and the blob of the file are unchanged")


if __name__ == "__main__":
    action, admin_password = sys.argv[1], sys.argv[2]
    try:
        {"create": create, "check": check}[action](admin_password)
    except (AssertionError, urllib.error.URLError) as error:
        sys.exit(f"Upgrade content check failed: {error}")
