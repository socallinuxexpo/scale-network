{
  ...
}:
{
  scale-network = {
    base.enable = true;
    # router.expo = {
    #   enable = true;
    #   frrBorderInterface = "sfp0";
    #   frrConferenceInterface = "sfp1";
    # };
    services.ssh.enable = true;
    services.alloy = {
      enable = true;
      remoteWrite.url = "http://10.128.3.20:3200/api/v1/push";
    };
    users.conjones.enable = true;
    users.djacu.enable = true;
    users.jared.enable = true;
    users.kylerisse.enable = true;
    users.owen.enable = true;
    users.rhamel.enable = true;
    users.rob.enable = true;
    users.root.enable = true;
    users.erikreinert.enable = true;
  };
}
