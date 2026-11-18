---
myst:
  html_meta:
    "description": "Documentation of the Helm chart that installs Plone 6 on Kubernetes"
    "property=og:description": "Documentation of the Helm chart that installs Plone 6 on Kubernetes"
    "property=og:title": "Plone Helm chart"
    "keywords": "Plone, Helm, Kubernetes, Volto, CloudNativePG, Gateway API"
---

# Plone Helm chart

The `plone` Helm chart installs [Plone 6](https://6.docs.plone.org/) on Kubernetes.
Version {{ chart_version }} of the chart installs Plone {{ plone_version }} by default.

These pages follow the [Diátaxis](https://diataxis.fr) framework, so that each page does one job.
If you install Plone on Kubernetes for the first time, start with the tutorial.

(beta)=

:::{warning}
The chart is in beta.
Its defaults install a minimal site, with one PostgreSQL instance, one backend, and one frontend, and no backups.
These aren't covered yet:

* backups and their restore, for [PostgreSQL](https://github.com/plone/helm-charts/issues/48) and [ZEO](https://github.com/plone/helm-charts/issues/49)
* [upgrades](https://github.com/plone/helm-charts/issues/55) of the chart and of Plone
* a [guide for production](https://github.com/plone/helm-charts/issues/54)

Until 1.0, a minor version of the chart can bring changes that need action when you upgrade.
:::

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 🎓 Tutorials
:link: tutorials/index
:link-type: doc

Take a first installation from start to finish, step by step.
:::

:::{grid-item-card} 🛠️ How-to guides
:link: how-to/index
:link-type: doc

Solve a specific task, such as serving the site over HTTPS, or adding Varnish.
:::

:::{grid-item-card} 📖 Reference
:link: reference/index
:link-type: doc

Look up the values, the components, and the resources of the chart.
:::

:::{grid-item-card} 💡 Explanation
:link: explanation/index
:link-type: doc

Understand how the parts work together, and why the chart is built this way.
:::

::::

## Helm repository

The chart is published in the Helm repository at this same address:

```shell
helm repo add plone https://plone.github.io/helm-charts
helm repo update
helm search repo plone
```

The source of the chart and of this documentation is in the [`plone/helm-charts`](https://github.com/plone/helm-charts) repository.

```{toctree}
:hidden: true
:maxdepth: 2

tutorials/index
how-to/index
reference/index
explanation/index
```
