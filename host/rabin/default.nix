{ inputs, hostname, config, ... }:
{
  haganah = {
    enable = true;
    users.enable = true;
    graphical.enable = true;
  };

  age.secrets = {
    rabin-dashboard = {
      file = "${inputs.self}/secrets/${hostname}-dashboard.age";
      owner = "root";
      group = "users";
    };
    rabin-traccar = {
      file = "${inputs.self}/secrets/${hostname}-traccar.age";
      owner = "root";
      group = "users";
    };
  };

  networking = {

    firewall.allowedTCPPorts = [ 443 80 53 ];

    hosts = {
      # Hmm... I guess it makes sense that this needs to be the global IP. Not ideal...
      "100.73.51.55" = [ "haganah.net" "ntfy.haganah.net" "traccar.haganah.net" "jenkins.haganah.net" ];
    };
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://ntfy.haganah.net";
      upstream-base-url = "https://ntfy.sh";
    };
  };

  services.traccar = {
    enable = true;
    environmentFile = config.age.secrets.rabin-traccar.path;
    settings = {
      databasePassword = "$TRACCAR_DB_PASSWORD";
      webPort = "8083";
    };
  };

  services.jenkins = {
    enable = true;
    port = 8084;
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

      "traccar.haganah.net" = {
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:8083";
            proxyWebsockets = true;
          };
        };
      };

      "jenkins.haganah.net" = {
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:8084";
          };
        };
      };
    };
  };

  services.homepage-dashboard = {
    enable = true;
    allowedHosts = "*";
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
        machines = [
          {
            rabin = {
              description = "rabin";
              icon = "tailscale.png";
              href = "http://rabin.haganah.net";
              widget = {
                type = "tailscale";
                deviceid = "{{HOMEPAGE_VAR_TAILSCALE_DEVICE_ID}}";
                key = "{{HOMEPAGE_VAR_TAILSCALE_API_KEY}}";
              };
            };
          }
        ];
      }
    ];
  };

  # ZFS
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "40f0cb12";

  fileSystems = {
    "/mnt/var" = {
      device = "zpool/var";
      fsType = "zfs";
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";
}
