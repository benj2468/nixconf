{ inputs, hostname, config, ... }:
{

  age.secrets = {
    rabin-dashboard = {
      file = "${inputs.self}/secrets/rabin-dashboard.age";
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
  services.jenkins = {
    enable = true;
    port = 9009;
    prefix = "/jenkins";
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
    ];
  };
}
