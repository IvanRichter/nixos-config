{ den, inputs, ... }:

{
  den.aspects.development = {
    nixpkgs-overlays = _: {
      hk = import "${inputs.self}/overlays/development/hk.nix";
      bigframes = import "${inputs.self}/overlays/python/bigframes.nix";
      rust = inputs.rust-overlay.overlays.default;
    };

    nixos = { pkgs, ... }: {
      environment.systemPackages =

        let
          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            extensions = [
              "clippy"
              "rust-src"
              "rustfmt"
            ];
            targets = [ "wasm32-unknown-unknown" ];
          };
        in

        with pkgs;
        [
          # Programming languages & runtimes
          pnpm
          bun
          pkl
          rustToolchain
          cargo-nextest
          cargo-outdated
          cargo-edit
          (python3.withPackages (pythonPackages: [
            pythonPackages.ipykernel
            pythonPackages.bigframes
          ]))

          # Build tools & compilers
          gcc
          gnumake
          kache
          pkg-config
          openssl

          # Dioxus & WebAssembly
          dioxus-cli
          trunk

          # Cloud & infra
          google-cloud-sdk
          google-cloud-sql-proxy
          terraform
          pulumi-bin
          ansible

          # Git & CI
          git-filter-repo
          ghgrab
          hk
          act
          actionlint
          shellcheck
          pinact

          # Databases & SQL
          dbmate
          sqlfluff
          dataform

          # Graphics & GPU
          mesa-demos

          # Compression
          brotli

          # Encoding & cryptography
          ciphey

          # Utilities
          bruno
        ];
    };

    homeManager = { pkgs, ... }: {
      # Cache C/C++ compiler calls, keep real compilers on PATH
      home.sessionPath = [ "${pkgs.kache.shims}/bin" ];

      programs.cargo = {
        enable = true;
        package = null; # Cargo comes from rustToolchain
        settings = {
          build.rustc-wrapper = "${pkgs.kache}/bin/kache";
          env = {
            HOST_CC = "${pkgs.kache}/bin/kache cc";
            HOST_CXX = "${pkgs.kache}/bin/kache c++";
            CC_KNOWN_WRAPPER_CUSTOM = "kache";
          };
        };
      };

      systemd.user.services.kache = {
        Unit.Description = "Kache compiler cache daemon";
        Service = {
          ExecStart = "${pkgs.kache}/bin/kache daemon run";
          Environment = [ "KACHE_LOG=kache=info" ];
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };

      programs.git = {
        enable = true;
        package = null;

        signing = {
          format = "ssh";
          key = "~/.ssh/keys/github_ed25519.pub";
          signByDefault = true;
          allowedSigners = ''
            ivan@anriku.com namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFOBwlAkmI2akQ+ZMiT/abYEcxSAZJ3Ordf6+6ktlj09
            ivan@anriku.com namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBb0kaPUxfcppuwg8htkUIdIENzoxD7AMdmNqHmDGuPv
          '';
        };

        settings = {
          safe.directory = "/home/ivan/nixos-config";
          user = {
            email = "ivan@anriku.com";
            name = "Ivan Richter";
          };
        };
      };

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
      };

      programs.gh = {
        enable = true;
        extensions = [ pkgs.gh-stack ];

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
