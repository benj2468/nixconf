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
      fzf-vim
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

      " COC Vim
      " Use <c-space> to trigger completion
      if has('nvim')
          inoremap <silent><expr> <c-space> coc#refresh()
      else
        inoremap <silent><expr> <c-@> coc#refresh()
      endif

      " Use `[g` and `]g` to navigate diagnostics
      " Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
      nmap <silent> [g <Plug>(coc-diagnostic-prev)
      nmap <silent> ]g <Plug>(coc-diagnostic-next)

      " GoTo code navigation
      nmap <silent> gd <Plug>(coc-definition)
      nmap <silent> gy <Plug>(coc-type-definition)
      nmap <silent> gi <Plug>(coc-implementation)
      nmap <silent> gr <Plug>(coc-references)

      " Use K to show documentation in preview window
      nnoremap <silent> K :call ShowDocumentation()<CR>

      function! ShowDocumentation()
        if CocAction('hasProvider', 'hover')
          call CocActionAsync('doHover')
        else
          call feedkeys('K', 'in')
        endif
      endfunction

      " Highlight the symbol and its references when holding the cursor
      autocmd CursorHold * silent call CocActionAsync('highlight')

      nmap <silent> <C-p> :Files<enter>
      nmap <silent> <C-f> :Ag<enter>
    '';
  };

  home.file.".vim/coc-settings.json".text = builtins.readFile ./configs/coc-settings.json;
}
