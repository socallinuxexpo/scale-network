{ config, lib, pkgs, ... }:
{
  # If not present then warning and will be set to latest release during build
  system.stateVersion = "22.11";

  boot.kernelParams = [ "console=ttyS0" ];

  # TODO: How to handle sudo esculation
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  networking.firewall.allowedTCPPorts = [ 80 ];

  virtualisation.oci-containers = {
    containers.scale-signs = {
      environmentFiles = [ /run/secrets/scale-sign-secrets.env ];
      image = "sarcasticadmin/scale-signs:74ec903";
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
        name = "enp0*";
        enable = true;
        address = [ "10.128.3.11/24" "2001:470:f026:503::11/64" ];
        gateway = [ "10.128.3.1" ];
        # TODO: Causes double entry of [Network] in .network file
        # Need to look into unifying into one block
        extraConfig = ''
          [Network]
          IPv6Token=static:::11
          LLDP=true
          EmitLLDP=true;
          IPv6PrivacyExtensions=false
        '';
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
