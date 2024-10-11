{
  inputs = {
    config-parts = {
      url = "github:justinrubek/config-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      imports = [
        inputs.config-parts.flakeModules.nixos
      ];

      config-parts.nixos = {
        # shared modules are applied to all configurations
        modules.shared = [
          ({pkgs, ...}: {environment.systemPackages = [pkgs.hello];})
        ];

        configurations = {
          host.system = "x86_64-linux";
        };
      };
    };
}
