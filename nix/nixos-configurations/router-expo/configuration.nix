{
  ...
}:
{
  scale-network = {
    base.enable = true;
    router.expo = {
      enable = true;
      frrBorderInterface = "fiber0";
      frrConferenceInterface = "fiber1";
      trunkInterfaces = [
        "copper0"
        "copper1"
        "fiber2"
        "fiber3"
      ];
    };
    services.ssh.enable = true;
    services.alloy = {
      enable = true;
      remoteWrite.url = "http://10.128.3.20:3200/api/v1/push";
    };
    users.djacu.enable = true;
    users.erikreinert.enable = true;
    users.jared.enable = true;
    users.jsh.enable = true;
    users.kylerisse.enable = true;
    users.owen.enable = true;
    users.rhamel.enable = true;
    users.rob.enable = true;
    users.root.enable = true;
  };
}
