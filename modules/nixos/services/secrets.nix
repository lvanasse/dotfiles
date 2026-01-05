{ config, inputs, ... }:
let
  username = config.flake.lib.username;
  # Paths inside the private secrets repo input
  jiraCfgAge = "${inputs.secrets}/jira/config.yml.age";
  jiraTokenAge = "${inputs.secrets}/jira/api_token.age";
  codexOpenAI = "${inputs.secrets}/codex/openai_api_key.age";
  codexTavily = "${inputs.secrets}/codex/tavily_api_key.age";
  codexBing = "${inputs.secrets}/codex/bing_search_v7_key.age";
in
{
  flake.modules.nixos.servicesSecrets =
    { ... }:
    {
      # Secrets deployment via agenix (system-level)

      # Deploy Jira CLI config from age-encrypted file if present.
      # This keeps API tokens and config out of the dotfiles repo.
      age.secrets =
        let
          hasCfg = builtins.pathExists jiraCfgAge;
          hasTok = builtins.pathExists jiraTokenAge;
        in
        (
          if hasCfg then
            {
              "jira-config" = {
                file = jiraCfgAge;
                # Match jira-cli default path observed during `jira init`
                path = "/home/${username}/.config/.jira/.config.yml";
                mode = "0600";
                owner = username;
                group = "users";
              };
            }
          else
            { }
        )
        // (
          if hasTok then
            {
              "jira-api-token" = {
                file = jiraTokenAge;
                # Keep token alongside jira config directory
                path = "/home/${username}/.config/.jira/JIRA_API_TOKEN";
                mode = "0600";
                owner = username;
                group = "users";
              };
            }
          else
            { }
        )
        // (
          let
            hasOA = builtins.pathExists codexOpenAI;
          in
          if hasOA then
            {
              "codex-openai-key" = {
                file = codexOpenAI;
                path = "/home/${username}/.config/codex/OPENAI_API_KEY";
                mode = "0600";
                owner = username;
                group = "users";
              };
            }
          else
            { }
        )
        // (
          let
            hasTv = builtins.pathExists codexTavily;
          in
          if hasTv then
            {
              "codex-tavily-key" = {
                file = codexTavily;
                path = "/home/${username}/.config/codex/TAVILY_API_KEY";
                mode = "0600";
                owner = username;
                group = "users";
              };
            }
          else
            { }
        )
        // (
          let
            hasB = builtins.pathExists codexBing;
          in
          if hasB then
            {
              "codex-bing-key" = {
                file = codexBing;
                path = "/home/${username}/.config/codex/BING_SEARCH_V7_SUBSCRIPTION_KEY";
                mode = "0600";
                owner = username;
                group = "users";
              };
            }
          else
            { }
        );
    };
}
