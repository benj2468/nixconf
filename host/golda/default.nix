{ ... }:

{
  haganah = {
    enable = true;
    users.enable = true;
  };

  networking = {
    vlans = {
      # VLAN 11 is internet
      vlan11 = { id = 11; interface = "enu1u1"; };
    };

    interfaces.enu1u1.useDHCP = false;
    interfaces.vlan11.useDHCP = true;
  };

  time.timeZone = "America/Los_Angeles";
}
