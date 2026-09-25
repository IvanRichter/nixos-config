{ den, inputs, ... }:

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
      environment.etc."codex/config.toml".source =
        (pkgs.formats.toml { }).generate "codex-config.toml"
          systemSettings;
    };

    homeManager =
      { pkgs, ... }:
      let
        humanizer =
          pkgs.runCommand "humanizer-skills"
            {
              pname = "humanizer";
              nativeBuildInputs = [ pkgs.installAgentSkills ];
            }
            ''
              cp -R "${inputs.humanizer}" humanizer
              installSkill humanizer
            '';
      in
      {
        programs.codex = {
          enable = true;
          skills.humanizer = "${humanizer}/share/skills/humanizer/humanizer";
        };
      };
  };
}
