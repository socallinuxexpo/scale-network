{ ... }:
{
  imports = [
    ./bind-master
    ./bind-slave.nix
    ./frr.nix
    ./frr2.nix
    ./gitlab.nix
    ./kea-master.nix
    ./monitoring.nix
    ./mrtg.nix
    ./ntp.nix
    ./prometheus.nix
    ./rsyslogd.nix
    ./signs.nix
    ./ssh.nix
    ./wasgeht.nix
  ];
}
