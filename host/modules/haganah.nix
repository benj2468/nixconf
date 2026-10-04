{ config
, lib
, pkgs
, libx
, ...
}:
let
  cfg = config.haganah;

  # The R2 binary cache, defined in github.com/benj2468/haganah-infra
  # (cloudflare/r2.tf, whose `nix_cache_url` output this is). Its public key is
  # not a secret; the private half is the haganah-nix-cache-1 age secret.
  nixCache = {
    url = "s3://haganah-nix-cache?endpoint=90158d26c50c77657b996f24c7d44142.r2.cloudflarestorage.com&region=auto";
    publicKey = "haganah-nix-cache-1:AqKW0D4ff5y5TeFPMfl10EIQqMpDC+zhIU3hWWDMGNM=";
    # Uploads only: every narinfo records its own compression, so readers
    # don't care, and zstd is several times faster than the default xz.
    pushUrl = "s3://haganah-nix-cache?endpoint=90158d26c50c77657b996f24c7d44142.r2.cloudflarestorage.com&region=auto&compression=zstd";
    # Paths built here and not yet uploaded, one per line.
    queue = "/var/lib/haganah-nix-cache/queue";
  };

  # rabin, the one x86_64 haganah host, builds x86_64 closures for the rest
  # over ssh-ng (it serves its store with nix.sshServe, host/rabin). Reached
  # over Tailscale. The public half of the haganah-builder-key age secret
  # is the key rabin accepts; rabin's host key is the one secrets.nix names.
  builder = {
    hostName = "rabin";
    address = "100.73.51.55";
    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAeofWvYHMVo+FKERUYbIpTsWzFP3EJ7j20bsc9pwByi";
    clientKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMDUBkw3sVHJEfWADN1kyFCNDYQGevdKzj6ZF7u/Lbfz haganah-builder";
  };
  isBuilder = config.networking.hostName == builder.hostName;

  # nix's post-build hook. It runs synchronously after every build, blocking
  # the build loop, and a non-zero exit fails the build — so it only records
  # the outputs and never fails; the upload happens in
  # haganah-nix-cache-push, off the build's critical path. The outputs are
  # already signed (secret-key-files), so they upload as they are.
  enqueueHook = pkgs.writeShellScript "haganah-nix-cache-enqueue" ''
    set -f
    mkdir -p "$(dirname ${nixCache.queue})" 2>/dev/null
    printf '%s\n' $OUT_PATHS >> ${nixCache.queue} 2>/dev/null
    exit 0
  '';
