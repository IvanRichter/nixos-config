{ den, ... }:

let
  systemSettings = {
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
      environment.systemPackages = [
        pkgs.chatgpt
        pkgs.codex-security
      ];

      environment.etc."codex/config.toml".source =
        (pkgs.formats.toml { }).generate "codex-config.toml"
          systemSettings;
    };

    homeManager.programs.codex = {
      enable = true;
      enableMcpIntegration = true;

      # Merge shared MCP servers while preserving settings managed by Codex
      mutableSettings = true;
    };
  };
}
