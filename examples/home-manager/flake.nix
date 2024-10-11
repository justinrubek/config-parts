{
  inputs = {
    config-parts = {
      url = "github:justinrubek/config-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      imports = [
        inputs.config-parts.flakeModules.home
      ];

      config-parts.home = {
        # shared modules are applied to all configurations
        modules.shared = [
          ({pkgs, ...}: {home.packages = [pkgs.hello];})
        ];

        configurations = {
          "user@host".system = "x86_64-linux";
        };
      };
    };
}
