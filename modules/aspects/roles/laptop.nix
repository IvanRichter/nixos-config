{ den, ... }:

{
  den.aspects.laptop.nixos = {
    # Lid behavior
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "suspend";
      LidSwitchIgnoreInhibited = false;
    };

    # Power profiles
    services.power-profiles-daemon.enable = true;
  };
}
