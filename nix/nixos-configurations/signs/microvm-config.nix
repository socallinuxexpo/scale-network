{ config, ... }:

{
  microvm.qemu.serialConsole = false;
  microvm.qemu.extraArgs = [
    "-serial"
    "pty"
  ];

  microvm.vcpu = 2;
  microvm.mem = 4096;
  microvm.interfaces = [
    {
      type = "tap";
      id = "vm-${config.networking.hostName}";
      mac = "58:9c:fc:06:1c:79";
    }
  ];

  microvm.volumes = [
    {
      image = "/persist/microvm/${config.networking.hostName}.img";
      mountPoint = "/var";
      size = 40000;
    }
  ];
}
