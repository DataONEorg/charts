# WordPress + MariaDB Helm Chart

> [!NOTE]
> This chart is intended to be a simple, maintainable solution for deploying the arcticdata.io and test.arcticdata.io WordPress sites. It therefore contains some hard-coded values by design, and is not intended to be a generic chart that is re-usable in other contexts (but can be used as a starting point if needed).

## Upgrade policy

WordPress core updates are disabled in the UI (manual and automatic). Upgrade WordPress and MariaDB only by changing image versions in `values*.yaml` and running `helm upgrade`.

## Find latest image versions

> [!IMPORTANT]
> Before upgrading, always check the upgrade notes for both products! Be especially careful with major version changes, which may include breaking changes to the DB schema and/or `wp-content` files.

- WordPress:
  - image tags: https://hub.docker.com/_/wordpress?tab=tags
  - release notes: https://wordpress.org/news/category/releases/
- MariaDB
  - image tags: https://hub.docker.com/_/mariadb?tab=tags
  - upgrade notes (major/minor specifics): https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/upgrading/upgrading-from-to-specific-versions

## Upgrade steps

1. Take manual backups before upgrade (`wp-content` & DB; see below).
2. Edit image tags in your values file(s):
   - `wordpress.image.tag`
   - `mariadb.image.tag`
3. Run Helm upgrade:

    ```shell
    helm upgrade --install wparctic ./charts/wordpress -n arctic -f <values-overrides-file>.yaml
    ```

## Manual Backups Before Upgrade

The production cephfs subvolume (`pdg`) is backed up daily - see [K8s Backups Quick Reference](https://github.com/DataONEorg/k8s-cluster/blob/main/admin/backup-summary.md#k8s-backups-quick-reference). This means we have a daily snapshot of the MariaDB data files on disk, and the WordPress `wp-content` files. However, it is best to do a quick manual backups immediately before upgrade, especially if the upgrade includes a major version change:

1. `wp-content` files: copy to a backup directory on the ceph mount, inside `/repos/dev/wordpress/wp-content`:

    ```shell
    $ ssh datateam  # (for prod adc) or knbvm (test.adc)
   
    $ sudo sudo rm -rf /mnt/ceph/repos/arctic/wordpress/wp-files/wp-content-backup-deleteme \
          && sudo mkdir -p /mnt/ceph/repos/arctic/wordpress/wp-files/wp-content-backup-deleteme \

    $ sudo cp -a /mnt/ceph/repos/arctic/wordpress/wp-files/wordpress/wp-content \
              /mnt/ceph/repos/arctic/wordpress/wp-files/wp-content-backup-deleteme
    ```

2. Database Dump: saves to a file on the ceph mount, inside `/repos/dev/wordpress/mariadb`:

    ```shell
    kubectl -n arctic exec wparctic-mariadb-0 -- \
        mariadb-dump -u arcticadata -p arcticadata_wp \
        > /var/lib/mysql/db-temp-backup-deleteme.sql
   
    # where arcticadata is the username, arcticadata_wp is the DB name, and
    # you will be prompted for the password (from the secret)
    # NOTE it's arcticadata and arcticadata_wp, not arcticdata/arcticdata_wp!
    ```

## Rollback & Recovery

> [!CAUTION]
> If the failed upgrade changed the DB schema and/or `wp-content`, a `helm rollback` alone is not sufficient!

Safest rollback sequence:
1. (If necessary) Restore DB from pre-upgrade backup/snapshot

    ```shell
    # From inside the mariadb pod:
    mariadb -u arcticadata -p arcticadata_wp  <  /var/lib/mysql/db-temp-backup-deleteme.sql
   
    # where arcticadata is the username, arcticadata_wp is the DB name, and
    # you will be prompted for the password (from the secret)
    # NOTE it's arcticadata and arcticadata_wp, not arcticdata/arcticdata_wp!
    ```

2. (If necessary) Restore `wp-content` from pre-upgrade backup/snapshot.

    ```shell
    $ ssh datateam  # (for prod adc) or knbvm (test.adc)
   
    $ sudo rm -rf /mnt/ceph/repos/arctic/wordpress/wp-files/wordpress/wp-content \
          && sudo cp -a /mnt/ceph/repos/arctic/wordpress/wp-files/wp-content-backup-deleteme \
              /mnt/ceph/repos/arctic/wordpress/wp-files/wordpress/wp-content
    ```

3. Roll back chart/image versions with `helm rollback`:

```shell
helm history <release>  # to find target revision number

helm rollback <release> <target-revision>
```

## Troubleshooting

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
