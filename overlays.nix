{inputs}:
with inputs; {
  nixpkgs.overlays = [
    fenix.overlays.default
  ];

  imports = [
    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.bcape = import ./home;
      };
    }
  ];
}
