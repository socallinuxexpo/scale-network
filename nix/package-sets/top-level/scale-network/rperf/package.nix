{
  pkgs,
  libs,
  stdenv,
  fetchFromGitHub,
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "rperf";
  version = "0.1.23";
  checkType = "debug";

  src = fetchFromGitHub {
    owner = "mfreeman451";
    repo = "rperf";
    rev = "72a02ce0142e7d4da68126ed41522191785824da";
    hash = "sha256-gTdp7LpPwWi6hUu62hMPYbdaLCdQNWPl/VxIrE91vww=";
  };

  nativeBuildInputs = with rustPlatform; [     
    rustc
    cargo
  ];
  cargoHash = libs.fakeHash;
  cargoBuildFlags = [
    "--release"
  ];

  meta = {
    description = "A Rust implementation of the iperf3 tool.";
    homepage = "https://github.com/mfreeman451/rperf";
  };
}


# with import <nixpkgs> { };

# rustPlatform.buildRustPackage rec {
#   pname = "rperf";
#   version = "0.1.23";
#   checkType = "debug";

#   src = fetchFromGitHub {
#     owner = "mfreeman451";
#     repo = "rperf";
#     rev = "72a02ce0142e7d4da68126ed41522191785824da";
#     hash = "sha256-gTdp7LpPwWi6hUu62hMPYbdaLCdQNWPl/VxIrE91vww=";
#   };

#   nativeBuildInputs = with rustPlatform; [     
#     rustc
#     cargo
#   ];
#   cargoHash = lib.fakeHash;
#   cargoBuildFlags = [
#     "--release"
#   ];

#   meta = {
#     description = "A Rust implementation of the iperf3 tool.";
#     homepage = "https://github.com/mfreeman451/rperf";
#   };
# }

