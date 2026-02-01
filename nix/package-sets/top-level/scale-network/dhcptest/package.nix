{
  lib,
  stdenv,
  dmd,
  fetchFromGitHub,
}:

stdenv.mkDerivation {
  pname = "dhcptest";
  version = "0.9-unstable-2024-03-20";

  src = fetchFromGitHub {
    owner = "CyberShadow";
    repo = "dhcptest";
    rev = "4807603943e7ab984964ad549aeb8b63e0b0b5a2";
    hash = "sha256-KeICp8rum550lFNbeArWyCff9sDd9nxrbltVXi7yBvI=";
  };

  nativeBuildInputs = [ dmd ];

  buildPhase = ''
    dmd dhcptest.d
  '';

  installPhase = ''
    install -Dt $out/bin dhcptest
  '';

  meta.platforms = [
    "x86_64-linux"
    "i686-linux"
    "x86_64-darwin"
  ];
}
