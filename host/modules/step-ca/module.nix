{ lib, libx, config, ... }:
let
  stepPerms = {
    owner = "step-ca";
    group = "step-ca";
  };

  rabin-ca-root = ./root.crt;
  rabin-ca-inter-crt = ./inter.crt;
in
{
  options.haganah.security.ca = {
    type = lib.mkOption {
      type = lib.types.enum [ "server" "client" ];
      default = "client";
    };
  };

  config = lib.mkMerge [{
    security.pki.certificateFiles = [
      rabin-ca-root
      rabin-ca-inter-crt
    ];
  }
    (lib.mkIf (config.haganah.security.ca.type == "server") {

      age.secrets = {
        rabin-ca-inter-key = libx.mkSecret "rabin-ca-inter-key" stepPerms;
        rabin-ca-inter-password = libx.mkSecret "rabin-ca-inter-password" stepPerms;
      };

      services.step-ca = with config.age.secrets; {
        enable = true;
        address = "127.0.0.1";
        port = 5443;
        settings = {
          root = rabin-ca-root;
          crt = rabin-ca-inter-crt;
          key = rabin-ca-inter-key.path;
          address = ":5443";
          dnsNames = [
            "127.0.0.1"
            # Do I need this?
            "100.73.51.55"
            # Do I need this?
            "ca.haganah.net"
          ];
          logger.format = "text";
          db = {
            type = "badgerv2";
            dataSource = "/var/lib/step-ca/db";
          };
          authority = {
            provisioners = [
              {
                type = "ACME";
                name = "acme";
                claims = {
                  enableSSHCA = true;
                  disableRenewal = true;
                  allowrenewalAfterExpiry = false;
                  disableSmallstepExtensions = false;
                };
                options = {
                  x509 = { };
                  ssh = { };
                };
              }
            ];
            tempalte = { };
            backdate = "1m0s";
          };
          tls = {
            cipherSuites = [
              "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
              "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
            ];
            minVersion = 1.2;
            maxVersion = 1.3;
            renegotiation = false;
          };
          commonName = "Step Online CA";
        };
        intermediatePasswordFile = rabin-ca-inter-password.path;
      };
    })];
}
