{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    fenix,
    utils,
    ...
  } @ inputs: let
    overlay = import ./pkgs/overlay.nix;

    systemSpecific = utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [overlay];
        };
      in {
        packages = {inherit pkgs;};
        overlays.default = overlay;
      }
    );
  in
    systemSpecific
    // {
      nixosConfigurations.nixos-vm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          (import ./overlays.nix {
            inherit inputs;
            overlays = [overlay];
          })
          ./configuration.nix
        ];
      };
    };
}
