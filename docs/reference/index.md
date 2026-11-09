# Reference

Reference pages describe the chart: its values, its components, and the resources it creates.

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 🎛️ Values
:link: values
:link-type: doc

Every value, with its default and its meaning, and the validation rules.
:::

:::{grid-item-card} 🐍 Backend
:link: backend
:link-type: doc

The resources, environment variables, and probes of the backend.
:::

:::{grid-item-card} 🌐 Frontend
:link: frontend
:link-type: doc

The resources, environment variables, and probes of the Volto frontend.
:::

:::{grid-item-card} 🗄️ Storage
:link: storage
:link-type: doc

RelStorage, the PostgreSQL cluster, the ZEO server, and the pack job.
:::

:::{grid-item-card} ⚡ Varnish
:link: varnish
:link-type: doc

The resources, affinity, and default VCL of Varnish.
:::

:::{grid-item-card} 🧭 Routing
:link: routing
:link-type: doc

The routing types, the HTTPRoute and Ingress rules, and the virtual host paths.
:::

:::{grid-item-card} 📋 Resources by scenario
:link: scenario-resources
:link-type: doc

The resources that each scenario creates.
:::

:::{grid-item-card} 🏷️ Naming conventions
:link: naming
:link-type: doc

The names, ports, and labels of the resources.
:::

::::

```{toctree}
:hidden: true

values
backend
frontend
storage
varnish
routing
scenario-resources
naming
```
