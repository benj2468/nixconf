{ ... }:

{
  haganah = {
    enable = true;
    users.enable = true;
  };

  networking = {

    useNetworkd = true;
    networkmanager.enable = false;
    dhcpcd.enable = false;

    vlans = {
      # VLAN 11 is internet
      vlan11 = { id = 11; interface = "enu1u1"; };
      # VLAN 18 will be local mesh, provided by this router.
      vlan18 = { id = 18; interface = "enu1u1"; };
    };

    interfaces.enu1u1.useDHCP = false;
    interfaces.vlan11.useDHCP = true;
  };

  time.timeZone = "America/Los_Angeles";
}
