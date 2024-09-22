{
  config,
  lib,
  pkgs,
  ...
}:
{

  boot.kernelParams = [ "console=ttyS0" ];

  networking = {
    firewall.allowedTCPPorts = [ 514 ];
  };

  # TODO: How to handle sudo esculation
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    rsyslog
    vim
    git
  ];

  # Easy test of the service using logger
  # logger -n 127.0.0.1 -P 514 --tcp "simple test"
  # cat /var/log/rsyslog/<hostname>/root.log
  services.rsyslogd = {
    enable = true;
    defaultConfig = ''
      module(load="imtcp")
      input(type="imtcp" port="514")

      $template RemoteLogs,"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
      *.* ?RemoteLogs
      & ~
    '';
  };
}
