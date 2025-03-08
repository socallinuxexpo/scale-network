{
  ...
}:
{
  scale-network = {
    base.enable = true;
    services.keaMaster.enable = true;
    services.bindMaster.enable = true;
    services.ntp.enable = true;
    services.rsyslogd.enable = true;
    services.signs.enable = true;
    services.monitoring.enable = true;
    services.mrtg.enable = true;
    services.prometheus.enable = true;
    services.ssh.enable = true;
    services.wasgeht.enable = true;
    libvirt.enable = true;
    timeServers.enable = true;

    users.berkhan.enable = true;
    users.conjones.enable = true;
    users.dlang.enable = true;
    users.jsh.enable = true;
    users.kylerisse.enable = true;
    users.owen.enable = true;
    users.rhamel.enable = true;
    users.rob.enable = true;
    users.root.enable = true;
    users.ruebenramirez.enable = true;
    users.gene.enable = true;
    users.erikreinert.enable = true;
    users.samuel.enable = true;
  };
}
