{ config, lib, pkgs, ... }:
{

  imports = [
    ./cachecache.nix
  ];

  boot.kernelParams = [ "console=ttyS0" ];

  networking = {
    firewall.allowedTCPPorts = [ 80 443 8080 8081 5000 ];
  };

  networking.hostName = "cache";

  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        name = "e*0*";
        enable = true;
        address = [ "10.0.3.16/24" "2001:470:f026:103::16/64" ];
        gateway = [ "10.0.3.1" ];
        networkConfig = {
          IPv6PrivacyExtensions = false;
        };
      };
    };
  };
  environment.systemPackages = with pkgs; [
    rsyslog
    vim
    git
  ];
}
