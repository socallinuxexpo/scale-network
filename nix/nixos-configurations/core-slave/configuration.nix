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
    # Turning off monitoring so we dont snmp walk
    services.monitoring.enable = false;
    services.prometheus.enable = true;
    services.ssh.enable = true;
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
  };
}
