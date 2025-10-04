{
  description = "X Minecraft Launcher (XMCL) - A modern Minecraft launcher";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
    ];

    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs: {
      default = pkgs.callPackage ./package.nix {};
    });
    formatter = forAllSystems (pkgs: pkgs.alejandra);
    homeModules.xmcl = import ./hm-module.nix;
  };
}
