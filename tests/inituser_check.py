"""Run the script of the ``admin-password`` init container with test passwords.

The unit tests of the chart can only compare the text of the script. This
check renders the backend Deployment, extracts the script, and runs it with
``/bin/sh`` for passwords that the ``inituser`` file of Zope can and can't
hold, so that a wrong ``case`` pattern fails.

Usage: ``python3 tests/inituser_check.py [chart directory]``
"""

import os
import subprocess
import sys
import tempfile

CHART = sys.argv[1] if len(sys.argv) > 1 else "charts/plone"

# Password, and whether the init container accepts it.
CASES = [
    ("s3cret", True),
    ("with inner spaces", True),
    ("100%s-and-\\n", True),
    ("$(touch pwned)", True),
    ("", False),
    ("a:b", False),
    (":", False),
    (" leading", False),
    ("trailing ", False),
]


def init_script() -> str:
    """Return the script of the ``admin-password`` init container.

    :returns: the shell script, with the path of ``inituser`` as rendered.
    """
    manifest = subprocess.run(
        [
            "helm", "template", "plone", CHART,
            "--kube-version", "1.37.0",
            "--set", "routing.gateway.name=gw",
            "--show-only", "templates/backend-deployment.yaml",
        ],
        check=True, capture_output=True, text=True,
    ).stdout.splitlines()
    start = next(i for i, line in enumerate(manifest) if line.strip() == "- name: admin-password")
    block = next(i for i in range(start, len(manifest)) if manifest[i].strip() == "- |")
    indent = len(manifest[block]) - len(manifest[block].lstrip()) + 2
    lines = []
    for line in manifest[block + 1:]:
        if line.strip() and len(line) - len(line.lstrip()) < indent:
            break
        lines.append(line[indent:])
    return "\n".join(lines) + "\n"


def main() -> int:
    script = init_script()
    assert "/admin/inituser" in script, "the script no longer writes /admin/inituser"
    failures = 0
    with tempfile.TemporaryDirectory() as tmp:
        target = os.path.join(tmp, "inituser")
        local = script.replace("/admin/inituser", target)
        for password, accepted in CASES:
            if os.path.exists(target):
                os.remove(target)
            result = subprocess.run(
                ["/bin/sh", "-c", local], cwd=tmp, capture_output=True, text=True,
                env={"PATH": os.environ["PATH"], "ADMIN_PASSWORD": password},
            )
            if accepted:
                written = open(target).read() if os.path.exists(target) else None
                ok = result.returncode == 0 and written == f"admin:{password}\n"
            else:
                ok = result.returncode != 0 and not os.path.exists(target)
            if os.path.exists(os.path.join(tmp, "pwned")):
                ok = False
            print(f"{'ok  ' if ok else 'FAIL'} {password!r}: {'accepted' if accepted else 'refused'}")
            failures += not ok
    print(f"{len(CASES) - failures} of {len(CASES)} passwords handled as expected")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
