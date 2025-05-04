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
  };

  networking = {
    firewall.allowedTCPPorts = [ 6443 443 80 ];
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
              href = "http://rabin.tail551489.ts.net";
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

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";
}
