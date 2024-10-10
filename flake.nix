{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} ({flake-parts-lib, ...}: let
      inherit (flake-parts-lib) importApply;

      flakeModules = {
        darwin = importApply ./nix-darwin.nix {
          inherit (inputs) nixpkgs systems;
        };
        home = importApply ./home-manager.nix {
          inherit (inputs) nixpkgs systems;
        };
        nixos = importApply ./nixos.nix {
          inherit (inputs) nixpkgs systems;
        };
      };
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
