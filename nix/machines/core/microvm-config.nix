{ config, ... }:

{
  microvm.qemu.serialConsole = false;
  microvm.qemu.extraArgs = [
    "-serial" "pty"
  ];

  microvm.vcpu = 4;
  microvm.mem = 8192;
  microvm.interfaces = [
    {
      type = "tap";
      id = "vm-${config.networking.hostName}";
      # Will eventually pull this from facts
      mac =  if config.networking.hostName == "coremaster" then "4c:72:b9:7c:41:17" else "58:9c:fc:00:38:5f";
    }
  ];

  microvm.volumes = [ { image = "/persist/microvm/${config.networking.hostName}.img"; mountPoint = "/var"; size = 40000; }];
}
