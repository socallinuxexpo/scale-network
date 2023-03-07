{ config, pkgs, lib, ... }:

# Minimal configuration for building NixOS bhyve images
# Inspiration based on hyperv-image.nix: https://github.com/NixOS/nixpkgs/blob/dd3ce3ebcc5de070edb64038fc9135c92f44a670/nixos/modules/virtualisation/hyperv-image.nix

with lib;

let
  cfg = config.bhyve;
in
{
  options = {
    bhyve = {
      baseImageSize = mkOption {
        type = with types; either (enum [ "auto" ]) int;
        default = "auto";
        example = 2048;
        description = lib.mdDoc ''
          The size of the bhyve base image in MiB.
        '';
      };
      vmDerivationName = mkOption {
        type = types.str;
        default = "nixos-bhyve-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
        description = lib.mdDoc ''
          The name of the derivation for the bhyve appliance.
        '';
      };
    };
  };

  config = {
    system.build.bhyveImage = import "${pkgs.path}/nixos/lib/make-disk-image.nix" {
      inherit config lib pkgs;
      name = cfg.vmDerivationName;
      format = "raw";
      diskSize = cfg.baseImageSize;
      # TODO: Check out uefi
      partitionTableType = "legacy";
    };

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };

    boot.growPartition = true;
    boot.initrd.availableKernelModules = [ "nvme" ];
    boot.loader.grub = {
      device = "/dev/sda";
    };
  };
}
