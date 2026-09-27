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
        # Lets a Nix job verify cache.haganah.net's step-ca certificate; see
        # runner-privileged below.
        "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/haganah-ca-bundle.crt:ro"
      ];
      environmentVariables = {
        NIX_SSL_CERT_FILE = "/etc/ssl/certs/haganah-ca-bundle.crt";
      };
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
      gitlab-runner-privileged = libx.mkSecret "rabin-gitlab-runner-privileged" {
        owner = "gitlab";
        group = "gitlab";
      };
      ci-private-key = libx.mkSecret "ci-private-key" {
        owner = "gitlab";
        group = "gitlab";
      };
    } // {
      # GitLab's own keys. These used to be `pkgs.writeText` literals in this
      # (public) repo and so in the world-readable store; secret_key_base and
      # the initial root password were rotated in the move. db_key_base, the
      # ActiveRecord keys and otp_key_base kept their values, because rotating
      # them makes existing encrypted data (CI/CD variables, tokens, 2FA seeds)
      # unreadable; if they ever must be rotated, follow GitLab's "lost secrets"
      # procedure, which resets CI/CD variables, runner tokens and 2FA.
      gitlab-secret-key-base = libx.mkSecret "rabin-gitlab-secret-key-base" {
        owner = "gitlab";
        group = "gitlab";
      };
      gitlab-otp-key-base = libx.mkSecret "rabin-gitlab-otp-key-base" {
        owner = "gitlab";
        group = "gitlab";
      };
      gitlab-db-key-base = libx.mkSecret "rabin-gitlab-db-key-base" {
        owner = "gitlab";
        group = "gitlab";
      };
      gitlab-ar-salt = libx.mkSecret "rabin-gitlab-ar-salt" {
        owner = "gitlab";
        group = "gitlab";
      };
      gitlab-ar-primary-key = libx.mkSecret "rabin-gitlab-ar-primary-key" {
        owner = "gitlab";
        group = "gitlab";
      };
      gitlab-ar-deterministic-key = libx.mkSecret "rabin-gitlab-ar-deterministic-key" {
        owner = "gitlab";
        group = "gitlab";
      };
      gitlab-initial-root-password = libx.mkSecret "rabin-gitlab-initial-root-password" {
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
        runner-privileged = {
          registrationFlags = [
            "--tls-ca-file ${../modules/step-ca/root.crt}"
          ];
          dockerPrivileged = true;
          dockerVolumes = [
            "/sccache:/sccache"
            "/etc/hosts:/etc/hosts"
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/haganah-ca-bundle.crt:ro"
          ];
          dockerImage = "alpine:latest";
          environmentVariables = {
            NIX_SSL_CERT_FILE = "/etc/ssl/certs/haganah-ca-bundle.crt";
          };
          authenticationTokenConfigFile = config.age.secrets.gitlab-runner-privileged.path;
        };
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
      # No databasePasswordFile: GitLab reaches its local PostgreSQL over the
      # unix socket with peer auth, so a password was never used.
      initialRootPasswordFile = config.age.secrets.gitlab-initial-root-password.path;
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
        secretFile = config.age.secrets.gitlab-secret-key-base.path;
        otpFile = config.age.secrets.gitlab-otp-key-base.path;
        dbFile = config.age.secrets.gitlab-db-key-base.path;
        jwsFile = pkgs.runCommand "oidcKeyBase" { } "${pkgs.openssl}/bin/openssl genrsa 2048 > $out";
        activeRecordSaltFile = config.age.secrets.gitlab-ar-salt.path;
        activeRecordPrimaryKeyFile = config.age.secrets.gitlab-ar-primary-key.path;
        activeRecordDeterministicKeyFile = config.age.secrets.gitlab-ar-deterministic-key.path;
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
