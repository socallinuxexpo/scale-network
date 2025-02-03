{
  openssh,
  writeShellApplication,
  scale-network,
}:
writeShellApplication {
  name = "massflash";

  runtimeInputs = [
    openssh
  ];

  text = scale-network.massflashSrc;
}
