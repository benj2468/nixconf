{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./programs/vim/default.nix
    ./programs/zsh.nix
    ./programs/tmux.nix
    ./programs/lynx.nix
  ];

  home.username = "bcape";
  home.homeDirectory = "/home/bcape";

  home.packages = with pkgs; [
    btop
    thefuck
    nodejs
    alejandra
    silver-searcher
  ];

  home.stateVersion = "23.11";

  programs.home-manager.enable = true;
}
