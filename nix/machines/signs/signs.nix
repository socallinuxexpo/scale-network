{ config, lib, pkgs, ... }:
{
  boot.kernelParams = [ "console=ttyS0" ];

  networking.firewall.allowedTCPPorts = [ 80 ];

  virtualisation.oci-containers = {
    containers.scale-signs = {
      environmentFiles = [ /var/lib/secrets/scale-sign-secrets.env ];
      image = "sarcasticadmin/scale-signs:1fc4dc5";
      ports = [ "80:80" ];
      extraOptions = [
        "--network=host"
      ];
    };
  };

  systemd.network = {
    enable = true;
    networks = {
      "10-lan" = {
        name = "e*0*";
        enable = true;
        address = [ "10.128.3.11/24" "2001:470:f026:503::11/64" ];
        gateway = [ "10.128.3.1" ];
        networkConfig = {
          LLDP = true;
          EmitLLDP = true;
          IPv6PrivacyExtensions = false;
        };
      };
    };
  };

  networking = {
    dhcpcd.enable = false;
    nameservers = [ "10.128.3.5" "10.0.3.5" "2001:470:f026:103::5/64" "2001:470:f026:503::5/64" ];
  };

  services = {
    openssh = {
      enable = true;
    };
  };

}
