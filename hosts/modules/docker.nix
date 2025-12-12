{ config, lib, pkgs, ... }:
let
  isAarch64 = pkgs.stdenv.hostPlatform.system == "aarch64-linux";
in
{
  virtualisation.docker = {
    enable = true;
    # Make BuildKit the default
    daemon.settings.features.buildkit = true;
  };

  systemd.services.docker = {
    wants = [ ];
    after = [ "multi-user.target" ];
  };

  # Register QEMU binfmt so amd64 containers/binaries run on ARM
  boot.binfmt = lib.mkIf isAarch64 {
    emulatedSystems = [ "x86_64-linux" ];
  };

  # Tools
  environment.systemPackages = with pkgs; [
    docker
    docker-buildx
    qemu-user
  ];
}
