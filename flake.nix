{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} ({flake-parts-lib, ...}: let
      inherit (flake-parts-lib) importApply;

      flakeModules.home = importApply ./home-manager.nix {inherit (inputs) home-manager nixpkgs systems;};
    in {
      systems = import inputs.systems;
      imports = [
        ./flake-parts/pre-commit.nix
        ./flake-parts/shells.nix
      ];

      flake = {
        inherit flakeModules;
      };
    });
}
