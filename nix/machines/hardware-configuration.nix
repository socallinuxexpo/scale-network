{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "zroot/root";
      fsType = "zfs";
    };
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-id/ata-C400-MTFDDAK128MAM_00000000121803393880-part1";
      fsType = "vfat";
    };
  fileSystems."/boot2" =
    {
      device = "/dev/disk/by-id/ata-WDC_WD10EADS-00L5B1_WD-WCAU47011840-part1";
      fsType = "vfat";
    };
  fileSystems."/nix" =
    {
      device = "zroot/nix";
      fsType = "zfs";
    };

  fileSystems."/home" =
    {
      device = "zroot/home";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    {
      device = "zroot/persist";
      fsType = "zfs";
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Use the systemd-boot EFI boot loader.
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
        { devices = [ "nodev" ]; path = "/boot"; }
        { devices = [ "nodev" ]; path = "/boot2"; }
    ];
  };

  # ZFS uniq system ID
  networking.hostId = "74405d06";
}
