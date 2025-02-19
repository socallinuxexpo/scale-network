{ ... }:
{
  imports = [
    ./bind-master.nix
    ./bind-slave.nix
    ./gitlab.nix
    ./kea-master.nix
    ./ntp.nix
    ./prometheus.nix
    ./ssh4vms.nix
  ];
}
