{ config, lib, pkgs, ... }:
let
  #dhcpv4config = pkgs.scaleTemplates.gomplateFile "dhcp4" ./kea/dhcpv4.tmpl ../../../inventory.json;
in
{
  # If not present then warning and will be set to latest release during build
  system.stateVersion = "22.11";

  boot.kernelParams = [ "console=ttyS0" ];

  users.extraUsers.root.password = "";

  users.users = {
    rherna = {
      isNormalUser = true;
      uid = 2005;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEiESod7DOT2cmT2QEYjBIrzYqTDnJLld1em3doDROq" ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    kea
    expect
    scaleInventory
  ];

  services = {
    openssh = {
      enable = true;
    };
    kea = {
      dhcp4 = {
        enable = true;
        configFile = "${pkgs.scaleInventory}/config/kea.json";
      };
    };
  };
}
