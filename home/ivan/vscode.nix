{ config, lib, pkgs, ... }:

let
  codeBin = "${config.programs.vscode.package}/bin/code";

  # Wishlist
  want = [
    "adrianwilczynski.alpine-js-intellisense"
    "ashishalex.dataform-lsp-vscode"
    "astro-build.astro-vscode"
    "jeff-hykin.better-nix-syntax"
    "bradlc.vscode-tailwindcss"
    "docker.docker"
    "esbenp.prettier-vscode"
    "ggsimm.wgsl-literal"
    "github.copilot"
    "github.copilot-chat"
    "glenn2223.live-sass"
    "golang.go"
    "hashicorp.terraform"
    "mads-hartmann.bash-ide-vscode"
    "mechatroner.rainbow-csv"
    "ms-azuretools.vscode-containers"
    "ms-azuretools.vscode-docker"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-python.vscode-python-envs"
    "ms-vscode-remote.remote-containers"
    "openai.chatgpt"
    "polymeilex.wgsl"
    "macabeus.vscode-fluent"
    "randomfractalsinc.vscode-data-preview"
    "risingstack.astro-alpinejs-syntax-highlight"
    "ritwickdey.liveserver"
    "tamasfe.even-better-toml"
    "timonwong.shellcheck"
    "unifiedjs.vscode-mdx"
    "usernamehw.errorlens"
    "AtomMaterial.a-file-icon-vscode"
    "vue.volar"
    "xabikos.javascriptsnippets"
    "zignd.html-css-class-completion"
  ];

  # Extensions in nixpkgs
  declaredIds = [
    "astro-build.astro-vscode"        
    "jeff-hykin.better-nix-syntax"
    "bradlc.vscode-tailwindcss"       
    "esbenp.prettier-vscode"          
    "hashicorp.terraform"             
    "mechatroner.rainbow-csv"         
    "tamasfe.even-better-toml"        
    "timonwong.shellcheck"            
    "usernamehw.errorlens"            
    "vue.volar"                       
    "ms-python.python"                
    "ms-python.vscode-pylance"        
    "golang.go"                       
  ];

  # The actual derivations for those
  declaredPkgs = with pkgs.vscode-extensions; [
    astro-build.astro-vscode
    jeff-hykin.better-nix-syntax
    bradlc.vscode-tailwindcss
    esbenp.prettier-vscode
    hashicorp.terraform
    mechatroner.rainbow-csv
    tamasfe.even-better-toml
    timonwong.shellcheck
    usernamehw.errorlens
    vue.volar
    ms-python.python
    ms-python.vscode-pylance
    golang.go
  ];

  # Everything else gets installed once via the Code CLI
  missingIds = lib.subtractLists declaredIds want;

in {
  programs.vscode = {
    enable  = true;
    package = pkgs.vscode;

    # Let the fallback CLI write to the extensions dir
    mutableExtensionsDir = true;

    profiles.default = {
      extensions = declaredPkgs;

      userSettings = {
        "telemetry.telemetryLevel" = "off";
        "security.workspace.trust.untrustedFiles" = "open";
        "terminal.integrated.fontFamily" = "MesloLGS Nerd Font";
        "terminal.integrated.defaultProfile.linux" = "fish";
        "terminal.integrated.gpuAcceleration" = "on";
        "terminal.integrated.cursorBlinking" = true;
        "terminal.integrated.shellIntegration.enabled" = false;
        "terminal.integrated.enableImages" = false;
        "terminal.integrated.smoothScrolling" = false;
        "terminal.integrated.fastScrollSensitivity" = 5;
        "terminal.integrated.profiles.linux" = {
          fish = { path = "/run/current-system/sw/bin/fish"; };
        };

        "sqlfluff.dialect" = "bigquery";
        "workbench.iconTheme" = "a-file-icon-vscode";
        "workbench.sideBar.location" = "right";
        "vsicons.dontShowNewVersionMessage" = true;

        "files.associations" = {
          "cloudbuild.yaml" = "yaml";
          "*.bash" = "shellscript";
          "*.sh" = "shellscript";
        };

        "github.copilot.nextEditSuggestions.enabled" = true;

        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
        "editor.fontFamily" =
          "'JetBrainsMono Nerd Font', 'MesloLGS Nerd Font', 'Droid Sans Mono', 'monospace'";
        "workbench.colorTheme" = "One Dark Pro Night Flat";

        "extensions.autoUpdate" = false;
        "extensions.autoCheckUpdates" = false;

        "vscode-dataform-tools.currencyFoDryRunCost" = "EUR";
      };
    };
  };

  # One-shot install for marketplace-only stuff
  home.activation.vscodeFallbackExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu
    for ext in ${lib.concatStringsSep " " (map lib.escapeShellArg missingIds)}; do
      echo "Installing non-nixpkgs extension: $ext"
      ${codeBin} --install-extension "$ext" --force || true
    done
  '';
}
