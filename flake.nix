{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    home = {
      url = "git+file:./home";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager?ref=release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    utils.url = "github:numtide/flake-utils";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , fenix
    , utils
    , home
    , treefmt-nix
    , ...
    } @ inputs:
    let
      overlay = import ./overlays;

      systemSpecific = utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };

          # Eval the treefmt modules from ./treefmt.nix
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;



        in
        {
          packages = { inherit pkgs; };
          overlays.default = overlay;
          formatter = treefmtEval.config.build.wrapper;
        }
      );
    in
    systemSpecific
    // {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.bcape = { ... }: {
                imports = [
                  (import home)
                  ./home.nix
                ];
              };
            };
          }

          {
            nixpkgs.overlays = [ fenix.overlays.default overlay ];
          }

          ./configuration.nix
        ];
      };
    };
}
