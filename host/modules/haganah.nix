{ config
, lib
, pkgs
, ...
}: {
  options.haganah = {
    enable = lib.mkEnableOption "Enable Haganah Configurations";
  };

  config = lib.mkIf config.haganah.enable {

    programs.zsh.enable = true;
    programs.fzf = {
      keybindings = true;
      fuzzyCompletion = true;
    };

    networking = {
      networkmanager.enable = lib.mkDefault true;
    };

    services.resolved.enable = false;
    services.dnsmasq = {
      enable = true;
    };

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "server";
      openFirewall = true;
    };

    environment.systemPackages = with pkgs; [
      busybox
      lm_sensors
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
      agenix
      cachix
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

    services.prometheus = {
      enable = lib.mkDefault true;

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
  };
}
