{ lib, libx, config, pkgs, ... }:
let cfg = config.haganah.graphical;
in {
  options.haganah.graphical = {
    enable = libx.mkTieredEnableOption config.haganah "Enable the Haganah Graphical Configurations";
  };


  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      vscode
      postman
    ];

    programs.firefox.enable = true;


    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the GNOME Desktop Environment.
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };
}
