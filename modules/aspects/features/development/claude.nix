{ den, ... }:

{
  den.aspects.claude.homeManager = {
    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;

      settings = {
        attribution = false;
        autoMemoryEnabled = true;
        outputStyle = "Concise";

        env = {
          CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        };
      };
    };
  };
}
