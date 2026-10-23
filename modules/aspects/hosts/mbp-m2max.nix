{
  den,
  inputs,
  ...
}:

{
  den.aspects.mbp-m2max.includes = with den.aspects; [
    workstation
    apple-silicon
  ];

  den.aspects.mbp-m2max.nixpkgs-overlays = _: {
    kernel-asahi = import "${inputs.self}/overlays/kernel/asahi.nix";
  };

  den.aspects.mbp-m2max.nixos = {
    imports = [ "${inputs.self}/hardware/mbp-m2max/hardware-configuration.nix" ];

    # Platform & licensing
    nixpkgs.hostPlatform = "aarch64-linux";

    # Bootloader
    boot.loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      limine = {
        enable = true;
        efiSupport = true;
        biosSupport = false;
        maxGenerations = 15;
      };
    };

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
    hardware.asahi.avd.vaapi-support = true;

    # Avoid --impure until firmware can be loaded from the ESP at boot:
    # https://github.com/nix-community/nixos-apple-silicon/issues/538
    hardware.asahi.peripheralFirmwareDirectory =
      (builtins.fetchTree {
        type = "path";
        path = "/boot/vendorfw";
        # Refresh with `nix hash path /boot/vendorfw` after firmware changes
        narHash = "sha256-ItcB63aNJUQV80uWJSeWBKjOjm+Sey+jgFvNTAmyYyE=";
      }).outPath;

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

    # Align systemd sleep with kernel
    systemd.sleep.settings = {
      Sleep = {
        SuspendState = "mem";
        SuspendMode = "s2idle";
      };
    };

    # Lid behavior
    services.logind.settings = {
      Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "suspend";
        HandleLidSwitchDocked = "suspend";
        IdleAction = "ignore";
        LidSwitchIgnoreInhibited = false;
        KillUserProcesses = true;
      };
    };

    # Power profiles
    services.power-profiles-daemon.enable = true;

    # Disable OOM killer
    systemd.oomd.enable = false;

    # Disable USB/BT wakeups
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
      SUBSYSTEM=="bluetooth", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
    '';

    # -- Sleep hook --
    environment.etc."systemd/system-sleep/10-safe-suspend".text = ''
      #!/bin/sh
      set -eu
      case "$1" in
        pre)
          sync
          ;;
        post)
          :
          ;;
      esac
    '';
    environment.etc."systemd/system-sleep/10-safe-suspend".mode = "0755";

    # Run fsck in initrd if journal looks dirty
    boot.initrd.checkJournalingFS = true;
  };

  den.aspects.apple-silicon.nixos.imports = [
    inputs.apple-silicon.nixosModules.apple-silicon-support
  ];
}
