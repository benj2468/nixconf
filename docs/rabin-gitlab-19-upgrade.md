# rabin: PostgreSQL 16 → 17 and GitLab 18.11 → 19.3

Why this is a runbook and not just a lock bump:

- **GitLab 19 in nixpkgs asserts PostgreSQL >= 17.** rabin's cluster is 16
  (the `stateVersion = "25.05"` default), and a major version change of the
  cluster needs `pg_upgrade`, which no activation script runs for you.
- **GitLab's required upgrade stops are 18.11 → 19.2 → 19.5.** rabin is on
  18.11.7, so it must run **19.2.x** and let that version's batched
  background migrations finish **before** going to 19.3.
- The same cluster holds `tandoor_recipes`; the upgrade moves it too.

Each step below is one commit on this branch. Deploy them **in order**, and
check each one before the next. The deploy command is whatever you normally
use, for example `nixos-rebuild switch --flake .#rabin` on rabin, or with
`--target-host`, at that commit.

## Step A: `d4c3c3e` + `30f4052` (still GitLab 18.11.7, PostgreSQL 16)

These commits add the `upgrade-pg-cluster` script and cap CI (`concurrent = 3`,
with job containers in `ci.slice`). Deploy the second commit, `30f4052`.
Nothing else changes; the runners re-register with the new flag by
themselves.

## Step B: `e6a71bf` (PostgreSQL 17)

On rabin, as root:

```sh
# 1. A logical backup you can restore into any version.
sudo -u postgres pg_dumpall > /root/pg16-$(date +%F).sql

# 2. Stop everything that talks to the database.
systemctl stop gitlab-runner tandoor-recipes gitlab.target
systemctl list-units --state=active 'gitlab*' 'tandoor*'   # expect none

# 3. Free disk: pg_upgrade copies the data (add --link to hard-link instead,
#    which is faster but makes the old cluster unusable once 17 starts).
du -sh /var/lib/postgresql/16 && df -h /var/lib/postgresql

# 4. Upgrade. This stops postgresql itself.
upgrade-pg-cluster
```

Then deploy `e6a71bf`. It points the module at
`/var/lib/postgresql/17`, and GitLab and Tandoor start on the new cluster.

- **Don't** deploy it before step 4. The module would start an empty
  cluster.
- Follow up with what `pg_upgrade` printed: typically
  `sudo -u postgres vacuumdb --all --analyze-in-stages`.

**Check:**
- GitLab signs in, a project page loads, and a CI job runs.
- Recipes load.
- `sudo -u postgres psql -c 'select version()'` says 17.

Keep `/var/lib/postgresql/16` until you're sure. After that,
`/var/lib/postgresql/17/delete_old_cluster.sh` (written by `pg_upgrade`)
removes it.

## Step C: `4103adf` (GitLab 19.2.4)

Deploy it. GitLab runs its migrations on start. Then **wait until the
batched background migrations are finished**:

- Admin area → Monitoring → Background migrations, where everything should
  be *Finished*/*Finalized*; or
- `sudo gitlab-rails runner 'puts Gitlab::Database::BackgroundMigration::BatchedMigration.queued.count'`,
  which should print `0`.

This can take minutes to hours. Don't start step D until it's done.

## Step D: `c0b2f75` (GitLab 19.3.3, latest nixos-unstable)

Deploy it. This is the nixpkgs update you originally wanted.

## If something goes wrong

- **Before step B's deploy:** the old cluster is untouched (unless you used
  `--link` and started 17). Revert to the step-A generation
  (`nixos-rebuild switch --rollback`) and start the services again.
- **After it:** roll back the generation. GitLab migrations don't go
  backwards, so a rollback past step C means restoring the step-B dump and
  the GitLab data backup, not just the generation. Take a GitLab backup
  (`sudo gitlab-rake gitlab:backup:create`) before step C if you want that
  option.
