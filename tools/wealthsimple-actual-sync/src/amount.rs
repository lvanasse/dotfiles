use thiserror::Error;

#[derive(Debug, Error, PartialEq)]
pub enum Error {
    #[error("amount is empty")]
    Empty,
    #[error("amount is not a plain decimal: {0}")]
    Invalid(String),
    #[error("amount has more than two decimal places: {0}")]
    Precision(String),
    #[error("amount is outside the supported cent range: {0}")]
    Overflow(String),
}

pub fn decimal_to_cents(input: &str) -> Result<i64, Error> {
    let input = input.trim();
    if input.is_empty() {
        return Err(Error::Empty);
    }
    let (negative, digits) = match input.as_bytes()[0] {
        b'-' => (true, &input[1..]),
        b'+' => (false, &input[1..]),
        _ => (false, input),
    };
    let mut parts = digits.split('.');
    let whole = parts.next().unwrap_or_default();
    let fraction = parts.next();
    if parts.next().is_some()
        || whole.is_empty()
        || !whole.bytes().all(|byte| byte.is_ascii_digit())
        || fraction.is_some_and(|part| !part.bytes().all(|byte| byte.is_ascii_digit()))
    {
        return Err(Error::Invalid(input.to_owned()));
    }
    let fraction = fraction.unwrap_or("");
    if fraction.len() > 2 {
        return Err(Error::Precision(input.to_owned()));
    }
    let whole: i64 = whole
        .parse()
        .map_err(|_| Error::Overflow(input.to_owned()))?;
    let fractional: i64 = match fraction.len() {
        0 => 0,
        1 => fraction.parse::<i64>().unwrap() * 10,
        2 => fraction.parse().unwrap(),
        _ => unreachable!(),
    };
    let cents = whole
        .checked_mul(100)
        .and_then(|value| value.checked_add(fractional))
        .ok_or_else(|| Error::Overflow(input.to_owned()))?;
    if negative {
        cents
            .checked_neg()
            .ok_or_else(|| Error::Overflow(input.to_owned()))
    } else {
        Ok(cents)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_without_floating_point() {
        assert_eq!(decimal_to_cents("12.34"), Ok(1234));
        assert_eq!(decimal_to_cents("0.5"), Ok(50));
        assert_eq!(decimal_to_cents("-3"), Ok(-300));
        assert!(matches!(
            decimal_to_cents("1.001"),
            Err(Error::Precision(_))
        ));
        assert!(decimal_to_cents("NaN").is_err());
    }
}
