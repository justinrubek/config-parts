{pkgs, ...}: {
  # `default.nix` is the configuration entrypoint, but you can include any other needed module via `import`
  imports = [./hardware.nix];

  environment.systemPackages = [pkgs.cowsay];
}
