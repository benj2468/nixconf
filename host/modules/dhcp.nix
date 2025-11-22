{ lib, config, ... }:
let cfg = config.haganah.dhcp; in
{
  options.haganah.dhcp = {
    enable = lib.mkEnableOption "Enable the DHCP module";

    bridgeName = lib.mkOption {
      type = lib.types.str;
      default = "br0";
    };

    openFirewall = lib.mkEnableOption "Open the firewall for DHCP" // { enable = true; };

    bridgeInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "enp4s0" ];
    };
  };


  config = lib.mkIf cfg.enable {


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
