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
          ms-vscode.cpptools-extension-pack
          ms-vscode.cpptools
          ms-vscode.cmake-tools
          ms-vscode.makefile-tools
          ms-python.python
          ms-python.vscode-pylance # Python language server: IntelliSense, hover docs, go-to-def
          charliermarsh.ruff # Python linting, formatting, and import organization
          streetsidesoftware.code-spell-checker
          xaver.clang-format
          mkhl.shfmt
          vscode-icons-team.vscode-icons
          sonarsource.sonarlint-vscode # SonarLint 4.37.0 via refreshed nix-vscode-extensions
          jeff-hykin.better-c-syntax
          marus25.cortex-debug
          mcu-debug.memory-view
          mcu-debug.rtos-views
          mcu-debug.peripheral-viewer
          redhat.vscode-yaml
          bufbuild.vscode-buf # Protobuf: parsing, linting, and formatting via buf language server
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
          "git.autofetch" = true;
          "diffEditor.ignoreTrimWhitespace" = false;
          "dev.containers.defaultExtensions" = [
            "GitHub.vscode-pull-request-github"
          ];
          "mcpServers" = { };
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
          "C_Cpp.intelliSenseEngine" = "disabled";
          # Generic clangd tuning: background-index enables project-wide
          # symbol search/go-to-def without a compile_commands.json, and
          # clang-tidy adds richer diagnostics. None of this is project-specific.
          "clangd.arguments" = [
            "--background-index"
            "--all-scopes-completion"
            "--completion-style=detailed"
            "--header-insertion=never"
            "--pch-storage=memory"
            "--clang-tidy"
          ];

          # Use Pylance as the Python language server (IntelliSense, hover, type info).
          # Requires ms-python.vscode-pylance in the extensions list above.
          "python.languageServer" = "Default";
          # Fallback interpreter when a workspace hasn't selected one. A per-project
          # "Python: Select Interpreter" choice (stored in the project's .vscode
          # settings) always overrides this.
          "python.defaultInterpreterPath" = "${pkgs.python3}/bin/python3";
          # Ruff handles style diagnostics and formatting while Pylance provides
          # completion, navigation, and type checking.
          "ruff.path" = [ "${pkgs.ruff}/bin/ruff" ];
          "[python]" = {
            "editor.defaultFormatter" = "charliermarsh.ruff";
            "editor.formatOnSave" = true;
            "editor.codeActionsOnSave" = {
              "source.fixAll.ruff" = "explicit";
              "source.organizeImports.ruff" = "explicit";
            };
          };
          "editor.renderWhitespace" = "all";
          "[shellscript]" = {
            "editor.defaultFormatter" = "mkhl.shfmt";
          };
          # Protobuf: buf provides parsing, linting, and formatting through its
          # language server. Point the extension at the Nix-managed binary and
          # disable its self-update check since Nix owns the version.
          "buf.path" = "${pkgs.buf}/bin/buf";
          "buf.checkForUpdates" = false;
          "[proto]" = {
            "editor.defaultFormatter" = "bufbuild.vscode-buf";
            "editor.formatOnSave" = true;
          };
          "github.copilot.enable" = {
            "*" = false;
          };
          "github.copilot.editor.enableAutoCompletions" = false;
          "github.copilot.inlineSuggest.enable" = false;
          "github.copilot.nextEditSuggestions.enabled" = false;
          "github.copilot.renameSuggestions.triggerAutomatically" = false;

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
