{
  den,
  inputs,
  ...
}:

{
  den.aspects.mbp-m2max.includes = with den.aspects; [
    workstation
    laptop
    apple-silicon
  ];

  den.aspects.mbp-m2max.nixpkgs-overlays = _: {
    kernel-asahi = import "${inputs.self}/overlays/kernel/asahi.nix";
  };

  den.aspects.mbp-m2max.nixos = {
    imports = [ "${inputs.self}/hardware/mbp-m2max/hardware-configuration.nix" ];

    # SSH
    services.openssh.enable = true;

    # Memory / swap
    zramSwap = {
      enable = true;
      memoryPercent = 50;
      algorithm = "zstd";
      priority = 100;
    };
    boot.kernel.sysctl = {
      "vm.swappiness" = 80;
      "vm.vfs_cache_pressure" = 50;
    };

    # Firmware
    hardware.asahi.enable = true;
    hardware.asahi.avd.codecs = [ "all" ];
    hardware.asahi.avd.vaapi-support = true;

    # Keyboard / input
    boot.kernelModules = [
      "hid_apple"
      "uinput"
    ];

    # Fn <-> Ctrl, Opt <-> Cmd, F1–F12 as real keys
    boot.extraModprobeConfig = ''
      options hid_apple swap_fn_leftctrl=1 swap_opt_cmd=1 fnmode=2
    '';

    hardware.uinput.enable = true;

    # Right Meta -> Delete
    services.keyd = {
      enable = true;
      keyboards.default.settings.main.rightmeta = "delete";
    };

    # -- Power management & display tweaks --
    # Force s2idle + tweak PCI/USB behavior
    # Enable full native panel (disable fake black bar over notch)
    boot.kernelParams = [
      "mem_sleep_default=s2idle"
      "usbcore.autosuspend=1"
      "pci=pcie_bus_perf"
      "appledrm.show_notch=1"
    ];

    # Session behavior
    services.logind.settings.Login = {
      IdleAction = "ignore";
      KillUserProcesses = true;
    };

    # Disable OOM killer
    systemd.oomd.enable = false;

    # Disable USB/BT wakeups
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
      SUBSYSTEM=="bluetooth", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
    '';
  };

  den.aspects.apple-silicon.nixos.imports = [
    inputs.apple-silicon.nixosModules.apple-silicon-support
  ];
}
