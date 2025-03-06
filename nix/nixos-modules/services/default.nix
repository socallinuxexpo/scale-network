{ ... }:
{
  imports = [
    ./bind-master
    ./bind-slave.nix
    ./cert-generator.nix
    ./gitlab.nix
    ./kea-master.nix
    ./monitoring.nix
    ./ntp.nix
    ./prometheus.nix
    ./rsyslogd.nix
    ./signs.nix
    ./ssh.nix
    ./wasgeht.nix
  ];
}
