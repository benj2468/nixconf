{ libx, lib, pkgs, inputs, hostname, config, ... }:
let
  dockerRunnerCount = config.haganah.gitlab.dockerRunnerCount;

  mkDockerSecrets = count: if count == 0 then { } else
  ((mkDockerSecrets (count - 1)) // {
    "gitlab-runner-${toString count}" = {
      file = "${inputs.self}/secrets/${hostname}-gitlab-runner-${toString count}.age";
      owner = "gitlab";
      group = "gitlab";
    };
  });
  mkDockerRunners = count: if count == 0 then { } else
  ((mkDockerRunners (count - 1)) // {
    "runner-docker-${toString count}" = {
      registrationFlags = [
        "--tls-ca-file ${../modules/step-ca/root.crt}"
        # Every job container lands in `ci.slice` (below), which caps what CI
        # can take from the GitLab server it shares this host with.
        "--docker-cgroup-parent ci.slice"
      ];
      dockerVolumes = [
        "/sccache:/sccache"
        "/var/run/docker.sock:/var/run/docker.sock"
        "/etc/hosts:/etc/hosts"
      ];
      dockerImage = "docker:latest";
      dockerDisableCache = true;
      authenticationTokenConfigFile = config.age.secrets."gitlab-runner-${toString count}".path;
    };
  });
in
{
  options.haganah.gitlab = {
    enable = libx.mkTieredEnableOption config.haganah "Enable Opinionated Gitlab Server";

    concurrentJobs = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3;
      description = ''
        Jobs all runners on this host may run at once. The runners share the
        host with GitLab itself, and an uncapped CI fan-out has been enough to
        make GitLab stop answering.
      '';
    };

    ciMemoryMax = lib.mkOption {
      type = lib.types.str;
      default = "70%";
      description = ''
        Hard memory ceiling for all CI job containers together (`ci.slice`), as
        systemd accepts it — a share of physical RAM or an absolute size. What is
        left is GitLab's: past it the kernel OOM-kills inside the slice, not
        Puma, Sidekiq or PostgreSQL.
      '';
    };

    dockerRunnerCount = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = ''
        Number of docker gitlab runners to create with the default configuraiton.

        The system configurer is responsible for ensuring that secrest exists for these named:

        secrets/${hostname}-gitlab-runner-{count}.age
      '';
    };
  };

  config = libx.mkIf config.haganah.gitlab.enable {
    age.secrets = (mkDockerSecrets dockerRunnerCount) // {
      gitlab-runner-nix = libx.mkSecret "rabin-gitlab-runner-beta" {
        owner = "gitlab";
        group = "gitlab";
      };
      ci-private-key = libx.mkSecret "ci-private-key" {
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
        concurrent = config.haganah.gitlab.concurrentJobs;
      };
      services = (mkDockerRunners dockerRunnerCount) // {
        runner-nix = {
          registrationFlags = [
            "--tls-ca-file ${../modules/step-ca/root.crt}"
            "--docker-cgroup-parent ci.slice"
          ];
          dockerVolumes =
            [
              "/etc/hosts:/etc/hosts"

              "${config.age.secrets.haganah-cache.path}:/etc/nix/key.private:ro"
              "${config.age.secrets.ci-private-key.path}:/root/.ssh/id_rsa:ro"
            ];
          dockerImage = "nixos/nix";
          dockerDisableCache = true;
          authenticationTokenConfigFile = config.age.secrets.gitlab-runner-nix.path;
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

    # The slice every docker runner's job containers are parented to. A low CPU
    # weight means CI yields to GitLab under contention without being throttled
    # when the host is idle.
    systemd.slices.ci.sliceConfig = {
      CPUWeight = 20;
      MemoryMax = config.haganah.gitlab.ciMemoryMax;
    };

    services.openssh.enable = true;

    systemd.services.gitlab-backup.environment.BACKUP = "dump";
  };
}
