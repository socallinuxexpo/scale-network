{
  ...
}:
{
  scale-network = {
    base.enable = true;
    router.conference = {
      enable = true;
      frrBorderInterface = "fiber0";
      frrExpoInterface = "fiber1";
    };
    services.ssh.enable = true;

    users.conjones.enable = true;
    users.djacu.enable = true;
    users.kylerisse.enable = true;
    users.owen.enable = true;
    users.rhamel.enable = true;
    users.rob.enable = true;
    users.root.enable = true;
    users.erikreinert.enable = true;
  };
}
