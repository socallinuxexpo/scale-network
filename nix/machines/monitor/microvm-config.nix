{ config, ... }:

{
  microvm.qemu.serialConsole = false;
  microvm.qemu.extraArgs = [
    "-serial"
    "pty"
  ];

  microvm.vcpu = 16;
  microvm.mem = 48000;
  microvm.interfaces = [
    {
      type = "tap";
      id = "vm-${config.networking.hostName}";
      # Will eventually pull this from facts
      mac = "58:9c:fc:0a:a8:f3";
    }
  ];

  microvm.volumes = [
    {
      image = "/persist/microvm/${config.networking.hostName}.img";
      mountPoint = "/var";
      size = 800000;
    }
  ];
}
