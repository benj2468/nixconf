# treefmt.nix
{ pkgs, ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";

  settings = {
    global = {
      excludes = [ "*.age" "*.cfg" "*.conf" ];
    };
  };

  programs.jsonfmt.enable = true;
  programs.nixpkgs-fmt.enable = true;
  programs.shellcheck.enable = true;
}
