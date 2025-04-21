{ lib, inputs, outputs, config, hostname, stateVersion, ... }:
{
  imports = [
    (./. + "/${hostname}")
    ./modules
    ./common
  ];

  nixpkgs = {
    config.allowUnfree = true;
    overlays = (with inputs; [
      # Overlays that we import
      agenix.overlays.default
      fenix.overlays.default
    ]) ++ (with outputs;
      [
        # Overlays that we output
        overlays.default
      ]);
  };


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
