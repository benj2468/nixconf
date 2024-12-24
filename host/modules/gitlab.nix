{ pkgs, inputs, hostname, config, ... }:
{
  age.secrets = {
    gitlab-db = {
      file = "${inputs.self}/secrets/${hostname}-gitlab-db.age";
      owner = "gitlab";
      group = "gitlab";
      mode = "400";
    };
  };

  services.gitlab = {
    enable = true;
    databasePasswordFile = config.age.secrets.gitlab-db.path;
    # This is moot since we change it...
    initialRootPasswordFile = pkgs.writeText "rootPassword" "dakqdvp4ovhksxer";
    statePath = "/home/gitlab";
    secrets = {
      # TODO(bjc) We should change these to also to secrets
      secretFile = pkgs.writeText "secret" "Aig5zaic";
      otpFile = pkgs.writeText "otpsecret" "Riew9mue";
      dbFile = pkgs.writeText "dbsecret" "we2quaeZ";
      jwsFile = pkgs.runCommand "oidcKeyBase" { } "${pkgs.openssl}/bin/openssl genrsa 2048 > $out";
    };
  };

  services.openssh.enable = true;

  systemd.services.gitlab-backup.environment.BACKUP = "dump";
}
