{
  inputs = {
    config-parts = {
      url = "github:justinrubek/config-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin"];
      imports = [
        inputs.config-parts.flakeModules.darwin
      ];

      config-parts.darwin = {
        # shared modules are applied to all configurations
        modules.shared = [
          ({pkgs, ...}: {environment.systemPackages = [pkgs.hello];})
        ];

        configurations = {
          host.system = "aarch64-darwin";
        };
      };
    };
}
