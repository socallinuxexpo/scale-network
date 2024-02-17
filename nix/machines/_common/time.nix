{
  # Sets the default timeservers for everything thats using the default: systemd-timesyncd
  networking.timeServers = [
    "ntpconf.scale.lan"
    "ntpexpo.scale.lan"
  ];
}
