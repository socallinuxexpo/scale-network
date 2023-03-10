{ config, lib, pkgs, ... }:
{
  # If not present then warning and will be set to latest release during build
  system.stateVersion = "22.11";

  boot.kernelParams = [ "console=ttyS0" ];

  # TODO: How to handle sudo esculation
  security.sudo.wheelNeedsPassword = false;

  networking.firewall.allowedTCPPorts = [ 80 ];

  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        name = "enp0*";
        enable = true;
        address = [ "10.128.3.12/24" "2001:470:f026:503::12/64" ];
        gateway = [ "10.128.3.1" ];
        # TODO: Causes double entry of [Network] in .network file
        # Need to look into unifying into one block
        extraConfig = ''
          [Network]
          IPv6Token=static:::12
          LLDP=true
          EmitLLDP=true;
          IPv6PrivacyExtensions=false
        '';
      };
    };
  };


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
