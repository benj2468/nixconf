let
  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIuNWcOuPAj6eArZ2t513v7FoTRJq9gOvYKRwzXuzRsp";
  rabin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAeofWvYHMVo+FKERUYbIpTsWzFP3EJ7j20bsc9pwByi";
  bcape = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMeJ7HXizPkhG12CRksRPRbqgIaWUWqIw0PEM7/+V7Qj";
  bcape-gantz = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnzxkEIglEd359gj7fUp48N3VnX7bVjBkVzrAuHdvOL";
  gantz = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFW89oseS2aGGT5RvUcb9CXFdndMYIp6Drswhto1xfys";

  users = [ admin bcape bcape-gantz ];
  machines = [ rabin gantz ];
in
{
  "rabin-dashboard.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-runner-1.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-runner-2.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-runner-3.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-runner-4.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-runner-5.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-runner-beta.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-secret-key-base.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-otp-key-base.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-db-key-base.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-ar-salt.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-ar-primary-key.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-ar-deterministic-key.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-initial-root-password.age".publicKeys = users ++ [ rabin ];
  "rabin-ca-inter-key.age".publicKeys = users ++ [ rabin ];
  "rabin-ca-inter-password.age".publicKeys = users ++ [ rabin ];
  "haganah-cache.age".publicKeys = users ++ machines;
  # The R2 binary cache (github.com/benj2468/haganah-infra, cloudflare/):
  # its signing key, and the nix daemon's read-only credentials for the bucket.
  "haganah-nix-cache-1.age".publicKeys = users ++ machines;
  "haganah-nix-cache-r2.age".publicKeys = users ++ machines;
  "ci-private-key.age".publicKeys = users ++ machines;
  # The key the haganah hosts' nix daemons use to reach rabin as a remote
  # builder (nix.sshServe there, nix.buildMachines everywhere else).
  "haganah-builder-key.age".publicKeys = users ++ machines;
}
