{ config
, pkgs
, username
, stateVersion
, inputs
, ...
}: {
  imports = [
    inputs.vscode-server.nixosModules.home
    ./programs/vim/default.nix
    ./programs/zsh.nix
    ./programs/tmux.nix
    ./programs/lynx.nix
    ./programs/direnv.nix
  ];

  home = {
    inherit username stateVersion;
    homeDirectory = "/home/${username}";
    packages = with pkgs; [
      btop
      bat
      thefuck
      nodejs
      alejandra
      silver-searcher
      glow
      xsel
      python3
      lazygit
      nix-output-monitor
    ];
  };

  services = {
    vscode-server.enable = true;
  };

  programs.home-manager.enable = true;
}
