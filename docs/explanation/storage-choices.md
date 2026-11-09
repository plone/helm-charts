# About the storage choices

Plone stores its content in the ZODB, an object database.
The chart offers two ways to store the ZODB: RelStorage on PostgreSQL, the default, and a ZEO server.
Both keep the same content, so the choice is about operations, not about the data model.
For the values of each choice, see [Storage](../reference/storage.md).

## RelStorage on PostgreSQL

RelStorage stores the objects and the blobs in a PostgreSQL database.
The database is a server that most operators already know how to back up, replicate, and monitor.
With the CloudNativePG operator, the chart runs it as a cluster, which can fail over when you run more instances.

Each backend pod connects to the database and only keeps a cache, so the backend pods don't hold any data of their own.
This allows several backend pods, which all read the same database.

RelStorage is the choice for new sites, and the default of the chart.

## ZEO

ZEO runs a storage server, which owns the data file of the ZODB.
The backend pods are its clients, and they reach the content through the server.
Only one server can own the data file, so the ZEO server is a single pod, which can't be replicated.
The backend pods can still scale, because each of them is a client of the same server.

The chart keeps the data of the ZEO server in a persistent volume, and packs it with `zeopack`.
ZEO is the choice for a site that already runs on ZEO, or that you want to move to Kubernetes as it is.
It doesn't need PostgreSQL, so it has fewer components to run.

## Packing

Both storage types keep the old revisions of the objects until they are packed.
The revisions make the undo of older changes possible, and they take space.
Packing removes the revisions that you no longer need, and the `pack.days` value decides how many days of history to keep.

The pack job runs every day by default, and keeps the history of the last 7 days.
If you need undo over a longer period, keep more days, and expect the database to grow.
For how to change the job, see [How to pack the database](../how-to/pack-the-database.md).
