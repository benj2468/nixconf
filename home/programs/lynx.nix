{pkgs, ...}: {
  home.packages = with pkgs; [lynx];

  programs.zsh.initExtra = ''

    function mkUrl () {
      local search=$@
      echo "''${search// /%20}"
    }

    function lx () lynx -cfg=${../cfg/lynx.cfg} -accept_all_cookies "$@"

    function duck () lx "https://lite.duckduckgo.com/lite?kd=-1&kp=-1&q=$(mkUrl $@)"

    function rust () lx "https://docs.rs/releases/search?query=$(mkUrl $@)"
  '';

  home.shellAliases = {
    "\"?\"" = "duck";
  };
}
