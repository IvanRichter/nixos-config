{
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
}
