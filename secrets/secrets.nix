let
  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIuNWcOuPAj6eArZ2t513v7FoTRJq9gOvYKRwzXuzRsp";
  rabin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAeofWvYHMVo+FKERUYbIpTsWzFP3EJ7j20bsc9pwByi";
  bcape = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMeJ7HXizPkhG12CRksRPRbqgIaWUWqIw0PEM7/+V7Qj";
  gantz = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFW89oseS2aGGT5RvUcb9CXFdndMYIp6Drswhto1xfys";

  users = [ admin bcape ];
  machines = [ rabin gantz ];
in
{
  "rabin-dashboard.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-runner-1.age".publicKeys = users ++ [ rabin ];
  "rabin-gitlab-runner-2.age".publicKeys = users ++ [ rabin ];
  "rabin-ca-inter-key.age".publicKeys = users ++ [ rabin ];
  "rabin-ca-inter-password.age".publicKeys = users ++ [ rabin ];
  "haganah-cache.age".publicKeys = users ++ machines;
}
