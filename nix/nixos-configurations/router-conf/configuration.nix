{
  ...
}:
{
  scale-network = {
    base.enable = true;
    services.frr.enable = true;
    services.frr.router-id = "10.1.1.2";
    services.frr.broadcast-interface = [
      "fiber0"
      "fiber1"
    ];
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
