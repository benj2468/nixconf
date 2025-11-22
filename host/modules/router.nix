{ pkgs, lib, config, ... }:
let cfg = config.haganah.router; in
{
  options.haganah.router = {
    enable = lib.mkEnableOption "Enable the Router module";

    bridgeName = lib.mkOption {
      type = lib.types.str;
      default = "br0";
    };

    openFirewall = lib.mkEnableOption "Open the firewall for Router" // { enable = true; };

    bridgeInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "enp4s0" ];
    };
  };


  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      tcpdump
    ];

    networking = {
      networkmanager.enable = false;
      useNetworkd = true;
    };

    networking.wireless.userControlled.enable = true;

    networking.interfaces."${cfg.bridgeName}".ipv4.addresses = [
      {
        address = "10.101.101.1";
        prefixLength = 24;
      }
    ];

    networking.bridges."${cfg.bridgeName}" = {
      interfaces = cfg.bridgeInterfaces;
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [ 67 68 ];
    };

    networking.nat = {
      enable = true;
      internalIPs = [ "10.101.101.0/24" ];
      internalInterfaces = [ cfg.bridgeName ];
    };

    services.dnsmasq = {
      enable = true;
      settings = {
        interface = cfg.bridgeName;
        dhcp-option = [
          "option:router,10.101.101.1"
          "option:dns-server,10.101.101.1"
        ];
        no-dhcp-interface = null;
        dhcp-range = [ "10.101.101.2,10.101.101.254,12h" ];
      };
    };
  };
}
