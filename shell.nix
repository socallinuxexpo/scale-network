# TODO: Pin this to a specific version of nixpkgs
{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  scale_pkgs = import ./nix/pkgs/default.nix { };
  scale_ruby = ruby.withPackages ( ps: with ps; [ nokogiri pry ] ++ [ scale_pkgs.scaleGems] );
  scale_python = python38.withPackages
      (pythonPackages: with pythonPackages; [ pytest pylint ]);

  # Trying to keep these pkg sets separate for later
  global = [ bash curl git jq kermit  screen glibcLocales ] ++ [ scale_python ];
  ansible_sub = [ansible_2_11 ansible-lint];
  openwrt_sub = [ expect gomplate magic-wormhole tftp-hpa ];
  network_sub = [ perl532 ];
in
mkShell {
  #buildInputs = [ global ] ++ [ ansible_sub ] ++ [ openwrt_sub ] ++ [ network_sub ] ++ [ scale_pkgs.serverspec ] ++ [ scale_ruby ];
  buildInputs = [ global ] ++ [ ansible_sub ] ++ [ openwrt_sub ] ++ [ network_sub ] ++ [ scale_ruby ];
}
