{ pkgs, ... }:
{
  # Pinned explicitly rather than left to follow `stateVersion`, so the major
  # version of the on-disk cluster is a visible, deliberate line. The module
  # derives `dataDir` (/var/lib/postgresql/<major>) from this, so bumping it
  # without first running `pg_upgrade` starts an empty cluster: see the NixOS
  # manual's "Upgrading" section for services.postgresql. GitLab 19 needs >= 17.
  services.postgresql.package = pkgs.postgresql_17;
}
