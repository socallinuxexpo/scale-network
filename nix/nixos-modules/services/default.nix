{ ... }:
{
  imports = [
    ./bind-master.nix
    ./gitlab.nix
    ./prometheus.nix
    ./ssh4vms.nix
  ];
}
