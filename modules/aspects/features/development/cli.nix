{ den, ... }:

{
  den.aspects.cli = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        # Network / HTTP
        wget
        xh
        gip
        gping

        # Archives
        unzip
        zip

        # Document processing
        ghostscript

        # File navigation
        tree
        fd

        # File/system utilities
        lsof
        file
        usbutils
        evtest
        ripgrep
        sd
        dust
        ast-grep
        tokei

        # JSON processing
        jaq
        jf

        # YAML processing
        yq-go

        # Nix tooling
        nix-output-monitor
        nixfmt

        # System info

        # Clipboard
        wl-clipboard-rs

        # DNS
        doggo
      ];
    };

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        home.sessionVariables.EDITOR = lib.getExe config.programs.micro.package;

        programs.bat.enable = true;

        programs.broot = {
          enable = true;
          enableFishIntegration = true;
        };

        programs.bottom.enable = true;

        programs.fzf = {
          enable = true;
          # Skim provides the Fish keybindings
          enableFishIntegration = false;
        };

        programs.micro = {
          enable = true;
          package = pkgs.micro-full;
        };

        xdg.configFile."micro/bindings.json".text = builtins.toJSON {
          "Ctrl-q" = "None";
          "Ctrl-x" = "Quit";
        };

        programs.skim = {
          enable = true;
          enableFishIntegration = true;
        };

        programs.yazi = {
          enable = true;
          enableFishIntegration = true;
        };

        programs.tealdeer.enable = true;
      };
  };
}
