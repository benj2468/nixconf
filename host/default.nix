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
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://crane.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk="
      ];
    };

    registry = lib.mkForce (lib.mapAttrs (_: value: { flake = value; }) inputs);

    nixPath = lib.mkForce (
      lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry
    );
  };

  system = { inherit stateVersion; };
}
