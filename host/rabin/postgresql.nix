{ config, lib, pkgs, ... }:
let
  cfg = config.services.postgresql;

  # The major version this host is moving *to*. GitLab 19 in nixpkgs asserts
  # PostgreSQL >= 17, and the cluster here was created at 16 (the default for
  # `stateVersion = "25.05"`), so the upgrade has to happen before nixpkgs is
  # bumped past GitLab 19.2 — see `docs/postgresql-upgrade.md`.
  newPostgres = pkgs.postgresql_17.withPackages (_: [ ]);
in
{
  # Pinned explicitly rather than left to follow `stateVersion`, so the major
  # version of the on-disk cluster is a visible, deliberate line in the config.
  # Bump this only after running `upgrade-pg-cluster` on the host.
  services.postgresql.package = pkgs.postgresql_16;

  # The NixOS manual's `pg_upgrade` wrapper
  # (https://nixos.org/manual/nixos/stable/#module-services-postgres-upgrading),
  # carrying this host's `initdbArgs` and extensions (none today) into the new
  # cluster. It stops PostgreSQL itself; stop its clients first.
  environment.systemPackages = [
    (pkgs.writeScriptBin "upgrade-pg-cluster" ''
      set -eux
      systemctl stop postgresql

      export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"
      export NEWBIN="${newPostgres}/bin"

      export OLDDATA="${cfg.dataDir}"
      export OLDBIN="${cfg.finalPackage}/bin"

      install -d -m 0700 -o postgres -g postgres "$NEWDATA"
      cd "$NEWDATA"
      sudo -u postgres "$NEWBIN/initdb" -D "$NEWDATA" ${lib.escapeShellArgs cfg.initdbArgs}

      sudo -u postgres "$NEWBIN/pg_upgrade" \
        --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
        --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
        "$@"
    '')
  ];
}
