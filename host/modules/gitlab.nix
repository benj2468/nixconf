{ lib, pkgs, inputs, hostname, config, ... }:
{
  options.haganah.gitlab = {
    enable = lib.mkEnableOption "Enable Opinionated Gitlab Server";

    # TODO: Also permit runners to be configurable
  };

  config = lib.mkIf config.haganah.gitlab.enable {
    age.secrets = {
      gitlab-db = {
        file = "${inputs.self}/secrets/${hostname}-gitlab-db.age";
        owner = "gitlab";
        group = "gitlab";
      };
      gitlab-runner-1-tokens = {
        file = "${inputs.self}/secrets/${hostname}-gitlab-runner-1-tokens.age";
        owner = "gitlab";
        group = "gitlab";
      };
    };

    environment.systemPackages = with pkgs; [
      gitlab-runner
    ];

    services.prometheus = {
      scrapeConfigs = [
        {
          job_name = "gitlab-runner";
          static_configs = [
            {
              targets = [ "localhost:9252" ];
            }
          ];
        }
      ];
    };

    services.gitlab-runner = {
      enable = true;
      settings = {
        log_level = "debug";
        listen_address = "0.0.0.0:9252";
      };
      services = {
        shell = {
          authenticationTokenConfigFile = config.age.secrets.gitlab-runner-1-tokens.path;
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
  };
}
