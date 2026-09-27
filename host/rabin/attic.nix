{ libx, config, ... }:
# A push-based Nix binary cache at https://cache.haganah.net.
#
# Attic rather than Harmonia: Harmonia serves this host's own /nix/store, so a
# remote runner could only fill it by `nix copy`-ing into rabin's system store
# as a trusted user, and anything allowed to push could plant a path rabin later
# builds against. Attic keeps its own storage, takes pushes over HTTP with
# per-cache tokens, and signs with its own key — a bad push reaches the cache's
# consumers, never this host.
#
# One-time setup after the first deploy (tokens are JWTs signed by the secret
# in `attic-server-token`):
#
#   sudo atticd-atticadm make-token --sub admin --validity '1y' \
#     --pull '*' --push '*' --create-cache '*' --configure-cache '*' \
#     --configure-cache-retention '*' --destroy-cache '*' --delete '*'
#   attic login haganah https://cache.haganah.net <admin token>
#   attic cache create haganah:<cache>
#   attic cache info haganah:<cache>          # prints the public key
#
# and per CI consumer a push token scoped to its own cache:
#
#   sudo atticd-atticadm make-token --sub <project>-ci --validity '1y' \
#     --pull <cache> --push <cache>
let
  port = 8085;
in
{
  age.secrets.attic-server-token = libx.mkSecret "rabin-attic-server-token" { };

  services.atticd = {
    enable = true;
    # Holds ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64. (The module's own
    # assertion text says `…_RS256_SECRET`; the binary reads `_BASE64`.)
    environmentFile = config.age.secrets.attic-server-token.path;
    settings = {
      listen = "127.0.0.1:${toString port}";
      api-endpoint = "https://cache.haganah.net/";
      # CI pushes whole workspace closures; without a retention period the
      # local storage only ever grows. A path pulled again is kept alive.
      garbage-collection.default-retention-period = "30 days";
    };
  };

  networking.hosts."100.73.51.55" = [ "cache.haganah.net" ];

  services.nginx.virtualHosts."cache.haganah.net" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://127.0.0.1:${toString port}";
  };
}
