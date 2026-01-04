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
    };
    services.ssh.enable = true;

    users.conjones.enable = true;
    users.kylerisse.enable = true;
    users.owen.enable = true;
    users.rhamel.enable = true;
    users.rob.enable = true;
    users.root.enable = true;
    users.erikreinert.enable = true;
  };
}
