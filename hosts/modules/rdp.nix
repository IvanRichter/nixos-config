{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    freerdp
  ];
}
