{ den, inputs, ... }:

{
  den.aspects.ai.nixos = { pkgs, ... }: {
    environment.systemPackages =
      let
        isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
      in
      with pkgs;
      [
        # AI coding workflow tools
        beads
        fff-mcp
        repomix
        rtk

        # Desktop automation
        dotool

        # Archives, compression, and file movement
        p7zip
        pv

        # Structured data and shell helpers
        jq
        jo
        gron
        miller
        qsv
        csvkit
        htmlq
        jc
        choose
        ripgrep-all
        shfmt
        hyperfine
        just
        entr
        watchexec
        moreutils
        socat
        netcat-openbsd
        sqlite
        jless
        parallel
        inotify-tools
        dos2unix

        # Network, transport, and low-level debugging
        inetutils
        whois
        nmap
        traceroute
        iperf3
        ltrace

        # Raw byte inspection
        hexyl
        xxd

        # Content conversion, rendering, and syntax-aware inspection
        graphviz
        imagemagick
        pandoc
        poppler-utils
        tree-sitter

        # Local services and large-asset helpers
        postgresql
        redis
      ]

      ++ lib.optionals isX86 [
        # Local AI
        lmstudio
      ];
  };

  den.aspects.ai.homeManager =
    { config, pkgs, ... }:
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
      skills =
        pkgs.lib.genAttrs agentSkillNames (name: "${agentSkills}/share/skills/agent-skills/${name}")
        // {
          gh-stack = "${pkgs.gh-stack}/share/skills/gh-stack/gh-stack";
          humanizer = "${humanizer}/share/skills/humanizer/humanizer";
        };
    in
    {
      programs.codex.skills = skills;
      programs.claude-code.skills = skills;

      programs.mcp = {
        enable = true;
        servers = {
          fff = {
            command = pkgs.lib.getExe pkgs.fff-mcp;
            args = [ "--no-update-check" ];
          };
          openaiDeveloperDocs.url = "https://developers.openai.com/mcp";
        };
      };

      programs.t3code = {
        enable = true;

        clientSettings = {
          notificationMode = "notifications";
          diffIgnoreWhitespace = false;
          fontFamilyCode = config.stylix.fonts.monospace.name;
          fontFamilySans = config.stylix.fonts.sansSerif.name;
        };
      };
    };
}
