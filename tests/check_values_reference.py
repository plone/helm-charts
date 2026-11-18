"""Check that docs/reference/values.md documents charts/plone/values.yaml.

Run by ``make docs-values``. It fails when:

* a value of ``values.yaml`` has no row in the reference, itself or one of
  its parents;
* a row of the reference names a key that ``values.yaml`` doesn't have,
  unless its default is "not set", for keys that are only commented out;
* a row has the default "not set", but ``values.yaml`` sets the key;
* ``values.schema.json`` refuses a key that the reference documents, such
  as one that is only commented out in ``values.yaml``;
* the default of a row, when written as YAML in backticks, differs from the
  value in ``values.yaml``. A default written in words, such as "a
  preference for pod anti-affinity by node", isn't compared.
"""

import json
import pathlib
import re
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
VALUES = ROOT / "charts/plone/values.yaml"
REFERENCE = ROOT / "docs/reference/values.md"
SCHEMA = ROOT / "charts/plone/values.schema.json"
ROW = re.compile(r"^\| `(?P<key>[A-Za-z0-9_.]+)` \| (?P<default>.*?) \| .* \|$")
MISSING = object()


def leaves(value: object, path: str = "") -> list[str]:
    """Return the paths of the values that aren't non-empty mappings.

    :param value: a value of ``values.yaml``.
    :param path: the path of ``value``.
    :returns: the dotted paths of its leaves.
    """
    if isinstance(value, dict) and value:
        result = []
        for key, child in value.items():
            result.extend(leaves(child, f"{path}.{key}" if path else key))
        return result
    return [path]


def lookup(values: dict, path: str) -> object:
    """Return the value at a dotted path, or ``MISSING``."""
    value: object = values
    for part in path.split("."):
        if not isinstance(value, dict) or part not in value:
            return MISSING
        value = value[part]
    return value


def accepted(schema: dict, path: str) -> bool:
    """Return whether the schema accepts a key at a dotted path.

    It follows ``properties``, and accepts the keys under a section that
    doesn't refuse additional properties, such as a Kubernetes object.
    """
    for part in path.split("."):
        properties = schema.get("properties", {})
        if part in properties:
            schema = properties[part]
        elif schema.get("additionalProperties") is False:
            return False
        else:
            return True
    return True


def main() -> int:
    values = yaml.safe_load(VALUES.read_text())
    schema = json.loads(SCHEMA.read_text())
    rows = {}
    for line in REFERENCE.read_text().splitlines():
        match = ROW.match(line)
        if match:
            rows[match["key"]] = match["default"].strip()
    errors = []

    for leaf in leaves(values):
        parts = leaf.split(".")
        if not any(".".join(parts[:n]) in rows for n in range(len(parts), 0, -1)):
            errors.append(f"{leaf}: not documented")

    for key, default in rows.items():
        if not accepted(schema, key):
            errors.append(f"{key}: documented, but values.schema.json refuses it")
        value = lookup(values, key)
        if value is MISSING:
            if default != "not set":
                errors.append(f"{key}: documented, but not in values.yaml")
            continue
        if default == "not set":
            errors.append(f"{key}: documented as not set, values.yaml has {value!r}")
            continue
        literal = re.fullmatch(r"`([^`]*)`", default)
        if literal is None:
            continue
        documented = yaml.safe_load(literal[1])
        if documented != value:
            errors.append(f"{key}: documented default {literal[1]}, values.yaml has {value!r}")

    for error in errors:
        print(error)
    compared = sum(1 for d in rows.values() if re.fullmatch(r"`[^`]*`", d))
    print(
        f"{len(rows)} documented keys, {compared} defaults compared, "
        f"{len(leaves(values))} values in values.yaml, {len(errors)} errors"
    )
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
