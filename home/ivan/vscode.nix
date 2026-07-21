{
  config,
  pkgs,
  ...
}:

let
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "clippy"
      "rust-src"
      "rustfmt"
    ];
  };

  # Extensions in nixpkgs
  nixpkgsExtensions = with pkgs.vscode-extensions; [
    astro-build.astro-vscode
    jeff-hykin.better-nix-syntax
    bradlc.vscode-tailwindcss
    catppuccin.catppuccin-vsc-icons
    docker.docker
    eamodio.gitlens
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
    samuelcolvin.jinjahtml
    shd101wyy.markdown-preview-enhanced
    tamasfe.even-better-toml
    timonwong.shellcheck
    tomoki1207.pdf
    unifiedjs.vscode-mdx
    usernamehw.errorlens
    vue.volar
    wgsl-analyzer.wgsl-analyzer
    ms-python.python
    ms-toolsai.jupyter
    ms-python.vscode-pylance
    golang.go
    zhuangtongfa.material-theme
  ];

  marketplace = pkgs.nix-vscode-extensions.forVSCodeVersion config.programs.vscode.package.version;

  marketplaceRelease = marketplace.vscode-marketplace-release;
  marketplacePrerelease = marketplace.vscode-marketplace;

  # Marketplace-only extensions missing from nixpkgs
  marketplaceExtensions = [
    marketplaceRelease.ashishalex.dataform-lsp-vscode
    marketplaceRelease.googlecloudtools.datacloud
    marketplaceRelease.macabeus.vscode-fluent
    marketplacePrerelease.openai.chatgpt
    marketplaceRelease.risingstack.astro-alpinejs-syntax-highlight
    marketplaceRelease.sqlfluff.vscode-sqlfluff
  ];

in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    mutableExtensionsDir = false;

    argvSettings = {
      "enable-crash-reporter" = false;
      "password-store" = "basic";
    };

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      extensions = nixpkgsExtensions ++ marketplaceExtensions;

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

        "vscode-dataform-tools.formattingCli" = "sqlfluff";
        "vscode-dataform-tools.sqlfluffConfigPath" = "./.sqlfluff";
        "workbench.iconTheme" = "catppuccin-macchiato";
        "workbench.sideBar.location" = "right";
        "workbench.editor.closeOnFileDelete" = true;
        "vsicons.dontShowNewVersionMessage" = true;

        "files.associations" = {
          "cloudbuild.yaml" = "yaml";
          "*.css" = "tailwindcss";
          "*.bash" = "shellscript";
          "*.sh" = "shellscript";
        };

        "search.useIgnoreFiles" = true;
        "search.useGlobalIgnoreFiles" = true;
        "search.searchOnTypeDebouncePeriod" = 100;
        "search.followSymlinks" = false;
        "search.maxResults" = 5000;
        "search.showLineNumbers" = true;
        "search.smartCase" = true;
        "search.exclude" = {
          "**/.git/objects/**" = true;
          "**/.git/subtree-cache/**" = true;
          "**/node_modules/**" = true;
          "**/target/**" = true;
          "**/dist/**" = true;
          "**/.direnv/**" = true;
        };
        "files.watcherExclude" = {
          "**/.git/objects/**" = true;
          "**/.git/subtree-cache/**" = true;
          "**/node_modules/**" = true;
          "**/target/**" = true;
          "**/dist/**" = true;
          "**/.direnv/**" = true;
        };

        "github.copilot.nextEditSuggestions.enabled" = true;
        "google.cloud.project" = "he-dlh-prd";
        "google.cloud.region" = "europe-west1";
        "google.datacloud.bigqueryRegion" = "europe-west1";
        "jupyter.jupyterLaunchTimeout" = 300000;
        "jupyter.runStartupCommands" = [
          "import bigframes"
          "%load_ext bigframes"
          "bigframes.options.bigquery.project = \"he-dlh-prd\""
          "bigframes.options.bigquery.application_name = \"datacloud.visual studio code\""
        ];

        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
        "editor.cursorBlinking" = "phase";
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.quickSuggestions" = {
          "strings" = "on";
        };
        "editor.inlayHints.enabled" = "offUnlessPressed";
        "js/ts.updateImportsOnFileMove.enabled" = "always";
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
        "[sql]" = {
          "editor.defaultFormatter" = "sqlfluff.vscode-sqlfluff";
          "editor.formatOnSave" = true;
        };
        "[sqlx]" = {
          "editor.defaultFormatter" = "ashishalex.dataform-lsp-vscode";
          "editor.formatOnSave" = true;
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
        "nix.formatterPath" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
        "editor.fontFamily" =
          "'JetBrainsMono Nerd Font', 'MesloLGS Nerd Font', 'Droid Sans Mono', 'monospace'";
        "workbench.colorTheme" = "One Dark Pro Night Flat";

        "extensions.autoUpdate" = "off";

        "vscode-dataform-tools.gcpProjectId" = "he-dlh-prd";
        "vscode-dataform-tools.gcpLocation" = "europe-west1";
        "vscode-dataform-tools.currencyFoDryRunCost" = "EUR";
      };
    };
  };
}
