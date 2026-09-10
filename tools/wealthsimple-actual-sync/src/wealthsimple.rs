use std::collections::HashSet;

use anyhow::{Context, Result, bail};
use chrono::{DateTime, Duration, Utc};
use regex::Regex;
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use thiserror::Error;
use uuid::Uuid;

use crate::{
    amount,
    model::{self, AccountKind, Activity, ActualTransaction, Disposition},
    transport,
};

const LOGIN_URL: &str = "https://my.wealthsimple.com/app/login";
const OAUTH_URL: &str = "https://api.production.wealthsimple.com/v1/oauth/v2";
const GRAPHQL_URL: &str = "https://my.wealthsimple.com/graphql";
const READ_ONLY_SCOPE: &str = "invest.read trade.read tax.read";

const ACCOUNTS_QUERY: &str = r#"query FetchImportAccounts($identityId: ID!, $first: Int!, $cursor: String) {
  identity(id: $identityId) { accounts(filter: {}, first: $first, after: $cursor) {
    edges { node { id unifiedAccountType currency status nickname } }
    pageInfo { hasNextPage endCursor }
  }}
}"#;

const ACTIVITIES_QUERY: &str = r#"query FetchActivityFeedItems($first: Int, $cursor: Cursor, $condition: ActivityCondition, $orderBy: [ActivitiesOrderBy!] = OCCURRED_AT_DESC, $accountScope: AccountScope = OWN) {
  activityFeedItems(first: $first, after: $cursor, condition: $condition, orderBy: $orderBy, accountScope: $accountScope) {
    edges { node { accountId aftOriginatorName amount amountSign canonicalId currency eTransferEmail eTransferName externalCanonicalId occurredAt spendMerchant billPayCompanyName billPayPayeeNickname opposingAccountId p2pHandle rewardProgram status subType type } }
    pageInfo { hasNextPage endCursor }
  }
}"#;

const BALANCE_QUERY: &str = r#"query FetchAccountsWithBalance($ids: [String!]!, $type: BalanceType!) {
  accounts(ids: $ids) { id custodianAccounts { id financials { ... on CustodianAccountFinancialsSo { balance(type: $type) { quantity securityId } } } } }
}"#;

const CREDIT_CARD_BALANCE_QUERY: &str = r#"query FetchCreditCardAccount($id: ID!) {
  creditCardAccount(id: $id) { id balance { current outstanding pending } }
}"#;

