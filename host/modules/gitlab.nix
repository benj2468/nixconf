{ pkgs, inputs, hostname, config, ... }:
{
  age.secrets = {
    gitlab-db = {
      file = "${inputs.self}/secrets/${hostname}-gitlab-db.age";
      owner = "gitlab";
      group = "gitlab";
    };
    # TODO(bjc) Change this to the name of the shell one
    gitlab-runners-tokens = {
      file = "${inputs.self}/secrets/${hostname}-gitlab-runners-tokens.age";
      owner = "gitlab";
      group = "gitlab";
    };
  };

  services.gitlab-runner = {
    enable = true;
    prometheusListenAddress = "0.0.0.0:9252";
    settings.log_level = "debug";
    services = {
      shell = {
        authenticationTokenConfigFile = config.age.secrets.gitlab-runners-tokens.path;
        executor = "shell";
      };
    };
  };

  services.gitlab = {
    enable = true;
    databasePasswordFile = config.age.secrets.gitlab-db.path;
    # This is moot since we change it...
    initialRootPasswordFile = pkgs.writeText "rootPassword" "dakqdvp4ovhksxer";
    statePath = "/home/gitlab";
    host = "git.${hostname}";
    port = 80;
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
