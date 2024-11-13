{ pkgs, ... }:
{
  services.gitlab-runner = {
    enable = true;
    gracefulTermination = true;
    services = {
      shell = {
        # make sure this is a quote path so it doesnt end up in /nix/store
        authenticationTokenConfigFile = "/persist/etc/gitlab/shellAuthToken.env";
        executor = "shell";
      };
    };
  };

  # include for gl-runner cli
  environment.systemPackages = [ pkgs.gitlab-runner ];
}
