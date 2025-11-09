{
  writeShellApplication,
  openssh,
}:
writeShellApplication {
  name = "massflash";
  runtimeInputs = [
    openssh
  ];
  text = builtins.readFile ./massflash;
}
