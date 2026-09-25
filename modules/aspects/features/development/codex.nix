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
        agentSkillEntries = builtins.readDir "${inputs.agent-skills}/skills";
        agentSkillNames = builtins.attrNames (
          pkgs.lib.filterAttrs (
            name: type:
            type == "directory" && builtins.pathExists "${inputs.agent-skills}/skills/${name}/SKILL.md"
          ) agentSkillEntries
        );
        agentSkills =
          pkgs.runCommand "agent-skills"
            {
              pname = "agent-skills";
              nativeBuildInputs = [
                pkgs.installAgentSkills
                pkgs.yq-go
              ];
            }
            ''
              cp -R "${inputs.agent-skills}/skills" skills
              chmod -R u+w skills

              for skillName in ${pkgs.lib.escapeShellArgs agentSkillNames}; do
                skill="skills/$skillName"
                metadata="$skill/agents/openai.yaml"
                mkdir -p "$skill/agents"

                if [[ -f "$metadata" ]]; then
                  yq --inplace '.policy.allow_implicit_invocation = false' "$metadata"
                else
                  printf '%s\n' \
                    'policy:' \
                    '  allow_implicit_invocation: false' \
                    > "$metadata"
                fi

                installSkill "$skill"
              done

              mkdir -p "$out/share/skills"
              cp -R "${inputs.agent-skills}/references" "$out/share/skills/references"
            '';
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
          skills =
            pkgs.lib.genAttrs agentSkillNames (name: "${agentSkills}/share/skills/agent-skills/${name}")
            // {
              humanizer = "${humanizer}/share/skills/humanizer/humanizer";
            };
        };
      };
  };
}
