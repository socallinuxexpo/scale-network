{ ... }:
{
  scale-network = {
    base.enable = true;

    libvirt.enable = true;

    services.alloy.enable = true;
    services.alloy.keaExporter.enable = true;
    services.alloy.bindExporter.enable = true;
    services.alloy.rsyslogdLokiScrape.enable = true;
    services.bindMaster.enable = true;
    services.bindExporter.enable = true;
    services.keaMaster.enable = true;
    services.keaExporter.enable = true;
    services.monitoring.enable = true;
    services.ntp.enable = true;
    services.rsyslogd.enable = true;
    services.ssh.enable = true;
    services.wasgeht.enable = true;

    timeServers.enable = true;

    users.djacu.enable = true;
    users.dlang.enable = true;
    users.erikaker.enable = true;
    users.erikreinert.enable = true;
    users.jared.enable = true;
    users.jsh.enable = true;
    users.kylerisse.enable = true;
    users.owen.enable = true;
    users.rhamel.enable = true;
    users.rob.enable = true;
    users.root.enable = true;
  };
}
