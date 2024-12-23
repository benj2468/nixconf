{ config
, lib
, pkgs
, options
, hostname
, inputs
, ...
}: {
  imports = [
    ./boot.nix
    ./users
  ];

  networking = {
    hostName = hostname;
    useNetworkd = lib.mkDefault true;
    useDHCP = lib.mkDefault true;
    firewall = {
      enable = true;
      logRefusedPackets = lib.mkDefault true;
    };
    nameservers = [ "100.100.100.100" "1.1.1.1" "8.8.8.8" ];
    # I think this should be a secret?
    search = [ "tail551489.ts.net" ];
  };

  services.tailscale.enable = true;

  time.timeZone = "America/Los-Angelees";

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
        domain = lib.mkDefault hostname;
        root_url = lib.mkDefault "http://${hostname}/grafana/";
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
}
