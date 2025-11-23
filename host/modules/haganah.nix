{ config
, lib
, pkgs
, inputs
, ...
}: {
  options.haganah = {
    enable = lib.mkEnableOption "Enable Haganah Configurations";
  };

  config = lib.mkIf config.haganah.enable {

    age.secrets = {
      wifi-psks = {
        file = "${inputs.self}/secrets/wifi.age";
        owner = "root";
        group = "users";
      };
    };

    programs.zsh.enable = true;

    networking = {

      # If we ever switch to networkd...
      # wireless = {
      #   enable = lib.mkDefault true;
      #   secretsFile = config.age.secrets.wifi-psks.path;
      #   networks.skiron.pskRaw = "ext:psk_skiron";
      # };

      # Add the tailscale nameserver
      nameservers = [ "1.1.1.1" ];

      networkmanager.enable = lib.mkDefault true;
    };

    services.resolved.enable = false;
    services.dnsmasq = {
      enable = true;
      settings.server = config.networking.nameservers;
    };

    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = lib.mkDefault "client";
    };

    environment.systemPackages = with pkgs; [
      busybox
      lm_sensors
      vim
      wget
      git
      gcc
      neofetch
      tree
      jq
      yq
      agenix
      cachix
      iotop
      home-manager
    ];

    environment.variables.EDITOR = "vim";

    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = true;
    };

    services.sshd.enable = true;

    services.grafana = {
      enable = lib.mkDefault true;
      settings = {
        panels = {
          enable_alpha = true;
        };
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
          # domain = lib.mkDefault hostname;
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

    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3031;
          grpc_listen_port = 0;
        };
        positions = {
          filename = "/tmp/positions.yaml";
        };
        clients = [{
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }];
        scrape_configs = [{
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "pihole";
            };
          };
          relabel_configs = [{
            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }];
        }];
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

    virtualisation.docker.enable = lib.mkDefault true;

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
      buildMachines = [
        {
          hostName = "gantz";
          system = "aarch64-linux";
          protocol = "ssh";
          supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "uid-range" ];
        }
      ];
      distributedBuilds = true;
    };
  };
}
