{ ... }:
let
  port = 9100;
in
{
  networking.firewall.allowedTCPPorts = [ port ];

  services.prometheus.exporters.node = {
    enable = true;
    port = port;
    enabledCollectors = [
      "logind"
      "systemd"
      "network_route"
    ];
    disabledCollectors = [
      "textfile"
    ];
  };
}
