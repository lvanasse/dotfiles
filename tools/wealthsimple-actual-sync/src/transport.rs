use std::{env, ffi::OsStr, fs, io::Write, process::Command};

use anyhow::{Context, Result, bail};
use serde_json::Value;

#[derive(Debug)]
pub struct Response {
    pub status: u16,
    pub headers: String,
    pub body: Vec<u8>,
}

fn curl_escape(value: &str) -> String {
    value
        .replace('\\', "\\\\")
        .replace('"', "\\\"")
        .replace('\n', "")
}

pub fn request(
    method: &str,
    url: &str,
    headers: &[(&str, String)],
    body: Option<&Value>,
) -> Result<Response> {
    let executable = env::var_os("WEALTHSIMPLE_CURL").unwrap_or_else(|| "curl_chrome142".into());
    request_with(&executable, method, url, headers, body)
}

fn request_with(
    executable: &OsStr,
    method: &str,
    url: &str,
    headers: &[(&str, String)],
    body: Option<&Value>,
) -> Result<Response> {
    let temp = tempfile::tempdir()?;
    let config_path = temp.path().join("curl.conf");
    let body_path = temp.path().join("request.json");
    let output_path = temp.path().join("response.json");
    let header_path = temp.path().join("response.headers");
    if let Some(body) = body {
        let mut file = fs::File::create(&body_path)?;
        serde_json::to_writer(&mut file, body)?;
        file.sync_all()?;
    }
    let mut config = fs::File::create(&config_path)?;
    writeln!(config, "silent")?;
    writeln!(config, "show-error")?;
    writeln!(config, "location")?;
    writeln!(config, "request = \"{}\"", curl_escape(method))?;
    writeln!(config, "url = \"{}\"", curl_escape(url))?;
    writeln!(config, "output = \"{}\"", output_path.display())?;
    writeln!(config, "dump-header = \"{}\"", header_path.display())?;
    writeln!(config, "write-out = \"%{{http_code}}\"")?;
    for (name, value) in headers {
        writeln!(
            config,
            "header = \"{}: {}\"",
            curl_escape(name),
            curl_escape(value)
        )?;
    }
    if body.is_some() {
        writeln!(config, "header = \"Content-Type: application/json\"")?;
        writeln!(config, "data-binary = \"@{}\"", body_path.display())?;
    }
    config.sync_all()?;
    let output = Command::new(executable)
        .arg("--config")
        .arg(&config_path)
        .output()
        .context("failed to execute curl-impersonate")?;
    if !output.status.success() {
        bail!(
            "Wealthsimple HTTP transport failed: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        );
    }
    let status: u16 = String::from_utf8_lossy(&output.stdout)
        .trim()
        .parse()
        .context("curl returned an invalid HTTP status")?;
    let response = Response {
        status,
        headers: fs::read_to_string(header_path).unwrap_or_default(),
        body: fs::read(output_path).unwrap_or_default(),
    };
    if response.status == 429 {
        bail!("Wealthsimple rate limited the request (HTTP 429); no import was attempted");
    }
    Ok(response)
}

#[cfg(test)]
mod tests {
    use std::{fs, os::unix::fs::PermissionsExt};

    use super::{curl_escape, request_with};

    #[test]
    fn curl_config_values_cannot_add_directives() {
        assert_eq!(
            curl_escape("token\noutput = /tmp/leak"),
            "tokenoutput = /tmp/leak"
        );
        assert_eq!(curl_escape("a\"b"), "a\\\"b");
    }

    #[test]
    fn mocked_transport_reports_rate_limit_without_bearer_in_arguments() {
        let temp = tempfile::tempdir().unwrap();
        let executable = temp.path().join("fake-curl");
        fs::write(
            &executable,
            r#"#!/bin/sh
case "$*" in *bearer-secret*) exit 41;; esac
config="$2"
output="$(sed -n 's/^output = "\(.*\)"$/\1/p' "$config")"
headers="$(sed -n 's/^dump-header = "\(.*\)"$/\1/p' "$config")"
printf '{}' > "$output"
: > "$headers"
printf 429
"#,
        )
        .unwrap();
        fs::set_permissions(&executable, fs::Permissions::from_mode(0o700)).unwrap();
        let error = request_with(
            executable.as_os_str(),
            "POST",
            "https://example.invalid/graphql",
            &[("Authorization", "Bearer bearer-secret".to_owned())],
            Some(&serde_json::json!({ "safe": true })),
        )
        .unwrap_err();
        assert!(error.to_string().contains("HTTP 429"));
    }
}
