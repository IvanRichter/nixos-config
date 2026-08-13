{ den, ... }:

{
  den.aspects.development = {
    nixos = { pkgs, ... }: {
      environment.systemPackages =

        let
          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            extensions = [
              "clippy"
              "rust-src"
              "rustfmt"
            ];
          };
        in

        with pkgs;
        [
          # Programming languages & runtimes
          pnpm
          bun
          rustToolchain
          cargo-nextest
          cargo-outdated
          cargo-edit
          (python314.withPackages (pythonPackages: [
            pythonPackages.ipykernel
            pythonPackages.jupyter
            pythonPackages.bigquery-magics
          ]))

          # Build tools & compilers
          gcc
          gnumake
          pkg-config
          openssl

          # Cloud & infra
          google-cloud-sdk
          google-cloud-sql-proxy
          terraform
          pulumi-bin
          gws
          ansible

          # Git & version control
          git-filter-repo
          ghgrab
          pinact

          # Databases & SQL
          dbmate
          sqlfluff
          dataform

          # Graphics & GPU
          mesa-demos

          # Compression
          brotli

          # Utilities
          bruno
        ];
    };

    homeManager = {
      programs.git = {
        enable = true;
        package = null;

        settings = {
          safe.directory = "/home/ivan/nixos-config";
          user = {
            email = "ivan.richter@anriku.com";
            name = "IvanRichter";
          };
        };
      };

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
      };

      programs.gh = {
        enable = true;

        settings = {
          git_protocol = "https";
          prompt = "enabled";
          prefer_editor_prompt = "disabled";
          aliases.co = "pr checkout";
          color_labels = "disabled";
          accessible_colors = "disabled";
          accessible_prompter = "disabled";
          spinner = "enabled";
        };
      };

      programs.docker-cli = {
        enable = true;
        configDir = ".docker";

        settings.credHelpers = {
          "europe-docker.pkg.dev" = "gcloud";
          "europe-west1-docker.pkg.dev" = "gcloud";
        };
      };

      programs.ssh = {
        enable = true;
        package = null;
        enableDefaultConfig = false;

        settings = {
          github-IvanRichter = {
            HostName = "github.com";
            User = "git";
            IdentityFile = "~/.ssh/keys/github_ed25519";
            IdentitiesOnly = true;
            AddKeysToAgent = "yes";
          };

          bitbucket-ivan_richter = {
            HostName = "bitbucket.org";
            User = "git";
            IdentityFile = "~/.ssh/keys/bitbucket_ed25519";
            IdentitiesOnly = true;
            AddKeysToAgent = "yes";
          };
        };
      };
    };
  };
}
