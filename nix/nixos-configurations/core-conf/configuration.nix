{ ... }:
{
  scale-network = {
    base.enable = true;

    libvirt.enable = true;

    services.alloy.enable = true;
    services.bindMaster.enable = true;
    services.keaMaster.enable = true;
    services.monitoring.enable = true;
    services.mrtg.enable = false;
    services.ntp.enable = true;
    services.rsyslogd.enable = true;
    services.ssh.enable = true;
    services.wasgeht.enable = true;

    timeServers.enable = true;

    users.berkhan.enable = true;
    users.conjones.enable = true;
    users.djacu.enable = true;
    users.dlang.enable = true;
    users.erikreinert.enable = true;
    users.gene.enable = true;
    users.jsh.enable = true;
    users.kylerisse.enable = true;
    users.owen.enable = true;
    users.rhamel.enable = true;
    users.rob.enable = true;
    users.root.enable = true;
    users.ruebenramirez.enable = true;
    users.samuel.enable = true;
  };
}
