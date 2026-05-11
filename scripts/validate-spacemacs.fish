#!/usr/bin/env fish

set script_dir (path dirname (status --current-filename))
exec bash "$script_dir/validate-spacemacs.sh" $argv
