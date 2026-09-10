mod actual;
mod amount;
mod model;
mod transport;
mod wealthsimple;

use std::{
    env, fs,
    io::{self, Write},
    path::{Path, PathBuf},
};

use anyhow::{Context, Result, bail};
use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use wealthsimple::{Session, Wealthsimple};

const DEFAULT_WINDOW_DAYS: i64 = 45;
const MANUAL_AUTH_EXIT: i32 = 20;

#[derive(Parser)]
#[command(
    version,
    about = "Fail-closed Wealthsimple Cash and Credit Card to Actual importer"
)]
struct Cli {
    #[arg(long, env = "WEALTHSIMPLE_ACTUAL_STATE_DIR")]
    state_dir: Option<PathBuf>,
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// Create a read-only OAuth session. Password and TOTP are never persisted.
    Auth,
    /// Refresh the session and list eligible Wealthsimple import accounts.
    Accounts,
    /// Fetch and validate a backfill, without contacting Actual.
    Stage {
        #[arg(long, default_value = "90d", value_parser = parse_duration_days)]
        since: i64,
    },
    /// Fetch a rolling window and ask Actual to reconcile/import it.
    Sync {
        #[arg(long)]
        dry_run: bool,
    },
}

#[derive(Debug, Serialize, Deserialize)]
struct StagedBatch {
    generated_at: String,
    cash: StagedAccount,
    credit_card: StagedAccount,
}

#[derive(Debug, Serialize, Deserialize)]
struct StagedAccount {
    kind: model::AccountKind,
    wealthsimple_account_id: String,
    since: String,
    wealthsimple_balance_cents: i64,
    transactions: Vec<model::ActualTransaction>,
}

fn parse_duration_days(value: &str) -> std::result::Result<i64, String> {
    let days = value
        .strip_suffix('d')
        .ok_or_else(|| "duration must end in d (for example 90d)".to_owned())?
        .parse::<i64>()
        .map_err(|_| "duration must contain a whole number of days".to_owned())?;
    if days <= 0 || days > 3660 {
        return Err("duration must be between 1d and 3660d".to_owned());
    }
    Ok(days)
}

fn state_dir(cli: &Cli) -> PathBuf {
    cli.state_dir
        .clone()
        .or_else(|| env::var_os("STATE_DIRECTORY").map(PathBuf::from))
        .unwrap_or_else(|| PathBuf::from("/var/lib/wealthsimple-actual-sync"))
}

fn atomic_json<T: Serialize>(path: &Path, value: &T) -> Result<()> {
    let parent = path.parent().context("state path has no parent")?;
    fs::create_dir_all(parent)?;
    let mut tmp = tempfile::NamedTempFile::new_in(parent)?;
    serde_json::to_writer_pretty(&mut tmp, value)?;
    tmp.write_all(b"\n")?;
    tmp.as_file().sync_all()?;
    tmp.persist(path).map_err(|error| error.error)?;
    Ok(())
}

fn required_env(name: &str) -> Result<String> {
    env::var(name).with_context(|| format!("required environment variable {name} is missing"))
}

fn load_session(path: &Path) -> Result<Session> {
    let data = fs::read(path).map_err(|_error| {
        wealthsimple::Error::ManualAuthentication(format!(
            "OAuth session is unavailable at {}; run `wealthsimple-actual-sync auth`",
            path.display()
        ))
    })?;
    serde_json::from_slice(&data).map_err(|error| {
        wealthsimple::Error::ManualAuthentication(format!("OAuth session is invalid: {error}"))
            .into()
    })
}

fn prompt(label: &str) -> Result<String> {
    eprint!("{label}: ");
    io::stderr().flush()?;
    let mut value = String::new();
    io::stdin().read_line(&mut value)?;
    let value = value.trim().to_owned();
    if value.is_empty() {
        bail!("{label} cannot be empty");
    }
    Ok(value)
}

