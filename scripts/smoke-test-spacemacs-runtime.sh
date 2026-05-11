#!/usr/bin/env bash
set -euo pipefail

EMACS_BIN="${EMACS_BIN:-emacs}"
SPACEMACS_FILE="${SPACEMACS_FILE:-$HOME/.spacemacs}"
EMACSD_DIR="${EMACSD_DIR:-$HOME/.emacs.d}"

if [ ! -f "$SPACEMACS_FILE" ]; then
  echo "spacemacs file not found: $SPACEMACS_FILE" >&2
  exit 1
fi

if [ ! -f "$EMACSD_DIR/init.el" ]; then
  echo "Spacemacs init.el not found under: $EMACSD_DIR" >&2
  exit 1
fi

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '  - %-28s %s\n' "$cmd" "$(command -v "$cmd")"
  else
    echo "missing executable in PATH: $cmd" >&2
    echo "run home-manager switch --flake .#ludovic@pc and restart Emacs before retrying" >&2
    exit 1
  fi
}

run_elisp() {
  "$EMACS_BIN" --batch --quick -l "$EMACSD_DIR/init.el" --eval "$1"
}

echo "[1/5] Checking private config entrypoints"
for private_file in \
  "$HOME/.config/slack/private.el" \
  "$HOME/.config/spotify/private.el" \
  "$HOME/.config/copilot-chat/github-token"
do
  if [ -r "$private_file" ]; then
    echo "  - present: $private_file"
  else
    echo "  - optional or missing: $private_file"
  fi
done

echo "[2/5] Checking required executables"
for cmd in \
  aspell \
  curl \
  node \
  npm \
  nixd \
  basedpyright-langserver \
  cmake-language-server \
  bash-language-server \
  yaml-language-server \
  docker-langserver \
  marksman
do
  check_cmd "$cmd"
done

echo "[3/5] Checking aspell dictionaries"
dicts_output="$(aspell dump dicts)"
printf '%s\n' "$dicts_output"
printf '%s\n' "$dicts_output" | grep -qx 'en'
printf '%s\n' "$dicts_output" | grep -qx 'fr'
echo "  - aspell dictionaries include en and fr"

echo "[4/5] Checking runtime package and command availability in Emacs"
run_elisp '(progn
  (when (fboundp (quote dotspacemacs/user-init))
    (dotspacemacs/user-init))
  (when (fboundp (quote dotspacemacs/user-config))
    (dotspacemacs/user-config))
  (dolist (feature (quote (copilot copilot-chat slack centaur-tabs all-the-icons nerd-icons markdown-mode dockerfile-mode nix-mode)))
    (unless (require feature nil t)
      (princ (format "missing feature: %S\n" feature))
      (kill-emacs 1))
    (princ (format "loaded feature: %S\n" feature)))
  (dolist (fn (quote (copilot-login
                      copilot-mode
                      copilot-chat-transient
                      slack-start
                      spotify-playpause)))
    (unless (fboundp fn)
      (princ (format "missing command: %S\n" fn))
      (kill-emacs 1))
    (princ (format "available command: %S\n" fn)))
  (princ (format "tabs-icons=%S\n" tabs-icons))
  (when (boundp (quote centaur-tabs-icon-type))
    (princ (format "centaur-tabs-icon-type=%S\n" centaur-tabs-icon-type)))
  (princ (format "copilot chat token file exists=%S\n"
                 (file-readable-p (expand-file-name "~/.config/copilot-chat/github-token"))))
  (princ (format "slack private config exists=%S\n"
                 (file-readable-p (expand-file-name "~/.config/slack/private.el"))))
  (princ (format "spotify private config exists=%S\n"
                 (file-readable-p (expand-file-name "~/.config/spotify/private.el"))))
  (when (file-readable-p (expand-file-name "~/.config/spotify/private.el"))
    (unless (require (quote counsel-spotify) nil t)
      (princ "missing feature: counsel-spotify\n")
      (kill-emacs 1))
    (princ (format "loaded feature: %S\n" (quote counsel-spotify)))
    (unless (and (boundp (quote counsel-spotify-client-id))
                 (boundp (quote counsel-spotify-client-secret))
                 (stringp counsel-spotify-client-id)
                 (stringp counsel-spotify-client-secret)
                 (> (length counsel-spotify-client-id) 0)
                 (> (length counsel-spotify-client-secret) 0))
      (princ "spotify private config loaded, but credentials are missing\n")
      (kill-emacs 1))))'

echo "[5/5] Checking this repo as the active project root"
repo_root="$(pwd)"
if [ ! -f "$repo_root/flake.nix" ]; then
  echo "expected to run from the dotfiles repo root; missing flake.nix in $repo_root" >&2
  exit 1
fi
echo "  - repo root: $repo_root"

echo "Spacemacs runtime smoke test passed."
