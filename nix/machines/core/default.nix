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

  networking.usePredictableInterfaceNames = false;
  # Make sure that the makes of these files are actually lexicographically before 99-default.link provides by systemd defaults since first match wins
  # Ref: https://github.com/systemd/systemd/issues/9227#issuecomment-395500679
  systemd.network = {
    enable = true;
    links = {
      "10-lan" = {
        matchConfig = { OriginalName = "*"; };
        linkConfig = { MACAddress = "58:9c:fc:00:38:5f"; MACAddressPolicy = "none"; };
      };
    };
    networks = {
      "10-lan" = {
        address = [ "10.0.3.5/24" "2001:470:f0fb:103::5/64" ];
        gateway = [ "10.0.3.1" ];
        matchConfig = { Name = "eth0"; };
      };
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
