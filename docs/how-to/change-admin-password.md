# How to change the admin password

This guide shows you how to change the password of the `admin` user of the Zope root.
The `plone-backend` image comes with an `admin` user with the password `admin`.
Change it before you expose the site.

1. Forward a local port to the backend:

   ```shell
   kubectl port-forward --namespace <namespace> service/<release>-backend 8080:8080
   ```

2. Open http://localhost:8080/acl_users/manage_main, log in as `admin`, select the `admin` user, and change its password.
