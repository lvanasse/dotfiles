#!/usr/bin/env bash
set -euo pipefail

if [ $# -gt 2 ]; then
  echo "Usage: $0 [path-to-.spacemacs] [path-to-.emacs.d]" >&2
  exit 2
fi

SPACEMACS_FILE="${1:-$HOME/.spacemacs}"
EMACSD_DIR="${2:-$HOME/.emacs.d}"
EMACS_BIN="${EMACS_BIN:-emacs}"

if [ ! -f "$SPACEMACS_FILE" ]; then
  echo "spacemacs file not found: $SPACEMACS_FILE" >&2
  exit 1
fi

if [ ! -f "$EMACSD_DIR/init.el" ]; then
  echo "Spacemacs init.el not found under: $EMACSD_DIR" >&2
  exit 1
fi

TMP_HOME="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_HOME"
}
trap cleanup EXIT

ln -s "$SPACEMACS_FILE" "$TMP_HOME/.spacemacs"
ln -s "$EMACSD_DIR" "$TMP_HOME/.emacs.d"
mkdir -p \
  "$TMP_HOME/.config" \
  "$TMP_HOME/.cache" \
  "$TMP_HOME/.local/state"

run_elisp() {
  HOME="$TMP_HOME" "$EMACS_BIN" --batch --quick -l "$TMP_HOME/.emacs.d/init.el" --eval "$1"
}

run_user_config='(progn
  (when (fboundp (quote dotspacemacs/user-config))
    (dotspacemacs/user-config))
  (when (fboundp (quote dotspacemacs/user-init))
    nil))'

echo "[1/4] Loading Spacemacs init with the target dotfile"
run_elisp "(princ \"init-loaded\")"
echo

echo "[2/4] Checking expected native layer bindings"
run_elisp "(progn
  ${run_user_config}
  (require 'core-keybindings)
  (dolist (entry '((\"SPC $ c\" . copilot-chat-transient)
                   (\"SPC $ m\" . mcp-hub)
                   (\"SPC $ d y\" . claude-code-ide-menu)
                   (\"SPC '\" . spacemacs/default-pop-shell)
                   (\"SPC a e m\" . mu4e)
                   (\"SPC a e c\" . my/mu4e-compose-new)
                   (\"SPC a e u\" . mu4e-update-mail-and-index)
                   (\"SPC a c i r\" . spacemacs/rcirc)
                   (\"SPC a c s s\" . slack-start)
                   (\"SPC a m s p\" . spotify-playpause)
                   (\"SPC a t d\" . docker)
                   (\"SPC a o S\" . my/org-caldav-sync)
                   (\"SPC S b\" . flyspell-buffer)
                   (\"SPC t S\" . spacemacs/toggle-spelling-checking)
                   (\"SPC e l\" . spacemacs/toggle-flycheck-error-list)))
    (let* ((key (car entry))
           (expected (cdr entry))
           (actual (lookup-key spacemacs-default-map (kbd (substring key 4)))))
      (princ (format \"%s => %S\\n\" key actual))
      (unless (eq actual expected)
        (kill-emacs 1)))))"

echo "[3/4] Checking expected tab bindings"
run_elisp "(progn
  ${run_user_config}
  (dolist (entry '((\"g t\" . spacemacs/tabs-forward)
                   (\"g T\" . spacemacs/tabs-backward)))
    (let* ((key (car entry))
           (expected (cdr entry))
           (actual (lookup-key evil-normal-state-map (kbd key))))
      (princ (format \"%s => %S\\n\" key actual))
      (unless (eq actual expected)
        (kill-emacs 1)))))"

echo "Spacemacs validation passed."
