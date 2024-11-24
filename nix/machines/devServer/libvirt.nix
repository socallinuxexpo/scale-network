{ config, ... }:
{
  security.polkit.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      ovmf.enable = true;
      runAsRoot = false;
    };
    onBoot = "ignore";
    onShutdown = "shutdown";

    hooks.qemu = {
      dynamic-ssh = ./dynamic-ssh.sh;
    };
  };



  # Add any users in the 'wheel' group to the 'libvirt' group.
  users.groups.libvirt.members = builtins.filter (
    x: builtins.elem "wheel" config.users.users."${x}".extraGroups
  ) (builtins.attrNames config.users.users);
}
