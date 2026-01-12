{
  config,
  lib,
  pkgs,
  ...
}:

let
  codeBin = "${config.programs.vscode.package}/bin/code";
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "clippy"
      "rust-src"
      "rustfmt"
    ];
  };

  # Wishlist
  want = [
    # Provided by nixpkgs
    "astro-build.astro-vscode"
    "bradlc.vscode-tailwindcss"
    "docker.docker"
    "esbenp.prettier-vscode"
    "github.copilot"
    "github.copilot-chat"
    "golang.go"
    "hashicorp.terraform"
    "jeff-hykin.better-nix-syntax"
    "jnoortheen.nix-ide"
    "mads-hartmann.bash-ide-vscode"
    "mechatroner.rainbow-csv"
    "ms-azuretools.vscode-containers"
    "ms-azuretools.vscode-docker"
    "ms-python.python"
    "ms-toolsai.jupyter"
    "ms-python.vscode-pylance"
    "ms-vscode-remote.remote-containers"
    "ritwickdey.liveserver"
    "rust-lang.rust-analyzer"
    "tamasfe.even-better-toml"
    "timonwong.shellcheck"
    "unifiedjs.vscode-mdx"
    "usernamehw.errorlens"
    "vue.volar"
    "zhuangtongfa.material-theme"

    # Marketplace-only
    "adrianwilczynski.alpine-js-intellisense"
    "ashishalex.dataform-lsp-vscode"
    "AtomMaterial.a-file-icon-vscode"
    "dustypomerleau.rust-syntax"
    "googlecloudtools.cloudcode"
    "ggsimm.wgsl-literal"
    "macabeus.vscode-fluent"
    "ms-python.vscode-python-envs"
    "openai.chatgpt"
    "polymeilex.wgsl"
    "randomfractalsinc.vscode-data-preview"
    "risingstack.astro-alpinejs-syntax-highlight"
  ];

  # Extensions in nixpkgs
  declaredIds = [
    "astro-build.astro-vscode"
    "jeff-hykin.better-nix-syntax"
    "bradlc.vscode-tailwindcss"
    "docker.docker"
    "esbenp.prettier-vscode"
    "github.copilot"
    "github.copilot-chat"
    "hashicorp.terraform"
    "jnoortheen.nix-ide"
    "mads-hartmann.bash-ide-vscode"
    "ms-azuretools.vscode-containers"
    "ms-azuretools.vscode-docker"
    "mechatroner.rainbow-csv"
    "ms-vscode-remote.remote-containers"
    "ritwickdey.liveserver"
    "rust-lang.rust-analyzer"
    "tamasfe.even-better-toml"
    "timonwong.shellcheck"
    "unifiedjs.vscode-mdx"
    "usernamehw.errorlens"
    "vue.volar"
    "ms-python.python"
    "ms-toolsai.jupyter"
    "ms-python.vscode-pylance"
    "golang.go"
    "zhuangtongfa.material-theme"
  ];

  # The actual derivations for those
  declaredPkgs = with pkgs.vscode-extensions; [
    astro-build.astro-vscode
    jeff-hykin.better-nix-syntax
    bradlc.vscode-tailwindcss
    docker.docker
    esbenp.prettier-vscode
    github.copilot
    github.copilot-chat
    hashicorp.terraform
    jnoortheen.nix-ide
    mads-hartmann.bash-ide-vscode
    ms-azuretools.vscode-containers
    ms-azuretools.vscode-docker
    mechatroner.rainbow-csv
    ms-vscode-remote.remote-containers
    ritwickdey.liveserver
    rust-lang.rust-analyzer
    tamasfe.even-better-toml
    timonwong.shellcheck
    unifiedjs.vscode-mdx
    usernamehw.errorlens
    vue.volar
    ms-python.python
    ms-toolsai.jupyter
    ms-python.vscode-pylance
    golang.go
    zhuangtongfa.material-theme
  ];

  # Everything else gets installed once via the Code CLI
  missingIds = lib.subtractLists declaredIds want;

in
{
  programs.vscode = {
    enable = true;
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
          fish = {
            path = "/run/current-system/sw/bin/fish";
          };
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
        "cloudcode.project" = "happy-end-data-warehouse";
        "cloudcode.beta.bigqueryRegion" = "eu";

        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
        "[rust]" = {
          "editor.defaultFormatter" = "rust-lang.rust-analyzer";
          "editor.formatOnSave" = true;
        };
        "rust-analyzer.checkOnSave" = false;
        "rust-analyzer.cargo.buildScripts.enable" = false;
        "rust-analyzer.cargo.targetDir" = "${config.xdg.cacheHome}/rust-analyzer/target";
        "rust-analyzer.procMacro.enable" = false;
        "rust-analyzer.rustfmt.overrideCommand" = [
          "${rustToolchain}/bin/rustfmt"
          "--edition"
          "2024"
        ];
        "nix.formatterPath" = "${pkgs.nixfmt}/bin/nixfmt";
        "editor.fontFamily" =
          "'JetBrainsMono Nerd Font', 'MesloLGS Nerd Font', 'Droid Sans Mono', 'monospace'";
        "workbench.colorTheme" = "One Dark Pro Night Flat";

        "extensions.autoUpdate" = true;
        "extensions.autoCheckUpdates" = true;

        "vscode-dataform-tools.currencyFoDryRunCost" = "EUR";
      };
    };
  };

  # Install marketplace-only extensions if missing
  home.activation.vscodeFallbackExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu

    INSTALLED="$(${codeBin} --list-extensions || true)"

    for ext in ${lib.concatStringsSep " " (map lib.escapeShellArg missingIds)}; do
      if ! echo "$INSTALLED" | grep -qx "$ext"; then
        echo "Installing VS Code marketplace extension: $ext"
        ${codeBin} --install-extension "$ext"
      else
        echo "VS Code extension already installed: $ext"
      fi
    done
  '';
}
