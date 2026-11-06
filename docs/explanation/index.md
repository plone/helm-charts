# Explanation

Explanation pages discuss how the chart works, and why it is built the way it is.

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 🏗️ Architecture
:link: architecture
:link-type: doc

The request flow with Volto and the Classic UI, and the role of Varnish.
:::

:::{grid-item-card} 🔀 The Zope virtual host rewrite
:link: virtual-host-rewrite
:link-type: doc

How Zope learns the public address of the site.
:::

:::{grid-item-card} 🗄️ Storage choices
:link: storage-choices
:link-type: doc

RelStorage on PostgreSQL, ZEO, and packing.
:::

:::{grid-item-card} 🤝 Community charts
:link: community-charts
:link-type: doc

Why the chart depends on the CloudNativePG and Varnish charts.
:::

:::{grid-item-card} 🚦 Gateway API
:link: gateway-api
:link-type: doc

Why the routing uses Gateway API by default.
:::

::::

```{toctree}
:hidden: true

architecture
virtual-host-rewrite
storage-choices
community-charts
gateway-api
```
