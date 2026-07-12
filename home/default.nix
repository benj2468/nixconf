{ pkgs
, username
, stateVersion
, ...
}: {
  imports = [
    ./programs/vim/default.nix
    ./programs/zsh.nix
    ./programs/tmux.nix
    ./programs/direnv.nix
    ./programs/starship.nix
  ];

  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
  };

  programs.btop.enable = true;
  programs.lazygit.enable = true;


  home = {
    inherit username stateVersion;
    homeDirectory = "/${if pkgs.system == "aarch64-darwin" then "Users" else "home"}/${username}";
    packages = with pkgs; [
      btop
      bat
      nodejs
      alejandra
      glow
      xsel
      python3
      lazygit
      nix-output-monitor
      cachix
    ];


    file.".npmrc".text = ''
      prefix=''${HOME}/.npm-packages
    '';

    sessionPath = [
      "$HOME/.npm-packages/bin"
    ];
  };
}
