{ bundlerApp }:

bundlerApp {
  pname = "serverspec";
  gemdir = ./.;
  exes = [ "serverspec-init" ];
}
