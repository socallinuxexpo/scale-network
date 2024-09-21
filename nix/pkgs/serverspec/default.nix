{ bundlerEnv }:

bundlerEnv {
  name = "serverspec";
  gemdir = ./.;
}
