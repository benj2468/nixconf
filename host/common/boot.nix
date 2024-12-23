{ ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      availableKernelModules = [ "ahci" "xhci_pci" "nvme" "usbhid" "sr_mod" ];
      kernelModules = [ ];
    };

    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  # These should probably be system by system
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/15f55af2-7456-4daf-9101-69efad852a6f";
    fsType = "ext4";
  };


  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/4DA5-E8A2";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/22127f7a-1299-4438-bf81-101244cc1206"; }
  ];
}
