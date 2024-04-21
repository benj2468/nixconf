{
  config,
  pkgs,
  ...
}: {
  home.username = "bcape";
  home.homeDirectory = "/home/bcape";

  home.packages = with pkgs; [
    btop
    tmux
    thefuck
    nodejs
    alejandra
  ];

  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  programs.tmux.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = ["git" "thefuck"];
      theme = "robbyrussell";
    };
  };

  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      rust-vim

      # coc
      coc-nvim
      coc-rust-analyzer

      vim-airline
      vim-fugitive

      # Themes
      gruvbox
      ctrlp-vim
    ];
    extraConfig = ''
      colorscheme gruvbox
      set background=dark
      inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                                 \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
    '';
  };
}
