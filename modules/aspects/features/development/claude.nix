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
          CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        };
      };
    };
  };
}
