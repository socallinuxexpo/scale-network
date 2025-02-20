{ ... }:
{
  imports = [
    ./bind-master.nix
    ./bind-slave.nix
    ./gitlab.nix
    ./kea-master.nix
    ./ntp.nix
    ./prometheus.nix
    ./rsyslogd.nix
    ./signs.nix
    ./ssh4vms.nix
  ];
}
