{
  config,
  lib,
  ...
}:
let
  cfg = config.scale-network.libvirt;

  inherit (builtins)
    attrNames
    elem
    filter
    ;

  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.libvirt.enable = mkEnableOption "SCaLE network libvirt setup";

  config = mkIf cfg.enable {
    security.polkit.enable = true;

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        ovmf.enable = true;
        runAsRoot = false;
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
    };

    # bridge traffic goes directly to the vm instead of through host firewall
    boot.kernel.sysctl = {
      "net.bridge.bridge-nf-call-ip6tables" = 0;
      "net.bridge.bridge-nf-call-iptables" = 0;
    };

    # Add any users in the 'wheel' group to the 'libvirt' group.
    users.groups.libvirt.members = (
      filter (x: elem "wheel" config.users.users."${x}".extraGroups) (attrNames config.users.users)
    );
  };
}
