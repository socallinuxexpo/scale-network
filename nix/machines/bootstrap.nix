{ config, pkgs, ... }:
{
  boot = {
    kernelParams = [ "console=ttyS0,115200n8" ];
    loader.grub.extraConfig = "
    serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
    terminal_input serial
    terminal_output serial
    ";
  };

  networking = {
    firewall.enable = true;
    useDHCP = true;
    enableIPv6 = true;
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    vim
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
  };
}
