{ config, lib, pkgs, ... }:
{
  # If not present then warning and will be set to latest release during build
  system.stateVersion = "23.05";

  boot = {
    kernelParams = [ "console=ttyS0,115200n8" ];
    loader.grub.extraConfig = "
    serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
    terminal_input serial
    terminal_output serial
    ";
  };

  # TODO: How to handle sudo esculation
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    rsyslog
    vim
    git
  ];
  
  services.openssh = {
    enable = true;
    openFirewall = true;
  };
}
