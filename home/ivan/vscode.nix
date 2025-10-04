{ config, lib, pkgs, ... }:

let
  codeBin = "${config.programs.vscode.package}/bin/code";

  exts = [
    "adrianwilczynski.alpine-js-intellisense"
    "ashishalex.dataform-lsp-vscode"
    "astro-build.astro-vscode"
    "bbenoist.nix"
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
    "ms-python.debugpy"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-python.vscode-python-envs"
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-wsl"
    "openai.chatgpt"
    "pkief.material-icon-theme"
    "polymeilex.wgsl"
    "randomfractalsinc.vscode-data-preview"
    "risingstack.astro-alpinejs-syntax-highlight"
    "ritwickdey.liveserver"
    "tamasfe.even-better-toml"
    "timonwong.shellcheck"
    "unifiedjs.vscode-mdx"
    "usernamehw.errorlens"
    "vscode-icons-team.vscode-icons"
    "vue.volar"
    "xabikos.javascriptsnippets"
    "zhuangtongfa.material-theme"
    "zignd.html-css-class-completion"
  ];
in
{
  programs.vscode = {
    enable  = true;
    package = pkgs.vscode;

    # New API: put settings under a profile
    profiles.default.userSettings = {
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
      "workbench.iconTheme" = "material-icon-theme";
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

      "extensions.autoUpdate" = true;
      "extensions.autoCheckUpdates" = true;

      "vscode-dataform-tools.currencyFoDryRunCost" = "EUR";
    };
  };

  # Always install/update your list to latest on each HM switch
  home.activation.vscodeLatestExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu
    for ext in ${lib.concatStringsSep " " (map lib.escapeShellArg exts)}; do
      ${codeBin} --install-extension "$ext" --force || true
    done
  '';
}