in
{
  options.haganah = {
    enable = lib.mkEnableOption "Enable Haganah Configurations";

    enableObservability = lib.mkEnableOption "Enable Haganah Observability" // {
      default = true;
    };

    enableTailscale = lib.mkEnableOption "Enable Tailscale" // {
      default = true;
    };

    useRemoteBuilder = lib.mkEnableOption "building x86_64-linux derivations on rabin" // {
      default = !isBuilder;
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        age.secrets = {
          haganah-cache = libx.mkSecret "haganah-cache" {
            mode = "440";
            owner = "root";
            group = "wheel";
          };
          # The R2 binary cache's signing key (see `nixCache` below). Same
          # permissions as haganah-cache: the daemon signs as root, and wheel
          # can `nix store sign` a path by hand before pushing it.
          haganah-nix-cache-1 = libx.mkSecret "haganah-nix-cache-1" {
            mode = "440";
            owner = "root";
            group = "wheel";
          };
          # AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY for the bucket: the hosts'
          # own token (read and write, separate from CI's so either can be
          # revoked alone). Read by the nix daemon to substitute and by
          # haganah-nix-cache-push to upload, both root, so root-only.
          haganah-nix-cache-r2 = libx.mkSecret "haganah-nix-cache-r2" {
            mode = "400";
            owner = "root";
            group = "root";
          };
        };

        programs.wireshark.enable = true;
        programs.zsh.enable = true;

        networking = {

          # mkAfter puts this at the end of the list, rather than before 127.0.0.1
          nameservers = lib.mkAfter [ "1.1.1.1" ];

          useNetworkd = true;
          networkmanager.enable = false;
          dhcpcd.enable = false;
        };

        services.chrony = {
          enable = true;
          servers = [ "pool.ntp.org" ];
        };

        services.resolved.enable = false;
        services.dnsmasq = {
          enable = true;
          settings.server = lib.mkAfter [
            "1.1.1.1"
          ];
        };

        environment.systemPackages = with pkgs; [
          podman-compose
          busybox
          lm_sensors
          vim
          wget
          git
          gcc
          fastfetch
          tree
          jq
          yq
          agenix
          cachix
          iotop
          home-manager
          sccache
          termshark
        ];

        environment.variables.EDITOR = "vim";

        services.openssh = {
          enable = true;
          settings.PasswordAuthentication = true;
        };

        services.sshd.enable = true;

        virtualisation.docker = {
          enable = lib.mkDefault true;
          autoPrune = {
            enable = true;
            dates = "daily";
            allVolumes.enable = true;
          };
        };
        # Select internationalisation properties.
        i18n.defaultLocale = "en_US.UTF-8";

        i18n.extraLocaleSettings = {
          LC_ADDRESS = "en_US.UTF-8";
          LC_IDENTIFICATION = "en_US.UTF-8";
          LC_MEASUREMENT = "en_US.UTF-8";
          LC_MONETARY = "en_US.UTF-8";
          LC_NAME = "en_US.UTF-8";
          LC_NUMERIC = "en_US.UTF-8";
          LC_PAPER = "en_US.UTF-8";
          LC_TELEPHONE = "en_US.UTF-8";
          LC_TIME = "en_US.UTF-8";
        };

        # Keep the computer from sleeping
        systemd.targets.sleep.enable = false;
        systemd.targets.suspend.enable = false;
        systemd.targets.hibernate.enable = false;
        systemd.targets.hybrid-sleep.enable = false;

        nix = {
          settings = {
            # Every local build is signed with both keys: haganah-cache for
            # whatever still trusts it, haganah-nix-cache-1 so a path built
            # here can be pushed to the R2 cache as-is.
            secret-key-files = [
              config.age.secrets.haganah-cache.path
              config.age.secrets.haganah-nix-cache-1.path
            ];
            trusted-users = [ "ci" ];
            # The R2 cache CI and every haganah host fill (wayfinder's
            # `.github/actions/nix`, and the hook below). Extra, not a
            # replacement: cache.nixos.org and the cachix caches stay first,
            # and a path missing here is just fetched or built. The bucket is
            # private, so the daemon authenticates with the credentials below.
            extra-substituters = [ nixCache.url ];
            extra-trusted-public-keys = [ nixCache.publicKey ];
            post-build-hook = enqueueHook;
          };
          distributedBuilds = true;
        };
        # `-`: optional. A host whose key is not yet a recipient of the secret
        # (secrets/secrets.nix) then runs a daemon that cannot read the R2
        # cache, rather than no daemon at all — systemd refuses to start a
        # unit whose EnvironmentFile is missing.
        systemd.services.nix-daemon.serviceConfig.EnvironmentFile =
          "-${config.age.secrets.haganah-nix-cache-r2.path}";

        # Drains the post-build hook's queue into the R2 cache. Started by the
        # path unit whenever the hook appends, and by the timer as a retry.
        #
        # The queue is renamed before it is read, so the hook's appends during
        # an upload land in a fresh file; a batch that fails to upload goes
        # back onto the queue for the next run. Paths garbage-collected in
        # the meantime are skipped. Never fails the unit on an upload error:
        # the cache is an optimisation, and a failed unit would only nag.
        systemd.services.haganah-nix-cache-push = {
          description = "Upload locally built store paths to the haganah R2 Nix cache";
          path = [ config.nix.package pkgs.coreutils ];
          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = "-${config.age.secrets.haganah-nix-cache-r2.path}";
          };
          script = ''
            queue=${nixCache.queue}
            if [ -z "''${AWS_ACCESS_KEY_ID:-}" ]; then
              echo "no cache credentials on this host; leaving the queue alone"
              exit 0
            fi
            [ -s "$queue" ] || exit 0
            batch="$queue.$(date +%s%N)"
            mv "$queue" "$batch"
            mapfile -t paths < <(sort -u "$batch" | while read -r p; do [ -e "$p" ] && echo "$p"; done)
            if [ "''${#paths[@]}" -eq 0 ]; then
              rm -f "$batch"
              exit 0
            fi
            echo "uploading ''${#paths[@]} paths"
            if nix copy --to '${nixCache.pushUrl}' "''${paths[@]}"; then
              rm -f "$batch"
            else
              echo "upload failed; requeueing ''${#paths[@]} paths"
              cat "$batch" >> "$queue"
              rm -f "$batch"
            fi
          '';
        };
        systemd.paths.haganah-nix-cache-push = {
          wantedBy = [ "multi-user.target" ];
          pathConfig.PathModified = nixCache.queue;
        };
        systemd.timers.haganah-nix-cache-push = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "5min";
            OnUnitInactiveSec = "30min";
          };
        };
        systemd.tmpfiles.rules = [ "d ${builtins.dirOf nixCache.queue} 0700 root root -" ];

      }
      (lib.mkIf isBuilder {
        nix.sshServe = {
          enable = true;
          protocol = "ssh-ng";
          write = true;
          # Remote builds hand rabin derivations, which only a trusted user
          # may build; the forced command keeps the key to nix-daemon --stdio.
          trusted = true;
          keys = [ builder.clientKey ];
        };
      })
      (lib.mkIf cfg.useRemoteBuilder {
        age.secrets.haganah-builder-key = libx.mkSecret "haganah-builder-key" {
          mode = "400";
          owner = "root";
          group = "root";
        };

        nix.buildMachines = [{
          hostName = builder.address;
          protocol = "ssh-ng";
          sshUser = "nix-ssh";
          sshKey = config.age.secrets.haganah-builder-key.path;
          systems = [ "x86_64-linux" ];
          maxJobs = 4;
          supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        }];
        # rabin fetches what it can from the caches itself rather than having
        # it all copied up from here.
        nix.settings.builders-use-substitutes = true;

        programs.ssh.knownHosts.rabin = {
          hostNames = [ builder.hostName builder.address ];
          publicKey = builder.hostKey;
        };
      })
      (lib.mkIf cfg.enableTailscale {
        services.tailscale = {
          enable = true;
          openFirewall = true;
          useRoutingFeatures = lib.mkDefault "client";
        };
      })
      (lib.mkIf cfg.enableObservability {

        services.grafana = {
          enable = lib.mkDefault true;
          settings = {
            panels = {
              enable_alpha = true;
            };
            security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
            server = {
              http_addr = "0.0.0.0";
              http_port = 3000;
              root_url = lib.mkDefault "http://127.0.0.1/grafana/";
              serve_from_sub_path = true;
            };
          };
        };

        services.loki = {
          enable = true;
          configuration = {
            server.http_listen_port = 3030;
            auth_enabled = false;
            common = {
              ring = {
                instance_addr = "127.0.0.1";
                kvstore = {
                  store = "inmemory";
                };
              };
              replication_factor = 1;
              path_prefix = "/tmp/loki";
            };

            schema_config = {
              configs = [{
                from = "2022-06-06";
                store = "tsdb";
                object_store = "filesystem";
                schema = "v13";
                index = {
                  prefix = "index_";
                  period = "24h";
                };
              }];
            };

            storage_config = {
              filesystem = {
                directory = "/var/lib/loki/chunks";
              };
            };
          };
        };

        services.prometheus = {
          enable = lib.mkDefault true;

          scrapeConfigs = [
            {
              job_name = "node";
              static_configs = [{
                targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
              }];
            }
            {
              job_name = "nginx";
              static_configs = [{
                targets = [ "localhost:${toString config.services.prometheus.exporters.nginx.port}" ];
              }];
            }
          ];

          exporters = {
            node = {
              enable = true;
              port = 9100;
              enabledCollectors = [
                "logind"
                "systemd"
              ];
              disabledCollectors = [
                "textfile"
              ];
              openFirewall = true;
              firewallFilter = "-i br0 -p tcp -m tcp --dport 9100";
            };
          };
        };
      })
    ]);
}
