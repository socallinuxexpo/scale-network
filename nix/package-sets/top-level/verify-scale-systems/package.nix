{
  jq,
  nix-eval-jobs,
  nix-output-monitor,
  stdenv,
  writeShellApplication,
}:
writeShellApplication {

  name = builtins.baseNameOf ./.;

  runtimeInputs = [
    jq
    nix-eval-jobs
    nix-output-monitor
  ];

  text = ''
    nix-eval-jobs --flake .#hydraJobs.scale-nixos-systems.${stdenv.hostPlatform.system} --constituents | \
      jq -cr '.constituents + [.drvPath] | .[] | select(.!=null) + "^*"' | \
      nom build --keep-going --no-link --print-out-paths --stdin "$@"
  '';

}
