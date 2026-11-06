# How to use your own images and environment variables

This guide shows you how to run your own backend or frontend image, for example one with add-ons, and how to set environment variables of the images.

## Use your own backend image

Set `backend.image.repository` and `backend.image.tag`.
The tag defaults to the `appVersion` of the chart.

```yaml
backend:
  image:
    repository: registry.example.com/my-plone-backend
    tag: "1.0.0"
```

## Use your own frontend image

To run your own Volto project, set `frontend.image.repository` and `frontend.image.tag`.

```yaml
frontend:
  image:
    repository: registry.example.com/my-volto-frontend
    tag: "1.0.0"
```

## Set environment variables

The `env` lists of the backend and the frontend add environment variables to their containers:

```yaml
backend:
  env:
    - name: ZOPE_FORM_MEMORY_LIMIT
      value: 8MB
```

For the variables that each image supports, see the documentation of the images:

* [`plone-backend` image](https://6.docs.plone.org/install/containers/images/backend.html)
* [`plone-frontend` image](https://6.docs.plone.org/install/containers/images/frontend.html)
* [`plone-zeo` image](https://6.docs.plone.org/install/containers/images/zeo.html)

The chart sets the variables for the storage and for the site itself, see [Backend](../reference/backend.md) and [Frontend](../reference/frontend.md).
