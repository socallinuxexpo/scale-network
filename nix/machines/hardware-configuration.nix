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
      device = "zroot/local/root";
      fsType = "zfs";
    };

  # Originally was by-uuid but changed to by-label to make agnostic 
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    {
      device = "zroot/local/nix";
      fsType = "zfs";
    };

  fileSystems."/home" =
    {
      device = "zroot/safe/home";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    {
      device = "zroot/safe/persist";
      fsType = "zfs";
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
