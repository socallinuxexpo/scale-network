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
      device = "/dev/disk/by-uuid/C59D-3BB6";
      fsType = "vfat";
    };
  fileSystems."/boot2" =
    {
      device = "/dev/disk/by-uuid/C59D-7616";
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
  # to generate: head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "4592a693";
}
