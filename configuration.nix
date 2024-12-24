{ config
, lib
, pkgs
, options
, ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # With an existing `nix.nixPath` entry:
  nix.nixPath =
    # Prepend default nixPath values.
    options.nix.nixPath.default
    ++
    # Append our nixpkgs-overlays.
    [ "nixpkgs-overlays=/etc/nixos/overlays-compat/" ];

  age.secrets = {
    rabin-dashboard = {
      file = ./secrets/rabin-dashboard.age;
      owner = "root";
      group = "users";
      mode = "400";
    };
  };

  networking = {
    hostName = "rabin";
    useNetworkd = true;
    firewall = {
      enable = true;
      logRefusedPackets = true;
      allowedTCPPorts = [ 6443 8080 443 80 ];
    };
    nameservers = [ "1.1.1.1" "8.8.8.8" "100.100.100.100" ];
    search = [ "tail551489.ts.net" ];
  };

  services.tailscale.enable = true;

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      rabin = {
        default = true;
        locations."/grafana/" = {
          proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };

        locations."/jenkins/" = {
          proxyPass = "http://127.0.0.1:9009";
        };

        locations."/" = {
          proxyPass = "http://127.0.0.1:8082";
        };
      };
    };
  };

  # Set your time zone.
  time.timeZone = "America/Los-Angelees";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bcape = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "users" ];
    shell = pkgs.zsh;
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch";
    };
  };

  environment.systemPackages = with pkgs; [
    busybox
    vim
    wget
    git
    (fenix.stable.withComponents [ "cargo" "clippy" "rust-src" "rustc" "rustfmt" ])
    rust-analyzer
    gcc
    neofetch
    clang-tools
    libclang
    tree
    jq
    yq

    (wrapHelm kubernetes-helm {
      plugins = with pkgs.kubernetes-helmPlugins; [
        helm-diff
        helm-git
      ];
    })
  ];

  environment.variables.EDITOR = "vim";

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  services.sshd.enable = true;

  services.jenkins = {
    enable = true;
    port = 9009;
    prefix = "/jenkins";
  };

  services.grafana = {
    enable = true;
    settings = {
      panels = {
        enable_alpha = true;
      };
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "rabin";
        root_url = "http://rabin/grafana/";
        serve_from_sub_path = true;
      };
    };
  };

  services.prometheus = {
    enable = true;

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
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

  services.homepage-dashboard = {
    enable = true;
    environmentFile = config.age.secrets.rabin-dashboard.path;
    settings = {
      title = "Cape Homepage";
    };

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
    ];

    services = [
      {
        infra = [{
          grafana = {
            icon = "grafana.png";
            href = "http://rabin/grafana/";
            widget = {
              type = "grafana";
              url = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
              username = "{{HOMEPAGE_VAR_GRAFANA_USERNAME}}";
              password = "{{HOMEPAGE_VAR_GRAFANA_PASSWORD}}";
            };
          };
        }];
      }
    ];
  };

  virtualisation.docker.enable = true;
}
