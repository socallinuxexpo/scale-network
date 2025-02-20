{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # *sas drivers required for Lenovo System x3650 M5 Machine Type: 8871AC1
  boot.initrd.availableKernelModules = [
    "ehci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "mpt3sas"
    "megaraid_sas"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "zroot/root";
    fsType = "zfs";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "nofail" ];
  };
  fileSystems."/boot2" = {
    device = "/dev/disk/by-label/BOOT2";
    fsType = "vfat";
    options = [ "nofail" ];
  };
  fileSystems."/nix" = {
    device = "zroot/nix";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "zroot/home";
    fsType = "zfs";
  };

  fileSystems."/persist" = {
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
      {
        devices = [ "nodev" ];
        path = "/boot";
      }
      {
        devices = [ "nodev" ];
        path = "/boot2";
      }
    ];
  };

  # ZFS uniq system ID
  # to generate: head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "6333bc40";
}
