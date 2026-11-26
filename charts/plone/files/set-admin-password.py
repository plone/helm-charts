"""Set the password of the ``admin`` user of the Zope root.

Run with ``zconsole run`` by the Job ``<release>-admin``, after each install
and upgrade of the chart, with the password in ``ADMIN_PASSWORD``.

Zope applies the ``inituser`` file only while the Zope root has its own user
folder. Creating a Plone 6 site replaces it with a PluggableAuthService, which
ignores ``inituser``: this script sets the password in either.
"""

import os
import sys

import transaction
from Acquisition import aq_base

USER = "admin"


def main(app) -> None:
    password = os.environ.get("ADMIN_PASSWORD", "")
    if not password:
        sys.exit("ADMIN_PASSWORD is empty")
    user_folder = app.acl_users
    if hasattr(aq_base(user_folder), "_createInitialUser"):
        # The user folder of Zope, before a Plone site is created.
        if USER in user_folder.getUserNames():
            user = user_folder.getUser(USER)
            user_folder._doChangeUser(USER, password, user.getRoles(), user.getDomains())
        else:
            user_folder._doAddUser(USER, password, ("Manager",), ())
    else:
        # A PluggableAuthService, with the users and roles of the Zope root.
        users = user_folder.users
        if USER in users.listUserIds():
            users.updateUserPassword(USER, password)
        else:
            users.addUser(USER, USER, password)
            user_folder.roles.assignRoleToPrincipal(USER, "Manager")
    transaction.commit()
    print(f"Set the password of the {USER} user of the Zope root")


main(app)  # noqa: F821, app is set by zconsole run
