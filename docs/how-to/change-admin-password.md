# How to change the admin password

This guide shows you how to read, set, and change the password of the `admin` user of the Zope root.

The `plone-backend` image comes with an `admin` user whose password is `admin`.
The chart replaces that password with one from a Secret:

* the Job `<release>-admin` sets it after each install and upgrade of the release, also on a site that already exists, such as one installed with an earlier version of the chart;
* on a new database, the backend pods and the Job that creates the site write it to the `inituser` file of Zope, so that the password `admin` never works, even before the site exists.

## Read the generated password

By default, the chart generates a random password on install, into the Secret `<release>-admin`, and keeps it on upgrades.
Read it with:

```shell
kubectl get secret --namespace <namespace> <release>-admin -o jsonpath='{.data.password}' | base64 -d
```

The installation notes of the chart print the same command.

## Use your own Secret

1. Create a Secret with the password:

   ```shell
   kubectl create secret generic plone-admin-password --namespace <namespace> \
       --from-literal=password='<password>'
   ```

2. Set it in your values:

   ```yaml
   site:
     admin:
       existingSecret: plone-admin-password
       # The key of the password in the Secret, password by default.
       passwordKey: password
   ```

3. Install or upgrade the release with these values.

Use your own Secret when you render the chart with `helm template`, or deploy it with a GitOps tool such as Argo CD or Flux.
These tools can't read the Secret already in the cluster, so the chart would generate a new password each time they render it.

The password must not be empty, contain a colon (`:`), or start or end with a space, because of the format of the `inituser` file.
Otherwise the pods don't start, and the log of their `admin-password` init container says why.

Installing or upgrading the release with your own Secret replaces the password of the `admin` user, also on an existing site.

## Change the password

1. Change the password in the Secret, the generated `<release>-admin` or your own.
   The chart keeps a password that you change in `<release>-admin`.

2. Upgrade the release with the same values, so that the Job `<release>-admin` sets the new password:

   ```shell
   helm upgrade <release> plone/plone --namespace <namespace> --reuse-values
   ```

A password that you change in the Zope management interface works until the next install or upgrade of the release, when the Job sets the password of the Secret again.

The Job only changes the `admin` user of the Zope root.
It creates it, with the `Manager` role, if it doesn't exist.
The other users of the Zope root, and the users of the Plone site, in the site's own user folder, are never changed.
