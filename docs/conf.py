"""Sphinx configuration for the documentation of the Plone Helm chart."""

from datetime import datetime
from pathlib import Path

import re


CHART = Path(__file__).parent.parent / "charts" / "plone" / "Chart.yaml"
_chart = CHART.read_text(encoding="utf-8")


def _chart_field(name: str) -> str:
    """Read a top-level scalar field of the chart's ``Chart.yaml``.

    :param name: Name of the field, such as ``version``.
    :returns: The value of the field, without quotes.
    """
    match = re.search(rf"^{name}:\s*\"?([^\"\n]+)\"?\s*$", _chart, re.MULTILINE)
    if match is None:
        raise ValueError(f"{name} not found in {CHART}")
    return match.group(1).strip()


project = "Plone Helm chart"
author = "Plone Community"
trademark_name = "Plone"
copyright = str(datetime.now().year)  # noqa: A001
# The chart version, and the Plone version it installs by default.
release = _chart_field("version")
version = release
plone_version = _chart_field("appVersion")

templates_path = ["_templates"]

extensions = [
    "myst_parser",
    "notfound.extension",
    "sphinx.ext.intersphinx",
    "sphinx_copybutton",
    "sphinx_design",
    "sphinx_sitemap",
    "sphinxext.opengraph",
]

exclude_patterns = [
    "_build",
    "_styles",
]

# -- MyST -------------------------------------------------------------------

myst_enable_extensions = [
    "attrs_inline",
    "colon_fence",
    "deflist",
    "linkify",
    "substitution",
]
myst_heading_anchors = 3
myst_substitutions = {
    "chart_version": release,
    "plone_version": plone_version,
}

intersphinx_mapping = {
    "plone": ("https://6.docs.plone.org/", None),
}

# -- Link checking ----------------------------------------------------------

linkcheck_ignore = [
    r"http://localhost.*",
    r"http://127\.0\.0\.1.*",
    r"https?://plone\.example\.com.*",
    # Anchors on GitHub are generated client-side.
    r"https://github\.com/.*#.*",
]

# -- HTML output ------------------------------------------------------------

html_theme = "plone_sphinx_theme"
html_logo = "_static/logo.svg"
html_favicon = "_static/favicon.ico"

html_theme_options = {
    "icon_links": [
        {
            "name": "GitHub",
            "url": "https://github.com/plone/helm-charts",
            "icon": "fa-brands fa-square-github",
            "type": "fontawesome",
        },
    ],
    "logo": {"text": "Plone Helm chart"},
    "navigation_with_keys": True,
    "path_to_docs": "docs",
    "repository_branch": "main",
    "repository_url": "https://github.com/plone/helm-charts",
    "search_bar_text": "Search",
    "show_toc_level": 2,
    "use_edit_page_button": True,
    "use_issues_button": True,
    "use_repository_button": True,
}

html_sidebars = {
    "**": [
        "navbar-logo",
        "search-button-field",
        "sbt-sidebar-nav",
    ]
}

html_title = f"{project} {release}"
html_static_path = ["_static"]

# The site is served from a project page, under /helm-charts/, next to the
# index.yaml of the Helm repository.
# The trailing slash matters: sphinxext.opengraph joins page URLs to it with
# urljoin, which drops the last path segment of a base without one.
html_baseurl = "https://plone.github.io/helm-charts/"
sitemap_url_scheme = "{link}"
sitemap_filename = "sitemap-custom.xml"
notfound_urls_prefix = "/helm-charts/"

ogp_site_url = html_baseurl
ogp_site_name = project
