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

    # For management of the managed switch
    interfaces.enu1u1.ipv4.addresses = [{
      address = "192.168.0.1";
      prefixLength = 24;
    }];

    # For internet
    interfaces.vlan11.useDHCP = true;
  };

  time.timeZone = "America/Los_Angeles";
}
