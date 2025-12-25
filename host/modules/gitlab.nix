{ libx, pkgs, inputs, hostname, config, ... }:
{
  options.haganah.gitlab = {
    enable = libx.mkTieredEnableOption config.haganah "Enable Opinionated Gitlab Server";
  };

  config = libx.mkIf config.haganah.gitlab.enable {
    age.secrets = {
      gitlab-runner-1 = {
        file = "${inputs.self}/secrets/${hostname}-gitlab-runner-1.age";
        owner = "gitlab";
        group = "gitlab";
      };
      gitlab-runner-2 = {
        file = "${inputs.self}/secrets/${hostname}-gitlab-runner-2.age";
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
          job_name = "gitaly";
          static_configs = [{
            targets = [ "localhost:9236" ];
          }];
        }
        {
          job_name = "gitlab";
          static_configs = [{
            targets = [ "localhost:9168" ];
          }];
        }
        {
          job_name = "sidekiq";
          static_configs = [{
            targets = [ "localhost:3807" ];
          }];
        }
        {
          job_name = "gitlab-runner";
          static_configs = [{
            targets = [ "localhost:9252" ];
          }];
        }
      ];
    };

    services.gitlab-runner = {
      enable = true;
      settings = {
        listen_address = "0.0.0.0:9252";
      };
      services = {
        default = {
          registrationFlags = [
            "--tls-ca-file ${../modules/step-ca/root.crt}"
          ];
          dockerVolumes = [ "/var/run/docker.sock:/var/run/docker.sock" "/etc/hosts:/etc/hosts" ];
          dockerImage = "nixos/nix";
          authenticationTokenConfigFile = config.age.secrets.gitlab-runner-1.path;
        };
        runner-2 = {
          registrationFlags = [
            "--tls-ca-file ${../modules/step-ca/root.crt}"
          ];
          dockerVolumes = [ "/var/run/docker.sock:/var/run/docker.sock" "/etc/hosts:/etc/hosts" ];
          dockerImage = "nixos/nix";
          authenticationTokenConfigFile = config.age.secrets.gitlab-runner-2.path;
        };
      };
    };

    services.gitlab = {
      enable = true;
      databasePasswordFile = pkgs.writeText "dbPassword" "24HKq$LnVsHqExYL";
      initialRootPasswordFile = pkgs.writeText "rootPassword" "dakqdvp4ovhksxer";
      host = "git.haganah.net";
      port = 443;
      https = true;
      extraConfig = {
        monitoring = {
          sidekiq_exporter = {
            enabled = true;
            address = "localhost";
            port = 3807;
          };
          web_exporter = {
            enabled = true;
            address = "localhost";
            port = 9168;
          };
        };
      };
      secrets = {
        secretFile = pkgs.writeText "secret" "Aig5zaic";
        otpFile = pkgs.writeText "otpsecret" "Riew9mue";
        dbFile = pkgs.writeText "dbsecret" "we2quaeZ";
        jwsFile = pkgs.runCommand "oidcKeyBase" { } "${pkgs.openssl}/bin/openssl genrsa 2048 > $out";
        activeRecordSaltFile = pkgs.writeText "salt" "5n*FfqwjVCQXdYa^";
        activeRecordPrimaryKeyFile = pkgs.writeText "key" "x%8wKLT1pK@aq9Qw";
        activeRecordDeterministicKeyFile = pkgs.writeText "key" "j&eekrQB!335XpvK";
      };
    };

    services.openssh.enable = true;

    systemd.services.gitlab-backup.environment.BACKUP = "dump";
  };
}
