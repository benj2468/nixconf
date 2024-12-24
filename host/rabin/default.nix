{ pkgs, inputs, hostname, config, ... }:
{

  imports = [
    ../modules/gitlab.nix
  ];

  environment.systemPackages = with pkgs; [
    gitlab-runner
  ];

  age.secrets = {
    rabin-dashboard = {
      file = "${inputs.self}/secrets/${hostname}-dashboard.age";
      owner = "root";
      group = "users";
      mode = "400";
    };
  };

  networking = {
    firewall.allowedTCPPorts = [ 6443 443 80 ];
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {

      "git.rabin" = {
        locations."/" = {
          proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
        };
      };

      rabin = {
        default = true;

        locations."/grafana/" = {
          proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
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
            href = "http://${hostname}/grafana/";
            widget = {
              type = "grafana";
              url = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
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
              href = "http://rabin";
              widget = {
                type = "tailscale";
                deviceid = "{{HOMEPAGE_VAR_TAILSCALE_RABIN_DEVICE_ID}}";
                key = "{{HOMEPAGE_VAR_TAILSCALE_AUTH_KEY}}";
              };
            };
          }
        ];
        #dev = [{
        #  gitlab = {
        #    icon = "gitlab.png";
        #    href = "http://git.${hostname}";
        #    widget = {
        #      type = "gitlab";
        #      url = "http://git.${hostname}";
        #      key = "{{HOMEPAGE_VAR_GITLAB_KEY}}";
        #      user_id = "{{HOMEPAGE_VAR_GITLAB_USER}}";
        #    };
        #  };
        #}];
      }
    ];
  };
}
