#!/usr/bin/env fish

set script_dir (path dirname (status --current-filename))
exec bash "$script_dir/smoke-test-spacemacs-runtime.sh" $argv
