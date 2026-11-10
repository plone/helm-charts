"""Smoke checks of a Plone release, run by ``helm test``.

The chart sets these environment variables:

``PAGE_URL``
    URL of the home page: the frontend with Volto, the backend with the
    Classic UI.
``API_URL``
    URL of the root of the REST API.
``HOST``
    Host header of the requests: the public hostname of the site.
``SITE_URL``
    Public URL of the site, which the API must return as the ``@id`` of the
    site.
``ADMIN_PASSWORD``
    Password of the ``admin`` user.
``UI``
    ``volto``, or ``classic`` for the Classic UI, which has no REST API.
``VARNISH``
    ``true`` when Varnish serves the home page.
``TIMEOUT``
    Seconds to wait for the site to answer the first request.

Only the Python standard library is used, so that the script runs with the
Python of the ``plone-backend`` image.
"""

import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request


ENV = os.environ
HOST = ENV["HOST"]
PAGE_URL = ENV["PAGE_URL"]
API_URL = ENV["API_URL"].rstrip("/")
SITE_URL = ENV["SITE_URL"]
ADMIN_PASSWORD = ENV["ADMIN_PASSWORD"]
VARNISH = ENV.get("VARNISH") == "true"
VOLTO = ENV.get("UI", "volto") == "volto"
TIMEOUT = int(ENV.get("TIMEOUT", "300"))


class NoRedirect(urllib.request.HTTPRedirectHandler):
    """Return redirects as responses, so that the checks can report them."""

    def redirect_request(self, *args, **kwargs):
        return None


OPENER = urllib.request.build_opener(NoRedirect)


def request(
    url: str,
    method: str = "GET",
    body: dict | None = None,
    json_api: bool = False,
    password: str | None = None,
) -> tuple[int, dict, bytes]:
    """Send a request with the Host header of the site.

    :param url: URL to request.
    :param method: HTTP method.
    :param body: JSON body to send.
    :param json_api: send ``Accept: application/json``.
    :param password: password of the ``admin`` user, sent with basic
        authentication.
    :returns: the status, the headers with lower case names, and the body.
    """
    headers = {"Host": HOST}
    if password is not None:
        credentials = base64.b64encode(f"admin:{password}".encode()).decode()
        headers["Authorization"] = f"Basic {credentials}"
    data = None
    if json_api or body is not None:
        headers["Accept"] = "application/json"
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with OPENER.open(req, timeout=30) as response:
            status, raw_headers, content = response.status, response.headers, response.read()
    except urllib.error.HTTPError as error:
        status, raw_headers, content = error.code, error.headers, error.read()
    return status, {k.lower(): v for k, v in raw_headers.items()}, content


def wait_for_site() -> None:
    """Wait until the home page answers, as the routing may still be starting."""
    deadline = time.monotonic() + TIMEOUT
    while True:
        try:
            status = request(PAGE_URL)[0]
        except OSError as error:
            status = error
        if status == 200 or time.monotonic() > deadline:
            return
        print(f"Waiting for {PAGE_URL}: {status}", flush=True)
        time.sleep(5)


def check_page() -> str:
    status, headers, _ = request(PAGE_URL)
    assert status == 200, f"status {status}"
    content_type = headers.get("content-type", "")
    assert content_type.startswith("text/html"), f"content type {content_type!r}"
    return "HTML page"


def check_api() -> str:
    status, _, content = request(f"{API_URL}/", json_api=True)
    assert status == 200, f"status {status}"
    site_id = json.loads(content).get("@id")
    assert site_id == SITE_URL, f"@id is {site_id!r}, expected {SITE_URL!r}"
    return f"@id {site_id}"


def check_portal_url() -> str:
    content = request(PAGE_URL)[2].decode()
    expected = f'data-portal-url="{SITE_URL}"'
    assert expected in content, f"no {expected} in the page"
    return expected


def login(password: str) -> int:
    if VOLTO:
        body = {"login": "admin", "password": password}
        return request(f"{API_URL}/@login", "POST", body)[0]
    # The Classic UI has no REST API: a page that only managers can see.
    return request(f"{API_URL}/@@overview-controlpanel", password=password)[0]


def check_admin_login() -> str:
    status = login(ADMIN_PASSWORD)
    assert status == 200, f"status {status}"
    return "with the password of the Secret"


def check_default_password() -> str:
    if ADMIN_PASSWORD == "admin":
        return "skipped: the password of the Secret is admin"
    status = login("admin")
    # The Classic UI redirects to its login form.
    assert status in (401, 302), f"status {status}"
    return "refused"


def check_varnish() -> str:
    for _ in range(3):
        status, headers, _ = request(PAGE_URL)
        ids = headers.get("x-varnish", "").split()
        if len(ids) == 2:
            return f"cache hit, X-Varnish {' '.join(ids)}"
        time.sleep(1)
    assert ids, "no X-Varnish header: the page doesn't go through Varnish"
    raise AssertionError(f"no cache hit after 3 requests, status {status}")


CHECKS = [
    ("Home page", check_page),
    ("API returns the public URL", check_api)
    if VOLTO
    else ("Page has the public URL", check_portal_url),
    ("admin login", check_admin_login),
    ("admin login with the password admin", check_default_password),
]
if VARNISH:
    CHECKS.append(("Varnish caches the home page", check_varnish))


def main() -> int:
    print(f"Checking {SITE_URL}: page {PAGE_URL}, API {API_URL}", flush=True)
    wait_for_site()
    failures = 0
    for name, check in CHECKS:
        try:
            result = check()
        except (AssertionError, OSError, ValueError) as error:
            failures += 1
            print(f"FAIL {name}: {error}", flush=True)
        else:
            print(f"ok   {name}: {result}", flush=True)
    print(f"{len(CHECKS) - failures} of {len(CHECKS)} checks passed", flush=True)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
