{pkgs, ...}: {

  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      nerdtree

      # coc
      coc-nvim
      coc-rust-analyzer
      coc-clangd
      coc-markdownlint
      coc-cmake
      coc-toml
      coc-yaml
      coc-json
      coc-python
      coc-spell-checker
      coc-sh

      vim-airline
      vim-fugitive
      vim-nix
      vim-clang-format
      rust-vim

      # Themes
      gruvbox
      ctrlp-vim
    ];
    extraConfig = ''
      colorscheme gruvbox
      set background=dark

      "Set line numbers on by default
      set number
      set relativenumber

      inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                                 \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
      " Start NERDTree when Vim starts with a directory argument.
      autocmd StdinReadPre * let s:std_in=1
      autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists('s:std_in') | execute 'NERDTree' argv()[0] | wincmd p | enew | execute 'cd '.argv()[0] | endif
    '';
  };
}
