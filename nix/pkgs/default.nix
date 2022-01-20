{ pkgs ? import <nixpkgs> { } }:

rec {
  serverspec = pkgs.callPackage ./serverspec { };
  scaleGems = pkgs.callPackage ./scaleGems {};
}
