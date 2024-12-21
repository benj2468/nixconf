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

  security.acme = {
    acceptTerms = true;
    defaults.email = "foo@bar.com";
  };

  networking = {
    hostName = "cape"; # Define your hostname.
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 6443 ];
    };
  };

  # Set your time zone.
  time.timeZone = "America/Los-Angelees";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bcape = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
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
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "cape.dev";
        root_url = "https://cape.dev/grafana/";
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

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--debug"
    ];
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "blog.cape.dev" = {
        addSSL = true;
        enableACME = true;
        root = "/var/www/blog";
      };
    };
  };

  system.stateVersion = "23.11"; # Did you read the comment?
}
