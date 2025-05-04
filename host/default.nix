{ lib, inputs, config, hostname, stateVersion, ... }:
{
  imports = [
    (./. + "/${hostname}")
    (./. + "/${hostname}/hardware-configuration.nix")
    ./modules
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    optimise.automatic = true;
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };

    registry = lib.mkForce (lib.mapAttrs (_: value: { flake = value; }) inputs);

    nixPath = lib.mkForce (
      lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry
    );
  };

  system = { inherit stateVersion; };
}
