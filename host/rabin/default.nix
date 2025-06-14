{ inputs, hostname, config, pkgs, ... }:
{
  haganah = {
    enable = true;
    users.enable = true;
    graphical.enable = true;
  };

  environment.systemPackages = with pkgs; [
    virt-manager
  ];

  age.secrets = {
    rabin-dashboard = {
      file = "${inputs.self}/secrets/${hostname}-dashboard.age";
      owner = "root";
      group = "users";
    };
  };

  networking = {

    firewall.allowedTCPPorts = [ 443 80 53 ];

    hosts = {
      # Hmm... I guess it makes sense that this needs to be the global IP. Not ideal...
      "100.68.69.57" = [ "haganah.net" "ntfy.haganah.net" "immich.haganah.net" ];
      "100.107.83.65" = [ "nas.haganah.net" ];
    };

    nat = {
      enable = true;
      internalInterfaces = [ "br0" ];
      internalIPs = [ "192.168.184.0/14" ];
    };

    bridges = {
      br0 = {
        interfaces = [ ];
      };
    };

    interfaces = {
      br0 = {
        useDHCP = false;
        ipv4.addresses = [{ address = "192.168.184.1"; prefixLength = 24; }];
      };
    };
  };

  services.immich = {
    enable = true;
    port = 2283;
    environment = {
      IMMICH_TELEMETRY_INCLUDE = "all";
    };
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://ntfy.haganah.net";
      upstream-base-url = "https://ntfy.sh";
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      primary = {
        default = true;

        locations."/grafana/" = with config.services.grafana.settings.server; {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = true;
        };

        locations."/" = {
          proxyPass = "http://127.0.0.1:8082";
        };
      };

      "ntfy.haganah.net" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:2586";
          proxyWebsockets = true;
        };
      };

      "immich.haganah.net" = {
        locations."/" = {
          proxyPass = "http://[::1]:${toString config.services.immich.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            client_max_body_size 50000M;
            proxy_read_timeout   600s;
            proxy_send_timeout   600s;
            send_timeout         600s;
          '';
        };
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
      { search = { provider = "google"; target = "_blank"; }; }
      { resources = { label = "system"; cpu = true; memory = true; cputemp = true; uptime = true; }; }
      { resources = { label = "storage"; disk = [ "/home" ]; }; }
      {
        openmeteo = {
          label = "Los Angeles";
          latitude = 33.680179;
          longitude = -117.7725196;
          timezone = "America/Los_Angeles";
          units = "metric";
        };
      }
    ];

    bookmarks = [{
      dev = [
        {
          github = [{
            abbr = "GH";
            href = "https://github.com/benj2468/";
            icon = "github-light.png";
          }];
        }
        {
          homepage = [{
            abbr = "HD";
            href = "https://gethomepage.dev";
            icon = "homepage.png";
          }];
        }
        {
          flake-parts = [{
            abbr = "FP";
            href = "https://flake.parts";
            icon = "nix.png";
          }];
        }
      ];
    }];

    services = [
      {
        infra = [{
          grafana = {
            icon = "grafana.png";
            href = "http://rabin.haganah.net/grafana";
            widget = {
              type = "grafana";
              url = "http://localhost/grafana";
              username = "{{HOMEPAGE_VAR_GRAFANA_USERNAME}}";
              password = "{{HOMEPAGE_VAR_GRAFANA_PASSWORD}}";
            };
          };
        }];
      }
      {
        home = [{
          immich = {
            icon = "immich.png";
            href = "http://immich.haganah.net";
            widget = {
              type = "immich";
              url = "http://immich.haganah.net";
              key = "{{HOMEPAGE_VAR_IMMICH_KEY}}";
              version = 2;
            };
          };
        }];
      }
      {
        machines = [
          {
            rabin = {
              description = "rabin";
              icon = "tailscale.png";
              href = "http://rabin.haganah.net";
              widget = {
                type = "tailscale";
                deviceid = "{{HOMEPAGE_VAR_TAILSCALE_DEVICE_ID}}";
                key = "{{HOMEPAGE_VAR_TAILSCALE_AUTH_KEY}}";
              };
            };
          }
        ];
      }
    ];
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
    };
  };

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";
}
