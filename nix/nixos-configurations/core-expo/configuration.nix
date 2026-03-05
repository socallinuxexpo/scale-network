{
  ...
}:
{
  scale-network = {
    base.enable = true;
    services.alloy = {
      enable = true;
      remoteWrite.url = "http://10.128.3.20:3200/api/v1/push";
      keaExporter.enable = true;
      bindExporter.enable = true;
    };
    services.keaMaster.enable = true;
    services.keaExporter.enable = true;
    services.bindMaster.enable = true;
    services.bindExporter.enable = true;
    services.ntp.enable = true;
    services.rsyslogd.enable = true;
    services.ssh.enable = true;
    libvirt.enable = true;
    timeServers.enable = true;

    users.djacu.enable = true;
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
