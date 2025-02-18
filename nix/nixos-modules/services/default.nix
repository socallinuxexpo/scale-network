{ ... }:
{
  imports = [
    ./bind-master.nix
    ./gitlab.nix
    ./kea-master.nix
    ./prometheus.nix
    ./ssh4vms.nix
  ];
}