fn run(cli: Cli) -> Result<()> {
    let dir = state_dir(&cli);
    fs::create_dir_all(&dir)?;
    let session_path = dir.join("oauth-session.json");

    match cli.command {
        Command::Auth => {
            let email = prompt("Wealthsimple email")?;
            let password = rpassword::prompt_password("Wealthsimple password: ")?;
            if password.is_empty() {
                bail!("Wealthsimple password cannot be empty");
            }
            let mut ws = Wealthsimple::bootstrap()?;
            let session = match ws.login(&email, &password, None) {
                Err(wealthsimple::Error::OtpRequired) => {
                    let otp = rpassword::prompt_password("Wealthsimple TOTP: ")?;
                    ws.login(&email, &password, Some(&otp))?
                }
                result => result?,
            };
            atomic_json(&session_path, &session)?;
            println!(
                "Read-only OAuth session saved to {}",
                session_path.display()
            );
            let accounts = ws.import_accounts()?;
            if accounts.is_empty() {
                bail!("authentication succeeded, but no eligible open CAD accounts were found");
            }
            println!("Eligible Wealthsimple import accounts:");
            for account in accounts {
                println!("  {:?}: {} ({})", account.kind, account.label, account.id);
            }
        }
        Command::Accounts => {
            let mut ws = Wealthsimple::from_session(load_session(&session_path)?)?;
            ws.refresh()?;
            atomic_json(&session_path, ws.session())?;
            let accounts = ws.import_accounts()?;
            if accounts.is_empty() {
                bail!("no eligible open CAD Cash or Credit Card accounts were found");
            }
            println!("Eligible Wealthsimple import accounts:");
            for account in accounts {
                println!("  {:?}: {} ({})", account.kind, account.label, account.id);
            }
        }
        Command::Stage { since } => {
            let cash_id = required_env("WEALTHSIMPLE_ACCOUNT_ID")?;
            let card_id = required_env("WEALTHSIMPLE_CREDIT_CARD_ACCOUNT_ID")?;
            let mut ws = Wealthsimple::from_session(load_session(&session_path)?)?;
            ws.refresh()?;
            atomic_json(&session_path, ws.session())?;
            ws.verify_account(&cash_id, model::AccountKind::Cash)?;
            ws.verify_account(&card_id, model::AccountKind::CreditCard)?;
            let cash = ws.fetch_ledger(&cash_id, model::AccountKind::Cash, since)?;
            let card = ws.fetch_ledger(&card_id, model::AccountKind::CreditCard, since)?;
            let cash_balance = ws.fetch_cad_balance(&cash_id)?;
            let card_balance = ws.fetch_credit_card_balance(&card_id)?;
            let batch = StagedBatch {
                generated_at: chrono::Utc::now().to_rfc3339(),
                cash: StagedAccount {
                    kind: model::AccountKind::Cash,
                    wealthsimple_account_id: cash_id,
                    since: cash.since.to_rfc3339(),
                    wealthsimple_balance_cents: cash_balance,
                    transactions: cash.transactions,
                },
                credit_card: StagedAccount {
                    kind: model::AccountKind::CreditCard,
                    wealthsimple_account_id: card_id,
                    since: card.since.to_rfc3339(),
                    wealthsimple_balance_cents: card_balance,
                    transactions: card.transactions,
                },
            };
            let path = dir.join("staged-transactions.json");
            atomic_json(&path, &batch)?;
            println!(
                "Validated {} Cash and {} Credit Card transactions; staged {} (balances: Cash {} cents, Credit Card {} cents)",
                batch.cash.transactions.len(),
                batch.credit_card.transactions.len(),
                path.display(),
                batch.cash.wealthsimple_balance_cents,
                batch.credit_card.wealthsimple_balance_cents,
            );
        }
        Command::Sync { dry_run } => {
            let cash_id = required_env("WEALTHSIMPLE_ACCOUNT_ID")?;
            let card_id = required_env("WEALTHSIMPLE_CREDIT_CARD_ACCOUNT_ID")?;
            let actual_cash = required_env("ACTUAL_ACCOUNT_ID")?;
            let actual_card = required_env("ACTUAL_CREDIT_CARD_ACCOUNT_ID")?;
            let mut ws = Wealthsimple::from_session(load_session(&session_path)?)?;
            ws.refresh()?;
            atomic_json(&session_path, ws.session())?;
            ws.verify_account(&cash_id, model::AccountKind::Cash)?;
            ws.verify_account(&card_id, model::AccountKind::CreditCard)?;
            let cash = ws.fetch_ledger(&cash_id, model::AccountKind::Cash, DEFAULT_WINDOW_DAYS)?;
            let card = ws.fetch_ledger(
                &card_id,
                model::AccountKind::CreditCard,
                DEFAULT_WINDOW_DAYS,
            )?;
            let cash_balance = ws.fetch_cad_balance(&cash_id)?;
            let card_balance = ws.fetch_credit_card_balance(&card_id)?;
            let cash_import_path = dir.join("actual-import-cash.json");
            let card_import_path = dir.join("actual-import-credit-card.json");
            atomic_json(&cash_import_path, &cash.transactions)?;
            atomic_json(&card_import_path, &card.transactions)?;
            actual::import(&actual_cash, &cash_import_path, dry_run)?;
            actual::import(&actual_card, &card_import_path, dry_run)?;
            if !dry_run {
                atomic_json(
                    &dir.join("last-sync.json"),
                    &serde_json::json!({
                        "completed_at": chrono::Utc::now().to_rfc3339(),
                        "cash": {
                            "since": cash.since,
                            "transaction_count": cash.transactions.len(),
                            "wealthsimple_balance_cents": cash_balance,
                        },
                        "credit_card": {
                            "since": card.since,
                            "transaction_count": card.transactions.len(),
                            "wealthsimple_balance_cents": card_balance,
                        },
                    }),
                )?;
            }
            println!(
                "{} {} Cash and {} Credit Card transactions (balances: Cash {} cents, Credit Card {} cents)",
                if dry_run {
                    "Previewed"
                } else {
                    "Imported/reconciled"
                },
                cash.transactions.len(),
                card.transactions.len(),
                cash_balance,
                card_balance,
            );
        }
    }
    Ok(())
}

fn main() {
    let cli = Cli::parse();
    if let Err(error) = run(cli) {
        eprintln!("wealthsimple-actual-sync: {error:#}");
        let manual = error.chain().any(|cause| {
            cause
                .downcast_ref::<wealthsimple::Error>()
                .is_some_and(|error| matches!(error, wealthsimple::Error::ManualAuthentication(_)))
        });
        std::process::exit(if manual { MANUAL_AUTH_EXIT } else { 1 });
    }
}

#[cfg(test)]
mod tests {
    use super::parse_duration_days;

    #[test]
    fn parses_bounded_day_duration() {
        assert_eq!(parse_duration_days("90d"), Ok(90));
        assert!(parse_duration_days("0d").is_err());
        assert!(parse_duration_days("90").is_err());
    }
}
