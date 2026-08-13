{ ... }:
{
  haganah = {
    enable = true;
    users.enable = true;
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Cross compilation support
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";
}
