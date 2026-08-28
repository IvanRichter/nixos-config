{ den, ... }:

let
  systemSettings = {
    model_context_window = 1000000;
    model_auto_compact_token_limit = 900000;
    model_reasoning_effort = "max";
    personality = "pragmatic";
    service_tier = "default";

    features = {
      multi_agent = true;
      memories = true;
    };

    memories = {
      generate_memories = true;
      use_memories = true;
    };

    plugins."github@openai-curated".enabled = true;
  };
in
{
  den.aspects.codex = {
    nixos = { pkgs, ... }: {
      environment.etc."codex/config.toml".source =
        (pkgs.formats.toml { }).generate "codex-config.toml"
          systemSettings;
    };

    homeManager.programs.codex.enable = true;
  };
}
