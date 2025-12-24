{ docker-nixpkgs
, nixVersions
, writeTextFile
, extraContents ? [ ]
}:
docker-nixpkgs.nix.override {
  nix = nixVersions.stable;
  extraContents = [
    (writeTextFile {
      name = "nix.conf";
      destination = "/etc/nix/nix.conf";
      text = ''
        accept-flake-config = true
        experimental-features = nix-command flakes
        max-jobs = auto
        extra-substituters = https://cache.haganah.net
        extra-trusted-public-keys = cache.haganah.net:F9mVI5kLMhuykafiB9juKqBpdY4TFg25yPUBn9+yaqo=
      '';
    })
  ] ++ extraContents;

  extraEnv = [
    "PATH=/root/.nix-profile/bin:/usr/bin:/bin" # Not sure how to just prepend
  ];
}