#[derive(Debug, Error)]
pub enum Error {
    #[error("manual reauthentication required: {0}")]
    ManualAuthentication(String),
    #[error("Wealthsimple requires a TOTP code")]
    OtpRequired,
    #[error("Wealthsimple login failed: {0}")]
    Login(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Session {
    pub client_id: String,
    pub access_token: String,
    pub refresh_token: String,
    pub session_id: String,
    pub wssdi: String,
}

pub struct Ledger {
    pub since: DateTime<Utc>,
    pub transactions: Vec<ActualTransaction>,
}

pub struct ImportAccount {
    pub id: String,
    pub label: String,
    pub kind: AccountKind,
}

pub struct Wealthsimple {
    session: Session,
}

impl Wealthsimple {
    pub fn bootstrap() -> Result<Self> {
        let login = transport::request("GET", LOGIN_URL, &[], None)?;
        if !(200..300).contains(&login.status) {
            bail!(
                "Wealthsimple login bootstrap failed with HTTP {}",
                login.status
            );
        }
        let headers = login.headers.to_ascii_lowercase();
        let wssdi = Regex::new(r"wssdi=([a-z0-9-]+);")?
            .captures(&headers)
            .and_then(|capture| capture.get(1))
            .map(|value| value.as_str().to_owned())
            .context("Wealthsimple login page did not set a device ID")?;
        let html =
            String::from_utf8(login.body).context("Wealthsimple login page was not UTF-8")?;
        let script = Regex::new(r#"<script[^>]+src="([^"]+/app-[a-f0-9]+\.js)""#)?
            .captures(&html)
            .and_then(|capture| capture.get(1))
            .map(|value| value.as_str().to_owned())
            .context("Wealthsimple login page did not identify its application bundle")?;
        let script_response = transport::request("GET", &script, &[], None)?;
        if !(200..300).contains(&script_response.status) {
            bail!(
                "Wealthsimple application bundle failed with HTTP {}",
                script_response.status
            );
        }
        let javascript = String::from_utf8(script_response.body)
            .context("Wealthsimple application bundle was not UTF-8")?;
        let client_id = Regex::new(r#""production"[^}]*clientId:"([a-f0-9]+)""#)?
            .captures(&javascript)
            .and_then(|capture| capture.get(1))
            .map(|value| value.as_str().to_owned())
            .context("Wealthsimple application bundle did not contain an OAuth client ID")?;
        Ok(Self {
            session: Session {
                client_id,
                access_token: String::new(),
                refresh_token: String::new(),
                session_id: Uuid::new_v4().to_string(),
                wssdi,
            },
        })
    }

    pub fn from_session(session: Session) -> Result<Self> {
        if session.client_id.is_empty()
            || session.refresh_token.is_empty()
            || session.session_id.is_empty()
            || session.wssdi.is_empty()
        {
            return Err(Error::ManualAuthentication(
                "stored OAuth session is incomplete".to_owned(),
            )
            .into());
        }
        Ok(Self { session })
    }

    pub fn session(&self) -> &Session {
        &self.session
    }

    fn oauth_headers(&self, profile: &str) -> Vec<(&str, String)> {
        vec![
            (
                "x-wealthsimple-client",
                "@wealthsimple/wealthsimple".to_owned(),
            ),
            ("x-ws-profile", profile.to_owned()),
            ("x-ws-device-id", self.session.wssdi.clone()),
            ("x-ws-session-id", self.session.session_id.clone()),
        ]
    }

    pub fn login(
        &mut self,
        email: &str,
        password: &str,
        otp: Option<&str>,
    ) -> std::result::Result<Session, Error> {
        let mut headers = self.oauth_headers("undefined");
        if let Some(otp) = otp {
            headers.push(("x-wealthsimple-otp", format!("{otp};remember=true")));
        }
        let body = json!({ "grant_type": "password", "username": email, "password": password, "skip_provision": "true", "scope": READ_ONLY_SCOPE, "client_id": self.session.client_id, "otp_claim": null });
        let response =
            transport::request("POST", &format!("{OAUTH_URL}/token"), &headers, Some(&body))
                .map_err(|error| Error::Login(error.to_string()))?;
        let value: Value = serde_json::from_slice(&response.body)
            .map_err(|error| Error::Login(error.to_string()))?;
        update_from_login(&mut self.session, &value, otp.is_some())?;
        Ok(self.session.clone())
    }

    pub fn refresh(&mut self) -> Result<()> {
        let body = json!({ "grant_type": "refresh_token", "refresh_token": self.session.refresh_token, "client_id": self.session.client_id });
        let response = transport::request(
            "POST",
            &format!("{OAUTH_URL}/token"),
            &self.oauth_headers("invest"),
            Some(&body),
        )?;
        let value: Value = serde_json::from_slice(&response.body)
            .context("Wealthsimple OAuth refresh response was invalid JSON")?;
        if !(200..300).contains(&response.status)
            && value.get("error").and_then(Value::as_str) != Some("invalid_grant")
        {
            bail!(
                "Wealthsimple OAuth refresh failed with HTTP {}",
                response.status
            );
        }
        update_from_refresh(&mut self.session, &value)?;
        Ok(())
    }

    fn graphql(&self, operation: &str, query: &str, variables: Value) -> Result<Value> {
        let mut headers = self.oauth_headers("trade");
        headers.extend([
            (
                "Authorization",
                format!("Bearer {}", self.session.access_token),
            ),
            ("x-ws-api-version", "12".to_owned()),
            ("x-ws-locale", "en-CA".to_owned()),
            ("x-platform-os", "web".to_owned()),
        ]);
        let body = json!({ "operationName": operation, "query": query, "variables": variables });
        let response = transport::request("POST", GRAPHQL_URL, &headers, Some(&body))?;
        if !(200..300).contains(&response.status) {
            bail!(
                "Wealthsimple GraphQL operation {operation} failed with HTTP {}",
                response.status
            );
        }
        let value: Value = serde_json::from_slice(&response.body)
            .context("Wealthsimple GraphQL response was invalid JSON")?;
        validate_graphql(&value, operation)?;
        Ok(value)
    }

    fn identity_id(&self) -> Result<String> {
        let mut headers = self.oauth_headers("invest");
        headers.push((
            "Authorization",
            format!("Bearer {}", self.session.access_token),
        ));
        headers.push((
            "x-wealthsimple-client",
            "@wealthsimple/wealthsimple".to_owned(),
        ));
        let response =
            transport::request("GET", &format!("{OAUTH_URL}/token/info"), &headers, None)?;
        if !(200..300).contains(&response.status) {
            bail!(
                "Wealthsimple token info failed with HTTP {}",
                response.status
            );
        }
        let value: Value = serde_json::from_slice(&response.body)?;
        value
            .get("identity_canonical_id")
            .and_then(Value::as_str)
            .map(str::to_owned)
            .context("Wealthsimple token info omitted identity_canonical_id")
    }

    pub fn import_accounts(&self) -> Result<Vec<ImportAccount>> {
        let mut cursor: Option<String> = None;
        let mut accounts = Vec::new();
        let identity_id = self.identity_id()?;
        loop {
            let response = self.graphql(
                "FetchImportAccounts",
                ACCOUNTS_QUERY,
                json!({ "identityId": identity_id, "first": 25, "cursor": cursor }),
            )?;
            let connection = &response["data"]["identity"]["accounts"];
            for edge in connection["edges"]
                .as_array()
                .context("account edges were not an array")?
            {
                let account = &edge["node"];
                if let Some(account) = parse_import_account(account)? {
                    accounts.push(account);
                }
            }
            let Some(next) = next_cursor(connection, cursor.as_deref(), "account")? else {
                break;
            };
            cursor = Some(next);
        }
        Ok(accounts)
    }

    pub fn verify_account(&self, expected: &str, kind: AccountKind) -> Result<()> {
        if self
            .import_accounts()?
            .iter()
            .any(|account| account.id == expected && account.kind == kind)
        {
            Ok(())
        } else {
            bail!(
                "configured Wealthsimple account ID does not match an open CAD {:?} account",
                kind
            )
        }
    }

    pub fn fetch_ledger(
        &self,
        account_id: &str,
        account_kind: AccountKind,
        days: i64,
    ) -> Result<Ledger> {
        let since = Utc::now()
            .checked_sub_signed(Duration::days(days))
            .context("invalid ledger window")?;
        let mut cursor: Option<String> = None;
        let mut transactions = Vec::new();
        let mut ids = HashSet::new();
        loop {
            let response = self.graphql("FetchActivityFeedItems", ACTIVITIES_QUERY, json!({ "first": 100, "cursor": cursor, "condition": { "startDate": since.format("%Y-%m-%d").to_string(), "endDate": Utc::now().format("%Y-%m-%d").to_string(), "accountIds": [account_id] }, "orderBy": "OCCURRED_AT_ASC", "accountScope": "OWN" }))?;
            let connection = &response["data"]["activityFeedItems"];
            let edges = connection["edges"]
                .as_array()
                .context("activity edges were not an array")?;
            for edge in edges {
                let activity: Activity = serde_json::from_value(
                    edge.get("node")
                        .cloned()
                        .context("activity edge omitted node")?,
                )
                .context("activity did not match the required schema")?;
                match model::normalize(&activity, account_id, account_kind)? {
                    Disposition::Import(tx) => {
                        if !ids.insert(tx.imported_id.clone()) {
                            bail!(
                                "Wealthsimple returned duplicate canonical ID {}",
                                tx.imported_id
                            );
                        }
                        transactions.push(tx);
                    }
                    Disposition::OmitPending | Disposition::OmitTerminal => {}
                }
            }
            let Some(next) = next_cursor(connection, cursor.as_deref(), "activity")? else {
                break;
            };
            cursor = Some(next);
        }
        transactions.sort_by(|a, b| (&a.date, &a.imported_id).cmp(&(&b.date, &b.imported_id)));
        Ok(Ledger {
            since,
            transactions,
        })
    }

    pub fn fetch_cad_balance(&self, account_id: &str) -> Result<i64> {
        let response = self.graphql(
            "FetchAccountsWithBalance",
            BALANCE_QUERY,
            json!({ "ids": [account_id], "type": "TRADING" }),
        )?;
        let accounts = response["data"]["accounts"]
            .as_array()
            .context("balance accounts were not an array")?;
        if accounts.len() != 1 {
            bail!("balance response did not contain exactly one account");
        }
        let mut found = None;
        for custodian in accounts[0]["custodianAccounts"]
            .as_array()
            .context("custodian accounts were not an array")?
        {
            for balance in custodian["financials"]["balance"]
                .as_array()
                .context("balances were not an array")?
            {
                if balance["securityId"].as_str() == Some("sec-c-cad") {
                    if found.is_some() {
                        bail!("balance response contained multiple CAD cash balances");
                    }
                    let value = match &balance["quantity"] {
                        Value::String(value) => value.clone(),
                        Value::Number(value) => value.to_string(),
                        _ => bail!("CAD balance quantity was not numeric"),
                    };
                    found = Some(amount::decimal_to_cents(&value)?);
                }
            }
        }
        found.context("balance response omitted the CAD cash balance")
    }

    pub fn fetch_credit_card_balance(&self, account_id: &str) -> Result<i64> {
        let response = self.graphql(
            "FetchCreditCardAccount",
            CREDIT_CARD_BALANCE_QUERY,
            json!({ "id": account_id }),
        )?;
        let account = &response["data"]["creditCardAccount"];
        if account["id"].as_str() != Some(account_id) {
            bail!("credit card balance response contained the wrong account ID");
        }
        let value = match &account["balance"]["current"] {
            Value::String(value) => value.clone(),
            Value::Number(value) => value.to_string(),
            _ => bail!("credit card current balance was not numeric"),
        };
        amount::decimal_to_cents(&value).context("credit card current balance was invalid")
    }
}

fn parse_import_account(account: &Value) -> Result<Option<ImportAccount>> {
    let Some(id) = account["id"].as_str() else {
        return Ok(None);
    };
    let unified_type = account["unifiedAccountType"].as_str().unwrap_or("");
    let kind = if unified_type == "CASH" {
        Some(AccountKind::Cash)
    } else if unified_type == "CREDIT_CARD" || id.contains("credit-card") {
        Some(AccountKind::CreditCard)
    } else {
        None
    };
    let Some(kind) = kind else { return Ok(None) };
    if account["currency"].as_str() != Some("CAD") {
        bail!("eligible Wealthsimple account {id} is not denominated in CAD");
    }
    if account["status"].as_str() != Some("open") {
        bail!("eligible Wealthsimple account {id} is not open");
    }
    let label = account["nickname"]
        .as_str()
        .unwrap_or(match kind {
            AccountKind::Cash => "Cash",
            AccountKind::CreditCard => "Credit Card",
        })
        .to_owned();
    Ok(Some(ImportAccount {
        id: id.to_owned(),
        label,
        kind,
    }))
}

fn update_from_login(
    session: &mut Session,
    value: &Value,
    otp_provided: bool,
) -> std::result::Result<(), Error> {
    if value.get("error").and_then(Value::as_str) == Some("invalid_grant") && !otp_provided {
        return Err(Error::OtpRequired);
    }
    if let Some(error) = value.get("error").and_then(Value::as_str) {
        return Err(Error::Login(error.to_owned()));
    }
    session.access_token = value
        .get("access_token")
        .and_then(Value::as_str)
        .ok_or_else(|| Error::Login("response omitted access_token".to_owned()))?
        .to_owned();
    session.refresh_token = value
        .get("refresh_token")
        .and_then(Value::as_str)
        .ok_or_else(|| Error::Login("response omitted refresh_token".to_owned()))?
        .to_owned();
    Ok(())
}

fn update_from_refresh(session: &mut Session, value: &Value) -> std::result::Result<(), Error> {
    let access = value
        .get("access_token")
        .and_then(Value::as_str)
        .ok_or_else(|| {
            Error::ManualAuthentication(
                value
                    .get("error")
                    .and_then(Value::as_str)
                    .unwrap_or("refresh response omitted access_token")
                    .to_owned(),
            )
        })?;
    let refresh = value
        .get("refresh_token")
        .and_then(Value::as_str)
        .ok_or_else(|| {
            Error::ManualAuthentication(
                "refresh response omitted rotating refresh_token".to_owned(),
            )
        })?;
    session.access_token = access.to_owned();
    session.refresh_token = refresh.to_owned();
    Ok(())
}

fn validate_graphql(value: &Value, operation: &str) -> Result<()> {
    if value.get("errors").is_some() || value.get("data").is_none() {
        bail!("Wealthsimple GraphQL operation {operation} failed: response contained errors");
    }
    Ok(())
}

fn next_cursor(connection: &Value, current: Option<&str>, label: &str) -> Result<Option<String>> {
    let page_info = connection
        .get("pageInfo")
        .context("response omitted pageInfo")?;
    let has_next = page_info
        .get("hasNextPage")
        .and_then(Value::as_bool)
        .context("pageInfo omitted boolean hasNextPage")?;
    if !has_next {
        return Ok(None);
    }
    let next = page_info
        .get("endCursor")
        .and_then(Value::as_str)
        .filter(|cursor| !cursor.is_empty())
        .with_context(|| format!("{label} page omitted endCursor"))?;
    if current == Some(next) {
        bail!("Wealthsimple {label} pagination cursor did not advance");
    }
    Ok(Some(next.to_owned()))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn session() -> Session {
        Session {
            client_id: "client".to_owned(),
            access_token: "old-access".to_owned(),
            refresh_token: "old-refresh".to_owned(),
            session_id: "session".to_owned(),
            wssdi: "device".to_owned(),
        }
    }

    #[test]
    fn login_reports_totp_challenge() {
        let mut session = session();
        assert!(matches!(
            update_from_login(&mut session, &json!({ "error": "invalid_grant" }), false),
            Err(Error::OtpRequired)
        ));
    }

    #[test]
    fn refresh_rotates_both_tokens_or_changes_nothing() {
        let mut good = session();
        update_from_refresh(
            &mut good,
            &json!({ "access_token": "new-access", "refresh_token": "new-refresh" }),
        )
        .unwrap();
        assert_eq!(good.access_token, "new-access");
        assert_eq!(good.refresh_token, "new-refresh");

        let mut expired = session();
        assert!(matches!(
            update_from_refresh(&mut expired, &json!({ "error": "invalid_grant" })),
            Err(Error::ManualAuthentication(_))
        ));
        assert_eq!(expired.access_token, "old-access");
        assert_eq!(expired.refresh_token, "old-refresh");
    }

    #[test]
    fn graphql_errors_and_broken_pagination_fail_closed() {
        assert!(validate_graphql(&json!({ "errors": [{ "message": "bad" }] }), "Test").is_err());
        assert_eq!(
            next_cursor(
                &json!({ "pageInfo": { "hasNextPage": true, "endCursor": "page-2" } }),
                Some("page-1"),
                "activity"
            )
            .unwrap(),
            Some("page-2".to_owned())
        );
        assert!(
            next_cursor(
                &json!({ "pageInfo": { "hasNextPage": true, "endCursor": "same" } }),
                Some("same"),
                "activity"
            )
            .is_err()
        );
        assert!(next_cursor(&json!({ "pageInfo": {} }), None, "activity").is_err());
    }

    #[test]
    fn discovers_cash_and_credit_card_accounts_and_rejects_wrong_currency() {
        let cash = parse_import_account(&json!({
            "id": "ca-cash-1", "unifiedAccountType": "CASH", "currency": "CAD",
            "status": "open", "nickname": "Spending"
        }))
        .unwrap()
        .unwrap();
        assert_eq!(cash.kind, AccountKind::Cash);

        let card = parse_import_account(&json!({
            "id": "credit-card-1", "unifiedAccountType": "CREDIT_CARD",
            "currency": "CAD", "status": "open", "nickname": "Visa"
        }))
        .unwrap()
        .unwrap();
        assert_eq!(card.kind, AccountKind::CreditCard);
        assert_eq!(card.label, "Visa");

        assert!(
            parse_import_account(&json!({
                "id": "credit-card-usd", "unifiedAccountType": "CREDIT_CARD",
                "currency": "USD", "status": "open"
            }))
            .is_err()
        );
    }
}
