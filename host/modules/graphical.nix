{ libx, config, pkgs, ... }:
let cfg = config.haganah.graphical;
in {
  options.haganah.graphical = {
    enable = libx.mkTieredEnableOption config.haganah "Enable the Haganah Graphical Configurations";
  };


  config = libx.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      vscode
    ];

    programs.firefox.enable = true;

    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the GNOME Desktop Environment.
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };
}
