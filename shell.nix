# Leverage the nix flake devShell to get pinned nixpkgs
{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  scale_python = python38.withPackages
      (pythonPackages: with pythonPackages; [ pytest pylint ]);

  # Trying to keep these pkg sets separate for later
  global = [ bash curl git jq kermit screen glibcLocales ] ++ [ scale_python ];
  ansible_sub = [ansible_2_12 ansible-lint];
  openwrt_sub = [ expect gomplate magic-wormhole tftp-hpa nettools unixtools.ping iperf3 ncurses ncurses.dev pkg-config gcc stdenv ];
  network_sub = [ perl534 ];
in
mkShell {
  buildInputs = [ global ] ++ [ ansible_sub ] ++ [ openwrt_sub ] ++ [ network_sub ];
}
