use chrono::{DateTime, Utc};
use chrono_tz::America::Toronto;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use thiserror::Error;

use crate::amount;

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum AccountKind {
    Cash,
    CreditCard,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Activity {
    pub account_id: Option<String>,
    pub amount: Option<Value>,
    pub amount_sign: Option<String>,
    pub canonical_id: Option<String>,
    pub currency: Option<String>,
    pub occurred_at: Option<String>,
    pub status: Option<String>,
    #[serde(rename = "type")]
    pub kind: Option<String>,
    pub sub_type: Option<String>,
    pub spend_merchant: Option<String>,
    pub e_transfer_name: Option<String>,
    pub e_transfer_email: Option<String>,
    pub aft_originator_name: Option<String>,
    pub bill_pay_company_name: Option<String>,
    pub bill_pay_payee_nickname: Option<String>,
    pub p2p_handle: Option<String>,
    pub reward_program: Option<String>,
    pub opposing_account_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ActualTransaction {
    pub date: String,
    pub amount: i64,
    pub payee_name: String,
    pub notes: String,
    pub imported_id: String,
    pub cleared: bool,
}

#[derive(Debug, Error)]
pub enum Error {
    #[error("activity is missing {0}")]
    Missing(&'static str),
    #[error("activity {0} has unsupported currency {1}")]
    Currency(String, String),
    #[error("activity {0} has unknown status {1}")]
    Status(String, String),
    #[error("activity {0} has unsupported shape {1}/{2}")]
    Shape(String, String, String),
    #[error("activity {0} has invalid amount: {1}")]
    Amount(String, #[source] amount::Error),
    #[error("activity {0} has invalid timestamp {1}")]
    Timestamp(String, String),
    #[error("activity {0} has invalid amount sign {1}")]
    Sign(String, String),
    #[error("activity {0} belongs to unexpected account {1}")]
    Account(String, String),
}

pub enum Disposition {
    Import(ActualTransaction),
    OmitPending,
    OmitTerminal,
}

fn required<'a>(value: &'a Option<String>, field: &'static str) -> Result<&'a str, Error> {
    value
        .as_deref()
        .filter(|value| !value.trim().is_empty())
        .ok_or(Error::Missing(field))
}

fn text(value: Option<&String>, fallback: &str) -> String {
    value
        .map(|value| value.trim())
        .filter(|value| !value.is_empty())
        .unwrap_or(fallback)
        .to_owned()
}

pub fn normalize(
    activity: &Activity,
    expected_account: &str,
    account_kind: AccountKind,
) -> Result<Disposition, Error> {
    let id = required(&activity.canonical_id, "canonicalId")?;
    let account = required(&activity.account_id, "accountId")?;
    if account != expected_account {
        return Err(Error::Account(id.to_owned(), account.to_owned()));
    }
    let currency = required(&activity.currency, "currency")?;
    if currency != "CAD" {
        return Err(Error::Currency(id.to_owned(), currency.to_owned()));
    }
    let status = required(&activity.status, "status")?.to_ascii_lowercase();
    match status.as_str() {
        "authorized" | "pending" | "submitted" => return Ok(Disposition::OmitPending),
        "rejected" | "cancelled" | "canceled" | "expired" => return Ok(Disposition::OmitTerminal),
        "settled" | "completed" | "complete" | "processed" | "succeeded" => {}
        _ => return Err(Error::Status(id.to_owned(), status)),
    }

    let kind = required(&activity.kind, "type")?.to_ascii_uppercase();
    let subtype = activity
        .sub_type
        .as_deref()
        .unwrap_or("")
        .to_ascii_uppercase();
    let (payee, notes) = match (kind.as_str(), subtype.as_str()) {
        ("SPEND", "PREPAID") | ("CREDIT_CARD", "PURCHASE") => {
            let merchant = required(&activity.spend_merchant, "spendMerchant")?.to_owned();
            (merchant.clone(), format!("Purchase: {merchant}"))
        }
        ("CREDIT_CARD", "REFUND") | ("CREDIT_CARD", "HOLD") => {
            let merchant = required(&activity.spend_merchant, "spendMerchant")?.to_owned();
            (merchant.clone(), format!("Refund: {merchant}"))
        }
        ("CREDIT_CARD", "PAYMENT") | ("CREDIT_CARD_PAYMENT", "" | "PAYMENT") => {
            let payee = match account_kind {
                AccountKind::Cash => "Wealthsimple Credit Card",
                AccountKind::CreditCard => "Wealthsimple Cash",
            };
            (payee.to_owned(), "Credit card payment".to_owned())
        }
        ("DEPOSIT", "E_TRANSFER" | "E_TRANSFER_FUNDING") => {
            let party = text(activity.e_transfer_name.as_ref(), "Interac e-transfer");
            let email = text(activity.e_transfer_email.as_ref(), "unknown sender");
            (
                party.clone(),
                format!("Interac e-transfer from {party} ({email})"),
            )
        }
        ("WITHDRAWAL", "E_TRANSFER" | "E_TRANSFER_FUNDING") => {
            let party = text(activity.e_transfer_name.as_ref(), "Interac e-transfer");
            let email = text(activity.e_transfer_email.as_ref(), "unknown recipient");
            (
                party.clone(),
                format!("Interac e-transfer to {party} ({email})"),
            )
        }
        ("DEPOSIT", "AFT") => {
            let party = text(activity.aft_originator_name.as_ref(), "Direct deposit");
            (party.clone(), format!("Direct deposit from {party}"))
        }
        ("WITHDRAWAL", "AFT") => {
            let party = text(
                activity.aft_originator_name.as_ref(),
                "Pre-authorized debit",
            );
            (party.clone(), format!("Pre-authorized debit to {party}"))
        }
        ("DEPOSIT", "EFT") => ("External account".to_owned(), "EFT deposit".to_owned()),
        ("WITHDRAWAL", "EFT") => ("External account".to_owned(), "EFT withdrawal".to_owned()),
        ("DEPOSIT", "PAYMENT_CARD_TRANSACTION") => (
            "Debit card funding".to_owned(),
            "Debit card funding".to_owned(),
        ),
        ("WITHDRAWAL", "BILL_PAY") => {
            let party = text(
                activity
                    .bill_pay_payee_nickname
                    .as_ref()
                    .or(activity.bill_pay_company_name.as_ref()),
                "Bill payment",
            );
            (party.clone(), format!("Bill payment to {party}"))
        }
        ("P2P_PAYMENT", "SEND") => {
            let party = text(activity.p2p_handle.as_ref(), "Wealthsimple Cash recipient");
            (party.clone(), format!("Cash sent to {party}"))
        }
        ("P2P_PAYMENT", "SEND_RECEIVED") => {
            let party = text(activity.p2p_handle.as_ref(), "Wealthsimple Cash sender");
            (party.clone(), format!("Cash received from {party}"))
        }
        ("INTERNAL_TRANSFER" | "ASSET_MOVEMENT", "SOURCE") => {
            let opposing = text(
                activity.opposing_account_id.as_ref(),
                "another Wealthsimple account",
            );
            (
                "Wealthsimple transfer".to_owned(),
                format!("Transfer to {opposing}"),
            )
        }
        ("INTERNAL_TRANSFER" | "ASSET_MOVEMENT", "DESTINATION") => {
            let opposing = text(
                activity.opposing_account_id.as_ref(),
                "another Wealthsimple account",
            );
            (
                "Wealthsimple transfer".to_owned(),
                format!("Transfer from {opposing}"),
            )
        }
        ("LEGACY_INTERNAL_TRANSFER", "SOURCE") => (
            "Wealthsimple transfer".to_owned(),
            "Transfer out".to_owned(),
        ),
        ("LEGACY_INTERNAL_TRANSFER", "DESTINATION") => {
            ("Wealthsimple transfer".to_owned(), "Transfer in".to_owned())
        }
        ("REFUND", "" | "TRANSFER_FEE_REFUND") => (
            "Wealthsimple refund".to_owned(),
            if subtype.is_empty() {
                "Refund"
            } else {
                "Account transfer fee refund"
            }
            .to_owned(),
        ),
        ("INTEREST", "" | "FPL_INTEREST") => (
            "Wealthsimple interest".to_owned(),
            if subtype == "FPL_INTEREST" {
                "Stock lending earnings"
            } else {
                "Interest"
            }
            .to_owned(),
        ),
        ("REIMBURSEMENT", "CASHBACK" | "ETF_REBATE" | "REWARD" | "ATM") => {
            let detail = match subtype.as_str() {
                "CASHBACK"
                    if activity.reward_program.as_deref()
                        == Some("CREDIT_CARD_VISA_INFINITE_REWARDS") =>
                {
                    "Cash back - Visa Infinite"
                }
                "CASHBACK" => "Cash back",
                "ETF_REBATE" => "ETF rebate",
                "REWARD" => "Reward",
                _ => "ATM fee reimbursement",
            };
            ("Wealthsimple reimbursement".to_owned(), detail.to_owned())
        }
        ("FEE", "MANAGEMENT_FEE" | "") => ("Wealthsimple fee".to_owned(), "Fee".to_owned()),
        ("PROMOTION", "INCENTIVE_BONUS") => (
            "Wealthsimple promotion".to_owned(),
            "Incentive bonus".to_owned(),
        ),
        ("REFERRAL", "") => (
            "Wealthsimple referral".to_owned(),
            "Referral reward".to_owned(),
        ),
        _ => return Err(Error::Shape(id.to_owned(), kind, subtype)),
    };

    let lexical_amount = match activity.amount.as_ref().ok_or(Error::Missing("amount"))? {
        Value::String(value) => value.clone(),
        Value::Number(value) => value.to_string(),
        _ => {
            return Err(Error::Amount(
                id.to_owned(),
                amount::Error::Invalid("non-numeric JSON value".to_owned()),
            ));
        }
    };
    let parsed = amount::decimal_to_cents(&lexical_amount)
        .map_err(|error| Error::Amount(id.to_owned(), error))?;
    if parsed < 0 {
        return Err(Error::Sign(
            id.to_owned(),
            "amount must be unsigned when amountSign is present".to_owned(),
        ));
    }
    let absolute = parsed;
    let sign = required(&activity.amount_sign, "amountSign")?.to_ascii_lowercase();
    let cents = match sign.as_str() {
        "positive" => absolute,
        "negative" => -absolute,
        _ => return Err(Error::Sign(id.to_owned(), sign)),
    };
    let occurred = required(&activity.occurred_at, "occurredAt")?;
    let timestamp = DateTime::parse_from_rfc3339(occurred)
        .map_err(|_| Error::Timestamp(id.to_owned(), occurred.to_owned()))?;
    let date = timestamp
        .with_timezone(&Utc)
        .with_timezone(&Toronto)
        .date_naive()
        .to_string();

    Ok(Disposition::Import(ActualTransaction {
        date,
        amount: cents,
        payee_name: payee,
        notes,
        imported_id: format!("wealthsimple:{id}"),
        cleared: true,
    }))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn activity(kind: &str, subtype: &str) -> Activity {
        serde_json::from_value(serde_json::json!({
            "accountId": "cash-1", "amount": "12.34", "amountSign": "negative",
            "canonicalId": "abc", "currency": "CAD", "occurredAt": "2026-01-01T04:30:00Z",
            "status": "settled", "type": kind, "subType": subtype, "spendMerchant": "Market"
        }))
        .unwrap()
    }

    #[test]
    fn purchase_has_stable_id_sign_payee_and_toronto_date() {
        let Disposition::Import(tx) =
            normalize(&activity("SPEND", "PREPAID"), "cash-1", AccountKind::Cash).unwrap()
        else {
            panic!()
        };
        assert_eq!(tx.imported_id, "wealthsimple:abc");
        assert_eq!(tx.amount, -1234);
        assert_eq!(tx.payee_name, "Market");
        assert_eq!(tx.date, "2025-12-31");
    }

    #[test]
    fn pending_is_omitted_then_settled_imports() {
        let mut pending = activity("SPEND", "PREPAID");
        pending.status = Some("authorized".to_owned());
        assert!(matches!(
            normalize(&pending, "cash-1", AccountKind::Cash),
            Ok(Disposition::OmitPending)
        ));
        assert!(matches!(
            normalize(&activity("SPEND", "PREPAID"), "cash-1", AccountKind::Cash),
            Ok(Disposition::Import(_))
        ));
    }

    #[test]
    fn unknown_data_fails_closed() {
        assert!(matches!(
            normalize(
                &activity("NEW_TYPE", "MYSTERY"),
                "cash-1",
                AccountKind::Cash
            ),
            Err(Error::Shape(..))
        ));
        let mut usd = activity("SPEND", "PREPAID");
        usd.currency = Some("USD".to_owned());
        assert!(matches!(
            normalize(&usd, "cash-1", AccountKind::Cash),
            Err(Error::Currency(..))
        ));
        let mut status = activity("SPEND", "PREPAID");
        status.status = Some("new-status".to_owned());
        assert!(matches!(
            normalize(&status, "cash-1", AccountKind::Cash),
            Err(Error::Status(..))
        ));
    }

    #[test]
    fn every_supported_cash_shape_normalizes() {
        let shapes = [
            ("SPEND", "PREPAID"),
            ("CREDIT_CARD", "PURCHASE"),
            ("CREDIT_CARD", "REFUND"),
            ("CREDIT_CARD", "HOLD"),
            ("CREDIT_CARD", "PAYMENT"),
            ("CREDIT_CARD_PAYMENT", "PAYMENT"),
            ("DEPOSIT", "E_TRANSFER"),
            ("DEPOSIT", "E_TRANSFER_FUNDING"),
            ("WITHDRAWAL", "E_TRANSFER"),
            ("WITHDRAWAL", "E_TRANSFER_FUNDING"),
            ("DEPOSIT", "AFT"),
            ("WITHDRAWAL", "AFT"),
            ("DEPOSIT", "EFT"),
            ("WITHDRAWAL", "EFT"),
            ("DEPOSIT", "PAYMENT_CARD_TRANSACTION"),
            ("WITHDRAWAL", "BILL_PAY"),
            ("P2P_PAYMENT", "SEND"),
            ("P2P_PAYMENT", "SEND_RECEIVED"),
            ("INTERNAL_TRANSFER", "SOURCE"),
            ("INTERNAL_TRANSFER", "DESTINATION"),
            ("ASSET_MOVEMENT", "SOURCE"),
            ("ASSET_MOVEMENT", "DESTINATION"),
            ("LEGACY_INTERNAL_TRANSFER", "SOURCE"),
            ("LEGACY_INTERNAL_TRANSFER", "DESTINATION"),
            ("REFUND", ""),
            ("REFUND", "TRANSFER_FEE_REFUND"),
            ("INTEREST", ""),
            ("INTEREST", "FPL_INTEREST"),
            ("REIMBURSEMENT", "CASHBACK"),
            ("REIMBURSEMENT", "ETF_REBATE"),
            ("REIMBURSEMENT", "REWARD"),
            ("REIMBURSEMENT", "ATM"),
            ("FEE", ""),
            ("FEE", "MANAGEMENT_FEE"),
            ("PROMOTION", "INCENTIVE_BONUS"),
            ("REFERRAL", ""),
        ];
        for (kind, subtype) in shapes {
            assert!(
                matches!(
                    normalize(&activity(kind, subtype), "cash-1", AccountKind::Cash),
                    Ok(Disposition::Import(_))
                ),
                "{kind}/{subtype}"
            );
        }
    }

    #[test]
    fn canonical_id_is_deterministic_across_refetches() {
        let first = normalize(&activity("SPEND", "PREPAID"), "cash-1", AccountKind::Cash).unwrap();
        let second = normalize(&activity("SPEND", "PREPAID"), "cash-1", AccountKind::Cash).unwrap();
        let (Disposition::Import(first), Disposition::Import(second)) = (first, second) else {
            panic!()
        };
        assert_eq!(first, second);
    }

    #[test]
    fn card_payments_target_the_other_actual_account() {
        let cash = normalize(
            &activity("CREDIT_CARD_PAYMENT", "PAYMENT"),
            "cash-1",
            AccountKind::Cash,
        )
        .unwrap();
        let card = normalize(
            &activity("CREDIT_CARD", "PAYMENT"),
            "cash-1",
            AccountKind::CreditCard,
        )
        .unwrap();
        let (Disposition::Import(cash), Disposition::Import(card)) = (cash, card) else {
            panic!()
        };
        assert_eq!(cash.payee_name, "Wealthsimple Credit Card");
        assert_eq!(card.payee_name, "Wealthsimple Cash");
    }
}
