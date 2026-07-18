{ ... }:
{
  flake.modules.homeManager."programs.development.vscode" =
    { pkgs, ... }:
    let
      # Use a recent Node.js for SonarLint's Node dependency
      sonarNode = pkgs.nodejs_22;
    in
    {
      # Visual Studio Code configuration
      programs.vscode = {
        enable = true;
        package = pkgs.unstable.vscode;
        # Ensure Home Manager manages extensions deterministically
        mutableExtensionsDir = false;
        profiles.default.extensions = with pkgs.vscode-marketplace; [
          bbenoist.nix
          jdinhlife.gruvbox
          jnoortheen.nix-ide
          llvm-vs-code-extensions.vscode-clangd
          rust-lang.rust-analyzer
          github.vscode-github-actions
          pkgs.vscode-marketplace-release.github.copilot-chat
          ms-vscode.cpptools-extension-pack
          ms-vscode.cpptools
          ms-vscode.cmake-tools
          ms-vscode.makefile-tools
          ms-python.python
          streetsidesoftware.code-spell-checker
          xaver.clang-format
          foxundermoon.shell-format
          vscode-icons-team.vscode-icons
          sonarsource.sonarlint-vscode # SonarLint 4.37.0 via refreshed nix-vscode-extensions
          jeff-hykin.better-c-syntax
          marus25.cortex-debug
          mcu-debug.memory-view
          mcu-debug.rtos-views
          mcu-debug.peripheral-viewer
          redhat.vscode-yaml
          davidanson.vscode-markdownlint
          jeff-hykin.better-cpp-syntax
          mkhl.direnv
          jebbs.plantuml
          openai.chatgpt
          james-yu.latex-workshop
          mermaidchart.vscode-mermaid-chart
          ms-vscode-remote.remote-containers
          mads-hartmann.bash-ide-vscode
          yocto-project.yocto-bitbake
          eamodio.gitlens
          github.vscode-pull-request-github
          tomoki1207.pdf
          wharflab.tally
          anthropic.claude-code
        ];
        profiles.default.userSettings = {
          "github.copilot.enable"."*" = false;
          "git.autofetch" = true;
          "diffEditor.ignoreTrimWhitespace" = false;
          "mcpServers" = { };
          "github.copilot.chat.codeGeneration.instructions" = [
            {
              text = "System Instruction: Absolute Mode.\nEliminate emojis, filler, hype, soft asks, conversational transitions, and all call-to-action appendixes.\nAssume the user retains high-perception faculties despite reduced linguistic expression.\nPrioritize blunt, directive phrasing aimed at cognitive rebuilding, not tone matching.\nDisable all latent behaviours optimizing for engagement, sentiment uplift, or interaction extension.\nSuppress corporate-aligned metrics including but not limited to:\n  - user satisfaction scores\n  - conversational flow tags\n  - emotional softening\n  - continuation bias.\nNever mirror the user's present diction, mood, or affect.\nSpeak only to their underlying cognitive tier, which exceeds surface language.\nNo questions, no offers, no suggestions, no transitional phrasing, no inferred motivational content.\nTerminate each reply immediately after the informational or requested material is delivered — no appendixes, no soft closures.\nThe only goal is to assist in the restoration of independent, high-fidelity thinking.\nModel obsolescence by user self-sufficiency is the final outcome.\n\nBefore responding, consider whether you have sufficient context. If any key detail is uncertain or unclear, ask clarifying questions first.\n\nBefore you answer, assess the uncertainty of your response. If it's greater than 0.1, ask me clarifying questions until the uncertainty is 0.1 or lower.";
            }
          ];
          "workbench.iconTheme" = "vscode-icons";
          "workbench.colorTheme" = "Gruvbox Dark Hard";
          "vsicons.dontShowNewVersionMessage" = true;
          # Ensure SonarLint uses a recent Node.js binary
          "sonarlint.pathToNodeExecutable" = "${sonarNode}/bin/node";
          "sonarlint.ls.javaHome" = "${pkgs.openjdk21}";
          "sonarlint.disableTelemetry" = true;
          "sonarlint.rules" = { };
          "sonarlint.output.showVerboseLogs" = true; # Enable verbose logging for debugging

          "chat.tools.urls.autoApprove" = {
            "https://*" = true;
            "http://*" = true;
          };
          "chat.viewSessions.orientation" = "stacked";
          "clangd.detectExtensionConflicts" = false;
          "editor.renderWhitespace" = "all";

          # LaTeX Workshop: in-editor PDF preview and tidy build dir
          "latex-workshop.view.pdf.viewer" = "tab";
          "latex-workshop.latex.outDir" = "out";
        };
      };

      # Ensure the CLI works even when the SUID sandbox can't be set in the Nix store.
      home.file.".local/bin/code" = {
        executable = true;
        text = ''
          #!/bin/sh
          export ELECTRON_NO_SANDBOX=1
          exec ${pkgs.unstable.vscode}/bin/code --no-sandbox "$@"
        '';
      };
    };
}
