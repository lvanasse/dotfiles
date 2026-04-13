#!/bin/bash
set -euo pipefail

sudo_bin="${SUDO_BIN:-sudo}"
install_bin="${INSTALL_BIN:-install}"
ln_bin="${LN_BIN:-ln}"

pam_swaylock_src="${PAM_SWAYLOCK_SRC:-$HOME/.local/share/pam/swaylock}"
pam_swaylock_file="${PAM_SWAYLOCK_FILE:-/etc/pam.d/swaylock}"
unix_chkpwd_bin="${UNIX_CHKPWD_BIN:-/sbin/unix_chkpwd}"
run_wrappers_dir="${RUN_WRAPPERS_DIR:-/run/wrappers/bin}"
unix_chkpwd_link="${run_wrappers_dir}/unix_chkpwd"

if [ -f "$pam_swaylock_src" ]; then
    if [ ! -f "$pam_swaylock_file" ] || ! cmp -s "$pam_swaylock_src" "$pam_swaylock_file"; then
        echo "Installing swaylock PAM config..."
        "$sudo_bin" "$install_bin" -m 0644 "$pam_swaylock_src" "$pam_swaylock_file"
    else
        echo "swaylock PAM config already up to date."
    fi
else
    echo "Warning: no swaylock PAM template found at $pam_swaylock_src" >&2
fi

if [ -x "$unix_chkpwd_bin" ]; then
    "$sudo_bin" "$install_bin" -d -m 0755 "$run_wrappers_dir"
    if [ ! -e "$unix_chkpwd_link" ] || [ "$(readlink -f "$unix_chkpwd_link")" != "$unix_chkpwd_bin" ]; then
        echo "Linking unix_chkpwd for swaylock PAM..."
        "$sudo_bin" "$ln_bin" -sf "$unix_chkpwd_bin" "$unix_chkpwd_link"
    else
        echo "unix_chkpwd wrapper already present."
    fi
else
    echo "Warning: $unix_chkpwd_bin not found; swaylock auth may fail" >&2
fi
