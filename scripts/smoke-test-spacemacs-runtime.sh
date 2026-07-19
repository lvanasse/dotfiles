#!/usr/bin/env bash
set -euo pipefail

SPACEMACS_FILE="${SPACEMACS_FILE:-$HOME/.config/spacemacs/init.el}"
EMACSD_DIR="${EMACSD_DIR:-$HOME/.config/spacemacs/.emacs.d}"
if [ -n "${EMACS_BIN:-}" ]; then
  EMACS_BIN="$EMACS_BIN"
else
  EMACS_BIN=""
  while IFS= read -r candidate; do
    [ "$candidate" = "$HOME/.local/bin/emacs" ] && continue
    EMACS_BIN="$candidate"
    break
  done < <(type -P -a emacs || true)
  EMACS_BIN="${EMACS_BIN:-emacs}"
fi

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

echo "[1/6] Checking private config entrypoints"
if [ -e "$HOME/.authinfo" ]; then
  authinfo_mode="$(stat -Lc '%a %U %G' "$HOME/.authinfo")"
  echo "  - present: $HOME/.authinfo ($authinfo_mode)"
else
  echo "missing authinfo file: $HOME/.authinfo" >&2
  echo "run nohm pc and restart Emacs before retrying" >&2
  exit 1
fi

for private_file in \
  "$HOME/.config/slack/private.el" \
  "$HOME/.config/spotify/private.el"; do
  if [ -r "$private_file" ]; then
    echo "  - present: $private_file"
  else
    echo "  - optional or missing: $private_file"
  fi
done

echo "[2/6] Checking required executables"
for cmd in \
  aspell \
  python3 \
  nixd \
  basedpyright-langserver \
  cmake-language-server \
  bash-language-server \
  yaml-language-server \
  docker-langserver \
  marksman; do
  check_cmd "$cmd"
done

echo "[3/6] Checking aspell dictionaries"
dicts_output="$(aspell dump dicts)"
printf '%s\n' "$dicts_output"
printf '%s\n' "$dicts_output" | grep -qx 'en'
printf '%s\n' "$dicts_output" | grep -qx 'fr'
echo "  - aspell dictionaries include en and fr"

echo "[4/6] Checking runtime package and command availability in Emacs"
run_elisp '(progn
  (when (fboundp (quote dotspacemacs/user-init))
    (dotspacemacs/user-init))
  (when (fboundp (quote dotspacemacs/user-config))
    (dotspacemacs/user-config))
  (dolist (feature (quote (erc slack centaur-tabs all-the-icons nerd-icons markdown-mode dockerfile-mode nix-mode ghostel vterm multi-vterm)))
    (unless (require feature nil t)
      (princ (format "missing feature: %S\n" feature))
      (kill-emacs 1))
    (princ (format "loaded feature: %S\n" feature)))
  (unless (eq (symbol-function (quote shell)) (quote ghostel))
    (princ "shell is not aliased to ghostel\n")
    (kill-emacs 1))
  (dolist (fn (quote (erc/default-servers
                      erc-tls
                      slack-start
                      spotify-playpause)))
    (unless (fboundp fn)
      (princ (format "missing command: %S\n" fn))
      (kill-emacs 1))
    (princ (format "available command: %S\n" fn)))
  (princ (format "tabs-icons=%S\n" tabs-icons))
  (when (boundp (quote centaur-tabs-icon-type))
    (princ (format "centaur-tabs-icon-type=%S\n" centaur-tabs-icon-type)))
  (princ (format "slack private config exists=%S\n"
                 (file-readable-p (expand-file-name "~/.config/slack/private.el"))))
  (princ (format "spotify private config exists=%S\n"
                 (file-readable-p (expand-file-name "~/.config/spotify/private.el"))))
  (let ((libera-entry (car (auth-source-search :host "Libera.Chat"
                                               :user "lvanasse"
                                               :max 1
                                               :require (quote (:secret)))))
        (server-entry (car (auth-source-search :host "irc.libera.chat"
                                               :port 6697
                                               :user "lvanasse"
                                               :max 1
                                               :require (quote (:secret))))))
    (princ (format "auth-source Libera.Chat entry=%S\n" (and libera-entry t)))
    (princ (format "auth-source irc.libera.chat:6697 entry=%S\n" (and server-entry t)))
    (unless (and libera-entry server-entry)
      (princ "missing Libera auth-source entry\n")
      (kill-emacs 1)))
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

echo "[5/6] Checking this repo as the active project root"
repo_root="$(pwd)"
if [ ! -f "$repo_root/flake.nix" ]; then
  echo "expected to run from the dotfiles repo root; missing flake.nix in $repo_root" >&2
  exit 1
fi
echo "  - repo root: $repo_root"

echo "[6/6] IRC smoke checks passed"

echo "Spacemacs runtime smoke test passed."
