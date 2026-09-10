use std::{env, path::Path, process::Command};

use anyhow::{Context, Result, bail};

pub fn import(account_id: &str, path: &Path, dry_run: bool) -> Result<()> {
    let executable = env::var_os("ACTUAL_CLI").unwrap_or_else(|| "actual".into());
    let mut command = Command::new(executable);
    command
        .args(["transactions", "import", "--account"])
        .arg(account_id)
        .arg("--file")
        .arg(path);
    if dry_run {
        command.arg("--dry-run");
    }
    let status = command
        .status()
        .context("failed to execute the Actual CLI")?;
    if !status.success() {
        bail!("Actual CLI reconciliation failed with {status}");
    }
    Ok(())
}

#[cfg(all(test, unix))]
mod tests {
    use std::{fs, os::unix::fs::PermissionsExt, sync::Mutex};

    use super::*;

    static ENV_LOCK: Mutex<()> = Mutex::new(());

    #[test]
    fn cli_receives_password_by_environment_and_never_by_argument() {
        let _guard = ENV_LOCK.lock().unwrap();
        let temp = tempfile::tempdir().unwrap();
        let executable = temp.path().join("fake-actual");
        fs::write(
            &executable,
            r#"#!/bin/sh
case "$*" in *super-secret*) exit 41;; esac
test "${ACTUAL_PASSWORD-}" = super-secret || exit 42
exit 0
"#,
        )
        .unwrap();
        fs::set_permissions(&executable, fs::Permissions::from_mode(0o700)).unwrap();
        let input = temp.path().join("transactions.json");
        fs::write(&input, "[]").unwrap();

        // SAFETY: this test serializes its environment mutations, and no other
        // test in the crate reads these Actual-specific variables.
        unsafe {
            env::set_var("ACTUAL_CLI", &executable);
            env::set_var("ACTUAL_PASSWORD", "super-secret");
        }
        let result = import("account-id", &input, true);
        unsafe {
            env::remove_var("ACTUAL_CLI");
            env::remove_var("ACTUAL_PASSWORD");
        }
        result.unwrap();
    }
}
