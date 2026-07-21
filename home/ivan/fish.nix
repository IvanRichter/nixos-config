{ pkgs, ... }:

{
  programs.fish = {
    enable = true;

    plugins = [
      {
        name = "async-prompt";
        src = pkgs.fishPlugins.async-prompt.src;
      }
      {
        name = "puffer";
        src = pkgs.fishPlugins.puffer.src;
      }
    ];

    functions = {
      fish_greeting = "";

      gibbor-update = {
        description = "Refresh the local Gibbor source checkout";
        body = ''
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
        '';
      };
    };

    shellAliases = {
      pbcopy = "wl-copy";
      pbpaste = "wl-paste";
      neofetch = "macchina";
      cat = "bat -pp";
      grep = "rg --no-heading --color=auto";
      find = "fd";
      top = "btm";
      dig = "doggo";
      jq = "jaq";
      du = "dust";
      nano = "micro";
      torrent = "xdg-open http://localhost:3030/web/";
    };
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    extraOptions = [ "--group-directories-first" ];
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [
      "--cmd"
      "cd"
    ];
  };

  programs.nix-your-shell = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };
}
