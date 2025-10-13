{ pkgs
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
    ./programs/direnv.nix
    ./programs/starship.nix
  ];

  catppuccin = {
    enable = true;
    flavor = "mocha";
    btop.enable = true;
    starship.enable = true;
    fzf.enable = true;
    lazygit.enable = true;
    nvim.enable = true;
    tmux.enable = true;
    zsh-syntax-highlighting.enable = true;
  };

  programs.btop.enable = true;
  programs.lazygit.enable = true;

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home = {
    inherit username stateVersion;
    homeDirectory = "/${if pkgs.system == "aarch64-darwin" then "Users" else "home"}/${username}";
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
      cachix
    ];
  };

  services = {
    vscode-server.enable = true;
  };
}
