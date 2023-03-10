{ config, lib, pkgs, ... }:
{
  # If not present then warning and will be set to latest release during build
  system.stateVersion = "22.11";

  boot.kernelParams = [ "console=ttyS0" ];

  # TODO: How to handle sudo esculation
  security.sudo.wheelNeedsPassword = false;

  networking.firewall.allowedTCPPorts = [ 80 ];

  environment.systemPackages = with pkgs; [
    rsyslog
    vim
    git
  ];

  # Easy test of the service using logger
  # logger -n 127.0.0.1 -P 514 --tcp "simple test"
  # cat /var/log/rsyslog/<hostname>/root.log
  #services.rsyslogd = {
  #  enable = true;
  #  defaultConfig = ''
  #    module(load="imtcp")
  #    input(type="imtcp" port="514")
#
#      $template RemoteLogs,"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
#      *.* ?RemoteLogs
#      & ~
#    '';
#  };

  services.zabbixServer.enable = true;
  services.zabbixWeb = {
    enable =true;
    virtualHost = {
      hostName = "monitoring.scale.lan";
      adminAddr = "tt@localhost";  
    };
  };

  
}
