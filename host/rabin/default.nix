{ libx, config, ... }:
{
  haganah = {
    enable = true;
    users.enable = true;
    graphical.enable = true;
    gitlab.enable = true;
    router = {
      enable = true;
      bridgeInterfaces = [
        "vlan18"
      ];
    };
    security.ca.type = "server";
  };

  age.secrets = {
    rabin-dashboard = libx.mkSecret "rabin-dashboard" { };
  };

  networking = {

    firewall.allowedTCPPorts = [ 443 80 53 ];

    vlans = {
      # VLAN 11 is internet
      vlan11 = { id = 11; interface = "enp4s0"; };
      # VLAN 18 will be local mesh, provided by this router.
      vlan18 = { id = 18; interface = "enp4s0"; };
    };

    interfaces.enp4s0.useDHCP = false;
    interfaces.vlan11.useDHCP = true;

    hosts =
      let
        localhosts = [
          "haganah.net"
          "git.haganah.net"
          "recipes.haganah.net"
          "ca.haganah.net"
          "home.haganah.net"
          "cache.haganah.net"
          "registry.haganah.net"
        ];
      in
      {
        # Hmm... I guess it makes sense that this needs to be the global IP. Not ideal...
        "100.73.51.55" = localhosts;
      };
  };

  services.prometheus.exporters.nginx.enable = true;
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "bcape@haganah.net";
      server = "https://127.0.0.1:${builtins.toString config.services.step-ca.port}/acme/acme/directory";
    };
  };
  services.nginx = {
    enable = true;
    clientMaxBodySize = "100M";

    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      primary = {
        default = true;

        locations."/grafana/" = with config.services.grafana.settings.server; {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = true;
        };

        locations."/nginx_status" = {
          extraConfig = ''
            stub_status on;
            access_log off;
            allow 127.0.0.1;
          '';
        };

        locations."/" = {
          proxyPass = "http://127.0.0.1:8082";
        };

      };

      "home.haganah.net" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8123";
          proxyWebsockets = true;
        };
      };

      "git.haganah.net" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
        };
      };

      "registry.haganah.net" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:5001";
        };
      };

      "ca.haganah.net" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:${builtins.toString config.services.step-ca.port}";
            proxyWebsockets = true;
          };
        };
      };

      "recipes.haganah.net" = {
        locations = {
          "/media/".alias = "/var/lib/tandoor-recipes/";
          "/" = {
            proxyPass = "http://localhost:${builtins.toString config.services.tandoor-recipes.port}";
            proxyWebsockets = true;
          };
        };
      };

      "cache.haganah.net" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://localhost:5000";
          };
        };
      };
    };
  };

  services.harmonia-dev.cache = {
    enable = true;
    signKeyPaths = [ config.age.secrets.haganah-cache.path ];
  };

  services.tandoor-recipes = {
    enable = true;
    port = 6690;
    database.createLocally = true;
    extraConfig = {
      ALLOWED_HOSTS = "recipes.haganah.net";
      ENABLE_SIGNUP = 1;
      ENABLE_METRICS = 1;
    };
  };

  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "harmonia";
        static_configs = [{
          targets = [ "localhost:5000" ];
        }];
      }
    ];
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
            href = "http://haganah.net/grafana";
            widget = {
              type = "grafana";
              url = "http://localhost/grafana";
              username = "{{HOMEPAGE_VAR_GRAFANA_USERNAME}}";
              password = "{{HOMEPAGE_VAR_GRAFANA_PASSWORD}}";
            };
          };
        }
          {
            gitlab = {
              icon = "gitlab.png";
              href = "https://git.haganah.net";
              widget = {
                type = "gitlab";
                url = "https://git.haganah.net";
                key = "{{HOMEPAGE_VAR_GITLAB_API_KEY}}";
                user_id = "1";
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
              href = "http://haganah.net";
              widget = {
                type = "tailscale";
                deviceid = "{{HOMEPAGE_VAR_TAILSCALE_DEVICE_ID}}";
                key = "{{HOMEPAGE_VAR_TAILSCALE_API_KEY}}";
              };
            };
          }
          {
            shamir = {
              description = "shamir";
              icon = "tailscale.png";
              href = "http://haganah.net";
              widget = {
                type = "tailscale";
                deviceid = "{{HOMEPAGE_VAR_TAILSCALE_DEVICE_ID_SHAMIR}}";
                key = "{{HOMEPAGE_VAR_TAILSCALE_API_KEY}}";
              };
            };
          }
        ];
      }
    ];
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      registry = {
        volumes = [ "/var/lib/registry:/var/lib/registry" ];
        image = "registry:3";
        ports = [ "5001:5000" ];
      };
      homeassistant = {
        volumes = [ "/var/lib/home-assistant:/config" ];
        environment.TZ = "America/Los_Angeles";
        image = "ghcr.io/home-assistant/home-assistant:2025.12.4";
        capabilities = {
          NET_ADMIN = true;
        };
        extraOptions = [
          "--network=host"
          # Pass devices into the container, so Home Assistant can discover and make use of them
          #"--device=/dev/ttyACM0:/dev/ttyACM0"
        ];
      };
    };
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
