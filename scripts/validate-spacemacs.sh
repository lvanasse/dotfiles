#!/usr/bin/env bash
set -euo pipefail

if [ $# -gt 2 ]; then
  echo "Usage: $0 [path-to-spacemacs-init.el] [path-to-spacemacs-.emacs.d]" >&2
  exit 2
fi

SPACEMACS_FILE="${1:-$HOME/.config/spacemacs/init.el}"
EMACSD_DIR="${2:-$HOME/.config/spacemacs/.emacs.d}"
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

TMP_HOME="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_HOME"
}
trap cleanup EXIT

mkdir -p "$TMP_HOME/.config/spacemacs"
ln -s "$SPACEMACS_FILE" "$TMP_HOME/.config/spacemacs/init.el"
cp -a "$EMACSD_DIR" "$TMP_HOME/.config/spacemacs/.emacs.d"
ln -s "$TMP_HOME/.config/spacemacs/.emacs.d" "$TMP_HOME/.emacs.d"
chmod -R u+w "$TMP_HOME/.config/spacemacs/.emacs.d" 2>/dev/null || true
if [ -d "$TMP_HOME/.config/spacemacs/.emacs.d/quelpa/packages" ]; then
  find "$TMP_HOME/.config/spacemacs/.emacs.d/quelpa/packages" -maxdepth 1 -type f \( -name '*.el' -o -name '.#*' \) -delete
fi
if [ -d "$TMP_HOME/.config/spacemacs/.emacs.d/.cache/quelpa/build" ]; then
  find "$TMP_HOME/.config/spacemacs/.emacs.d/.cache/quelpa/build" -mindepth 1 -maxdepth 1 \( -type d -o -type f \) -exec rm -rf {} +
fi
mkdir -p \
  "$TMP_HOME/.cache" \
  "$TMP_HOME/.local/state"

run_elisp() {
  HOME="$TMP_HOME" \
    SPACEMACSDIR="$TMP_HOME/.config/spacemacs" \
    "$EMACS_BIN" --batch --quick -l "$TMP_HOME/.config/spacemacs/.emacs.d/init.el" --eval "$1"
}

run_user_config='(progn
  (when (fboundp (quote dotspacemacs/user-config))
    (dotspacemacs/user-config))
  (when (fboundp (quote dotspacemacs/user-init))
    nil))'

echo "[1/5] Loading Spacemacs init with the target dotfile"
run_elisp '(princ "init-loaded")'
echo

echo "[2/5] Checking expected native layer bindings"
run_elisp "(progn
  ${run_user_config}
  (require 'core-keybindings)
  (dolist (entry '((\"SPC '\" . ghostel)
                   (\"SPC b g\" . ghostel)
                   (\"SPC b G\" . ghostel-project)
                   (\"SPC b t\" . ghostel)
                   (\"SPC b T\" . ghostel-project)
                   (\"SPC a e m\" . my/mu4e-open-inbox)
                   (\"SPC a e c\" . my/mu4e-compose-new)
                   (\"SPC a e l\" . my/open-mail-irc-layout)
                   (\"SPC a e u\" . mu4e-update-mail-and-index)
                   (\"SPC a c i\" . my/irc-dispatch)
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

echo "[3/5] Checking tab navigation bindings"
run_elisp "(progn
  ${run_user_config}
  (let* ((legacy-tabs
          '((\"g t\" evil-normal-state-map
             (spacemacs/tabs-forward centaur-tabs-forward tab-next))
            (\"g T\" evil-normal-state-map
             (spacemacs/tabs-backward centaur-tabs-backward tab-previous))))
         (current-tabs
          '((\"C-x t o\" global-map
             (spacemacs/tabs-forward centaur-tabs-forward tab-next))
            (\"C-x t O\" global-map
             (spacemacs/tabs-backward centaur-tabs-backward tab-previous))))
         (matched nil))
    (dolist (entry legacy-tabs)
      (let* ((key (nth 0 entry))
             (map (symbol-value (nth 1 entry)))
             (acceptable (nth 2 entry))
             (actual (lookup-key map (kbd key))))
        (princ (format \"%s => %S\\n\" key actual))
        (when (memq actual acceptable)
          (setq matched t))))
    (dolist (entry current-tabs)
      (let* ((key (nth 0 entry))
             (map (symbol-value (nth 1 entry)))
             (acceptable (nth 2 entry))
             (actual (lookup-key map (kbd key))))
        (princ (format \"%s => %S\\n\" key actual))
        (when (memq actual acceptable)
          (setq matched t))))
    (unless matched
      (kill-emacs 1))))"

echo "[4/5] Checking mail mode-line formatter"
run_elisp "(progn
  ${run_user_config}
  (let ((zero (my/mu4e-alert-mode-line-formatter 0))
        (two (my/mu4e-alert-mode-line-formatter 2)))
    (princ (format \"mail 0 => %s\\n\" zero))
    (princ (format \"mail 2 => %s\\n\" two))
    (unless (and (string= \"\" zero)
                 (string= \"\" two)
                 (string-match-p \"maildir:/ludovic/Index\" my/mu4e-alert-query)
                 (string-match-p \"maildir:/ludovic/Promotions\" my/mu4e-alert-query)
                 (string-match-p \"maildir:/ludovic/SocialNetworks\" my/mu4e-alert-query))
      (kill-emacs 1))))"

echo "[5/5] Checking Spacemacs home-buffer mode-line"
run_elisp "(progn
  ${run_user_config}
  (require (quote core-spacemacs-buffer))
  (require (quote spaceline-config))
  (setq my/mail-unread-count 2
        mu4e-alert-mode-line (my/mu4e-alert-mode-line-formatter 2))
  (spacemacs-buffer/goto-buffer t t)
  (with-current-buffer (get-buffer spacemacs-buffer-name)
    (let* ((formatted (format-mode-line mode-line-format))
           (line (if (string= formatted \"\")
                     (spaceline-ml-main)
                   formatted)))
      (princ (format \"home mode-line => %s\\n\" line))
      (unless (and (equal mode-line-format
                          (quote (\"%e\" (:eval (spaceline-ml-main)))))
                   (not (string-match-p \"my/spacemacs-home-mode-line\"
                                         (format \"%S\" mode-line-format))))
        (kill-emacs 1)))))"

echo "[bonus] Checking Spaceline redisplay fallback when evil-state is nil"
run_elisp "(progn
  ${run_user_config}
  (require (quote spaceline-config))
  (let ((evil-state nil))
    (princ (format \"nil-state mode-line => %s\\n\" (spaceline-ml-main)))))"

echo "Spacemacs validation passed."
