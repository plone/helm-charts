# How to change the admin password

This guide shows you how to read, set, and change the password of the `admin` user of the Zope root.

The `plone-backend` image comes with an `admin` user whose password is `admin`.
The chart replaces that password with one from a Secret: each backend pod, and the Job that creates the site, write it to the `inituser` file of Zope when they start, and Zope applies it.

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

## Change the password

1. Change the password in the Secret, the generated `<release>-admin` or your own.
   The chart keeps a password that you change in `<release>-admin`.

2. Restart the backend pods, which apply the password when they start:

   ```shell
   kubectl rollout restart --namespace <namespace> deployment/<release>-backend
   ```

## When the password doesn't apply

Zope replaces the `admin` user from the `inituser` file only while the Zope root has no other user.
If you add users to the Zope root, in `/acl_users` of the Zope management interface, the chart no longer sets the password.
Manage the passwords of the Zope root users there instead, and keep the `admin` user: the Job that creates the site runs as `admin`.

The users of the Plone site itself, in the site's own user folder, don't count, and the chart never changes them.
