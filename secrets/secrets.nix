let
  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIuNWcOuPAj6eArZ2t513v7FoTRJq9gOvYKRwzXuzRsp";
  rabin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAeofWvYHMVo+FKERUYbIpTsWzFP3EJ7j20bsc9pwByi";

  users = [ admin ];
in
{
  "rabin-dashboard.age".publicKeys = users ++ [ rabin ];
}
