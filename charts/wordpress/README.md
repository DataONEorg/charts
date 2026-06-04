# WordPress + MariaDB Helm Chart

Minimal chart to deploy WordPress and its database dependency, MariaDB (e.g. at https://arcticdata.io/ or https://wp.test.dataone.org).

> [!NOTE]
> This chart is intended to be a simple, maintainable solution for deploying the arcticdata.io and test.arcticdata.io WordPress sites. It therefore contains some hard-coded values by design, and is not intended to be a generic chart that is re-usable in other contexts (but can be used as a starting point if needed).


## Upgrade policy

- The admin UI will show a warning if the WordPress version is out of date.
- WordPress core updates are disabled in the UI (manual and automatic).
- Upgrade WordPress and MariaDB only by changing image versions in values overrides (`wordpress.image.tag` and/or `mariadb.image.tag`) and running `helm upgrade`.
- Plugin updates and Theme editing can be done in the WordPress admin UI.


## Find latest image versions

> [!IMPORTANT]
> Before upgrading, always check the upgrade notes for both products! Be especially careful with major version changes, which may include breaking changes to the DB schema and/or `wp-content` files.

- WordPress:
  - image tags: https://hub.docker.com/_/wordpress?tab=tags
  - release notes: https://wordpress.org/news/category/releases/
- MariaDB
  - image tags: https://hub.docker.com/_/mariadb?tab=tags
  - upgrade notes (major/minor specifics): https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/upgrading/upgrading-from-to-specific-versions


## Deployment Notes

1. If you are running only ONE WP pod (`replicaCount: 1`), ensure that:
- `ingress.host` and `adminIngress.host` are set to the same domain
- `podDisruptionBudget.enabled` is set to `false`

2. If you are running 2 OR MORE WP pods (`replicaCount` >1), ensure that:
- `ingress.host` and `adminIngress.host` are set to DIFFERENT domains, to avoid issues when editing Themes in Preview Mode
- `podDisruptionBudget.enabled` is set to `true`

3. The chart automatically deletes the default `Akismet` and `Hello Dolly` plugins, and themes named "twentytwenty*", so they don't keep reappearing after every new helm deployment. Override `wordpress.postStart` if you don't want those to be deleted.


## Upgrade steps

1. Take manual backups before upgrade (`wp-content` & DB; see below).
2. Edit image tags in your values file(s):
   - `wordpress.image.tag`
   - `mariadb.image.tag`

> [!CAUTION]
> Your WP site may experience downtime when upgrading MariaDB, since the image automatically runs `mariadb_upgrade` on startup, which may take a few minutes to complete!

3. Run Helm upgrade:

    ```shell
    helm upgrade --install wparctic oci://ghcr.io/dataoneorg/charts/dataone-wordpress-stack \
        -f <values-overrides-file>.yaml -n arctic
    ```

## Manual Backups Before Upgrade

The production cephfs subvolume (`pdg`) is backed up daily - see [K8s Backups Quick Reference](https://github.com/DataONEorg/k8s-cluster/blob/main/admin/backup-summary.md#k8s-backups-quick-reference). This means we have a daily snapshot of the MariaDB data files on disk, and the WordPress `wp-content` files. However, it is best to do a quick manual backups immediately before upgrade, especially if the upgrade includes a major version change:

1. `wp-content` files: copy to a backup directory on the ceph mount:

   ```shell
    # FROM YOUR LOCAL MACHINE:
    # May take 6 minutes or more
    #
    ssh datateam.nceas.ucsb.edu 'sudo tar -czf \
      /mnt/ceph/repos/arctic/wordpress/temp-backups/wp_files_backup_$(date +%Y%m%d_%H%M%S).tgz \
      /mnt/ceph/repos/arctic/wordpress/wp-files'
    ```

2. Database Dump: saves to a file on the ceph mount, inside `/repos/dev/wordpress/mariadb`:

    ```shell
    # FROM YOUR LOCAL MACHINE:
    #
    kubectl exec -it wparctic-mariadb-0 -- bash -c ' \
      mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" arcticadata_wp \
        > /var/lib/mysql/manual_backup_$(date +%Y%m%d_%H%M%S).sql'

    # NOTE it's  arcticadata_wp, not arcticdata_wp!
    ```

## Rollback & Recovery

> [!CAUTION]
> If the failed upgrade changed the DB schema and/or `wp-content`, a `helm rollback` alone is not sufficient!

Safest rollback sequence:
1. (If necessary) Restore DB from pre-upgrade backup/snapshot

    ```shell
    # From inside the mariadb pod:
    mariadb -u root -p"$MARIADB_ROOT_PASSWORD" arcticadata_wp  <  /var/lib/mysql/manual_backup_<date>.sql
   
    # NOTE it's  arcticadata_wp, not arcticdata_wp!
    ```

> [!IMPORTANT]
> If you are copying DB files from another instance instead of using a dump file (e.g. copy from prod to test):
> 1. Make sure the entire directory is owned by UID `999` (the mysql user in the MariaDB container)
> 2. Delete the `tc.log` file in the target `mariadb/data` directory if you see errors about recovery failure and tc log during startup.

2. (If necessary) Restore `wp-content` from pre-upgrade backup/snapshot.

    ```shell
    ssh datateam \
      'sudo tar -xzf /mnt/ceph/repos/arctic/wordpress/temp-backups/wp_files_backup_<date>.tgz -C /'
    ```

> [!IMPORTANT]
> If you are restoring wp-content files from another instance (e.g. copy from prod to test), make sure the entire directory is owned by UID `33` (the www-data user in the WordPress container)

3. Roll back chart/image versions with `helm rollback`:

```shell
helm history <release>  # to find target revision number

helm rollback <release> <target-revision>
```

## Troubleshooting

### WordPress

If you see this in WP admin during update operations:

> Automated WordPress update has failed to complete - please attempt the update again now.
> 
> Update WordPress
> 
> **Another update is currently in progress.**

...and if you are certain another update is currently NOT in progress, the `core_updater.lock` row may be stale. You can remove it from MariaDB by executing this inside the MariaDB pod:

```shell
mariadb -u arcticadata -p arcticadata_wp \
  -e "DELETE FROM wp_options WHERE option_name = 'core_updater.lock';"
# where arcticadata is the username, arcticadata_wp is the DB name, and
# you will be prompted for the password (from the secret)
# NOTE it's arcticadata and arcticadata_wp, not arcticdata/arcticdata_wp!
```

### MariaDB

If you see this in the MariaDB logs during startup, after copying DB files from another instance:

```shell
2026-05-04 21:20:28 0 [Note] Plugin 'FEEDBACK' is disabled.
2026-05-04 21:20:28 0 [Note] Plugin 'wsrep-provider' is disabled.
2026-05-04 21:20:28 0 [Note] InnoDB: Loading buffer pool(s) from /var/lib/mysql/ib_buffer_pool
2026-05-04 21:20:28 0 [Note] Recovering after a crash using tc.log
2026-05-04 21:20:28 0 [ERROR] Recovery failed! You must enable all engines that were enabled at the moment of the crash
1 2026-05-0421:20:20Orashrecovery failed. Either correct the problem fits, for examples out of memory error and restart, or delete to log and start l
erver with --tc-heuristic-recover={commit rollback}
2026-05-04 21:20:28 0 [ERROR] Can't init tc log
2026-05-04 21:20:28 0 [ERROR]
```

Simply delete the `mariadb/data/tc.log` file and restart the pod
