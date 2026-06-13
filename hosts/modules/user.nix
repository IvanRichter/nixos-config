{ config, pkgs, ... }:

{
  users.users.ivan = {
    isNormalUser = true;
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "render"
      "plugdev"
    ];
    packages = with pkgs; [
      syncthing
      fish
      fishPlugins.async-prompt
      fishPlugins.puffer
    ];
  };

  programs.fish = {
    enable = true;
    useBabelfish = true;
    shellInit = ''
      starship init fish | source
    '';
    interactiveShellInit = ''
      zoxide init fish --cmd cd | source

      if command -q nix-your-shell
        nix-your-shell fish | source
      end

      function fish_greeting
      end

      function gibbor-update --description "Refresh the local Gibbor source checkout"
        set -l target /home/ivan/work/happy-end/gibbor-src
        set -l tmp (mktemp -d); or return 1
        set -l code 0

        scp -P 62884 richter@www.gibbor.eu:~/gibbor_source.tgz "$tmp/gibbor_source.tgz"; and \
          mkdir "$tmp/extract"; and \
          tar -xzf "$tmp/gibbor_source.tgz" -C "$tmp/extract"; and \
          rm -rf "$target"; and \
          mkdir -p "$target"
        set code $status

        if test $code -ne 0
          rm -rf "$tmp"
          return $code
        end

        set -l source "$tmp/extract"
        set -l entries "$source"/*
        if test (count $entries) -eq 1; and test -d "$entries[1]"
          set source "$entries[1]"
        end

        cp -a "$source/." "$target"/
        set code $status
        rm -rf "$tmp"
        return $code
      end
    '';
    shellAliases = {
      pbcopy = "wl-copy";
      pbpaste = "wl-paste";
      neofetch = "macchina";
      ls = "eza --group-directories-first";
      cat = "bat -pp";
      grep = "rg --no-heading --color=auto";
      find = "fd";
      top = "btm";
      dig = "doggo";
      jq = "jaq";
      du = "dust";
      cd = "z";
      nano = "micro";
      torrent = "xdg-open http://localhost:3030/web/";
    };
  };

  services.syncthing = {
    enable = true;
    user = "ivan";
    dataDir = "/home/ivan";
    configDir = "/home/ivan/.config/syncthing";
    openDefaultPorts = true;
    overrideDevices = false;
    overrideFolders = false;
  };

  security.sudo-rs = {
    enable = true;
  };
}
