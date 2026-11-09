# How to pack the database

This guide shows you how to change when the pack job runs, how much history it keeps, or how to turn it off.
The `<release>-pack` CronJob packs the database regularly, removing old object revisions and unused objects.
It uses `zodbpack` with RelStorage, and `zeopack` with ZEO.

## Change the schedule

The job runs every day at 09:45 by default.
To change it, set `pack.schedule` to a cron expression:

```yaml
pack:
  schedule: "45 9 * * *"
```

## Keep the history of the last days

By default, the job keeps the history of the last 7 days, so that undo works for them.
To keep more or less history, set `pack.days`.
A value of `0` removes all of the history:

```yaml
pack:
  days: 30
```

Keeping history matters for undo, see [Pack job](../reference/storage.md#pack-job).

## Limit a long pack

The job stops a pack that runs for longer than `pack.activeDeadlineSeconds`, 23 hours by default, and retries a failed pack `pack.backoffLimit` times, once by default.
Keep `pack.activeDeadlineSeconds` below the interval of `pack.schedule`, so that a stuck pack doesn't block the next one:

```yaml
pack:
  schedule: "45 9 * * *"
  activeDeadlineSeconds: 82800
  backoffLimit: 1
```

## Turn packing off

To turn packing off, set `pack.enabled` to `false`.
Do this when the database is packed elsewhere, for example on an external ZEO server.
