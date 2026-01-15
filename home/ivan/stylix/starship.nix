{ ... }:
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      # Default $all list with $os moved before $directory to show the icon on the first line.
      format = builtins.concatStringsSep "" [
        "$username"
        "$hostname"
        "$localip"
        "$shlvl"
        "$singularity"
        "$kubernetes"
        "$nats"
        "$os"
        "$directory"
        "$vcsh"
        "$fossil_branch"
        "$fossil_metrics"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_metrics"
        "$git_status"
        "$hg_branch"
        "$hg_state"
        "$pijul_channel"
        "$docker_context"
        "$package"
        "$bun"
        "$c"
        "$cmake"
        "$cobol"
        "$cpp"
        "$daml"
        "$dart"
        "$deno"
        "$dotnet"
        "$elixir"
        "$elm"
        "$erlang"
        "$fennel"
        "$fortran"
        "$gleam"
        "$golang"
        "$gradle"
        "$haskell"
        "$haxe"
        "$helm"
        "$java"
        "$julia"
        "$kotlin"
        "$lua"
        "$mojo"
        "$nim"
        "$nodejs"
        "$ocaml"
        "$odin"
        "$opa"
        "$perl"
        "$php"
        "$pulumi"
        "$purescript"
        "$python"
        "$quarto"
        "$raku"
        "$rlang"
        "$red"
        "$ruby"
        "$rust"
        "$scala"
        "$solidity"
        "$swift"
        "$terraform"
        "$typst"
        "$vlang"
        "$vagrant"
        "$xmake"
        "$zig"
        "$buf"
        "$guix_shell"
        "$nix_shell"
        "$conda"
        "$pixi"
        "$meson"
        "$spack"
        "$memory_usage"
        "$aws"
        "$gcloud"
        "$openstack"
        "$azure"
        "$direnv"
        "$env_var"
        "$mise"
        "$crystal"
        "$custom"
        "$sudo"
        "$cmd_duration"
        "$line_break"
        "$jobs"
        "$battery"
        "$time"
        "$status"
        "$container"
        "$netns"
        "$shell"
        "$character"
      ];
      os = {
        disabled = false;
        format = "[$symbol]($style) ";
      };
      directory = {
        truncation_length = 3;
        truncation_symbol = "../";
        truncate_to_repo = true;
      };
      git_branch = {
        symbol = "git:";
        format = " [$symbol$branch]($style)";
      };
      git_status = {
        format = " [$all_status$ahead_behind]($style) ";
      };
      nix_shell = {
        symbol = "nix:";
        format = " [$symbol$state( $name)]($style)";
      };
      cmd_duration = {
        min_time = 1000;
        format = " [$duration]($style)";
      };
      character = {
        format = " $symbol ";
        success_symbol = "[>](green)";
        error_symbol = "[x](red)";
      };
    };
  };
}
