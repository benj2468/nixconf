{ ... }:
{
  imports = [
    ./haganah.nix
    ./gitlab.nix
    ./graphical.nix
    ./users.nix
    ./router.nix
    ./step-ca/module.nix
  ];
}
