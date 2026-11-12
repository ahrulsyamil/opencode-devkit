# Backup and restore

The persisted OpenCode v2 data volume may contain authentication tokens in its SQLite database. Treat any archive containing this directory as a secret.

## Backup

```bash
make backup
```

This **stops** the service first to improve SQLite consistency and archives six persistent volumes into a `backups/devkit-<UTC timestamp>.tar.gz` file with private permissions. The service remains stopped after backup: run `make up` to start it again.

**Not included:** source code under the bind-mounted workspace (`WORKSPACE_DIR`), `.env`, SSH keys provided through an optional override, and other host paths. Back those up separately using your preferred encrypted backup provider.

## Restore

```bash
make restore FILE=backups/devkit-20261112T000000Z.tar.gz
```

The script rejects obvious unsafe paths, symlinks, and special files; it asks you to type `RESTORE`, stops the service and extracts the archive into the named volumes. Only restore backups you trust. For a truly clean rollback, initialize empty volumes first under a separately named Compose project. Existing files not present in the backup are not deleted automatically. Then `make up`, `make smoke`, and manually inspect your OpenCode projects and credentials.

## Disaster recovery considerations

- Restore the *same* `.env` password and UID/GID as the original deployment when possible.
- Restore the host workspace separately to avoid dangling project references.
- A volume is not an offsite backup. Schedule encrypted backups and test restoration regularly.
- Docker volume names include the Compose project name; changing it creates a fresh set of volumes unless you migrate them explicitly.
