# Reconciliation Rules

## Overview

This document defines the reconciliation logic used in the `finance-reconciliation-sql` project.

The goal of the reconciliation process is to compare internal transaction records from a fund accounting or finance operations system against external transaction records received from a bank, custodian or payment service provider.

Each reconciliation run attempts to identify:

* fully matched transactions,
* internal-only transactions,
* external-only transactions,
* amount mismatches,
* date mismatches,
* duplicate records,
* aged open breaks,
* resolved and unresolved exceptions.

## Matching Approach

The reconciliation logic is based on comparing key transaction attributes between the internal and external data sources.

The main matching fields are:

* fund,
* account,
* currency,
* transaction reference,
* transaction type,
* amount,
* settlement date or value date,
* transaction direction.

Not every exception means that a transaction is incorrect. Some differences may be caused by timing delays, external file cut-off times, manual bookings, reference formatting differences or operational adjustments.

## Reconciliation Rule Types

### 1. Exact Match

A transaction is considered an exact match when the internal and external records align across the core reconciliation fields.

Required matching fields:

- account,
- normalized matching reference,
- transaction type,
- direction,
- currency,
- amount,
- settlement date / value date.

Raw references do not have to be identical if the normalized matching references are the same.

Example:

| Field              | Internal        | External                    |
|--------------------|-----------------|-----------------------------|
| Raw reference      | `TXN-2025-0004` | `PSP-CAPTURE-TXN-2025-0004` |
| Matching reference | `TXN-2025-0004` | `TXN-2025-0004`             |
| Amount             | `10000.00`      | `10000.00`                  |
| Currency           | `USD`           | `USD`                       | 
 
This can be treated as a matched transaction because the matching references align.

Expected result:

```text
MATCHED
```

### 2. Internal-Only Transaction

An internal-only transaction exists in the internal system but does not have a matching external record.

This may indicate that:

* the transaction has not settled yet,
* the external statement file is incomplete,
* the transaction was booked internally too early,
* the external reference is missing or different,
* the transaction was incorrectly booked.

Expected result:

```text
UNMATCHED_INTERNAL
```

### 3. External-Only Transaction

An external-only transaction exists in the external statement but does not have a matching internal record.

This may indicate that:

* the transaction has not been booked internally,
* the payment was received unexpectedly,
* the bank or custodian posted a fee or charge,
* the external statement contains a transaction that requires manual investigation,
* the internal system import process failed.

Expected result:

```text
UNMATCHED_EXTERNAL
```

### 4. Amount Mismatch

An amount mismatch occurs when the internal and external records appear to refer to the same transaction, but the amounts are different.

The transaction may match on:

* reference,
* account,
* currency,
* transaction type,
* direction,

but fail on amount.

Example:

| Field           | Internal Record | External Record |
| --------------- | --------------- | --------------- |
| Reference       | TXN-1002        | TXN-1002        |
| Currency        | EUR             | EUR             |
| Internal Amount | 1000.00         |                 |
| External Amount |                 | 995.00          |

Expected result:

```text
AMOUNT_MISMATCH
```

Possible business causes:

* bank fees,
* FX rounding,
* incorrect manual booking,
* partial settlement,
* incorrect source data,
* adjustment not posted internally.

### 5. Date Mismatch

A date mismatch occurs when the internal and external records match on reference, account, currency, transaction type, direction and amount, but the settlement date or value date is different.

Example:

| Field                    | Internal Record | External Record |
| ------------------------ | --------------- | --------------- |
| Reference                | TXN-1003        | TXN-1003        |
| Amount                   | 2500.00         | 2500.00         |
| Internal Settlement Date | 2025-01-20      |                 |
| External Value Date      |                 | 2025-01-21      |

Expected result:

```text
DATE_MISMATCH
```

Possible business causes:

* settlement delay,
* bank holiday,
* cut-off timing,
* timezone difference,
* incorrect value date on statement,
* incorrect internal booking date.

### 6. Currency Mismatch

A currency mismatch occurs when the transaction appears to be the same based on reference and account, but the internal and external currencies are different.

Expected result:

```text
CURRENCY_MISMATCH
```

This is usually a higher-risk exception because currency differences may affect reporting, cash balances and NAV-related processes.

### 7. Duplicate Internal Transaction

A duplicate internal transaction occurs when more than one internal record has the same key attributes.

Duplicate detection should check combinations such as:

* transaction reference,
* fund,
* account,
* currency,
* amount,
* settlement date,
* direction.

Expected result:

```text
DUPLICATE_INTERNAL
```

Possible business causes:

* duplicate manual booking,
* repeated file import,
* system processing error,
* incorrect transaction correction process.

### 8. Duplicate External Transaction

A duplicate external transaction occurs when more than one external record has the same key attributes.

Expected result:

```text
DUPLICATE_EXTERNAL
```

Possible business causes:

* duplicate statement line,
* repeated external file import,
* provider data issue,
* duplicate payment message.

### 9. Aged Open Break

An aged open break is an unresolved reconciliation exception that remains open after a defined number of days.

For this project, an exception is considered aged when it remains unresolved for more than 5 calendar days.

Expected result:

```text
AGED_OPEN_BREAK
```

Aged breaks are important because they may indicate:

* unresolved operational risk,
* delayed investigation,
* missing ownership,
* incomplete process controls,
* possible impact on reporting accuracy.

### 10. Resolved Exception

A reconciliation exception is considered resolved when it has been investigated and closed.

A break may be resolved by:

* receiving a missing external record,
* posting a missing internal booking,
* correcting an incorrect amount,
* updating the settlement date,
* confirming a valid timing difference,
* applying a manual adjustment.

Expected status:

```text
RESOLVED
```

### 11. Unresolved Exception

An unresolved exception is a break that remains open and requires further investigation.

Expected status:

```text
UNRESOLVED
```

Unresolved exceptions should be included in open breaks reporting.

### 12. Reference Mismatch

A reference mismatch occurs when an internal and external record appear to describe the same business transaction based on account, amount, currency, transaction type and date, but their normalized matching references do not match.

This exception is used when other attributes suggest a possible relationship between the records, but the reference logic does not support a clean match.

Example:

| Field              | Internal        | External        |
|--------------------|-----------------|-----------------|
| Account            | `ACC-USD-001`   | `ACC-USD-001`   |
| Amount             | `8000.00`       | `8000.00`       |
| Currency           | `USD`           | `USD`           |
| Date               | `2025-01-27`    | `2025-01-27`    |
| Matching reference | `TXN-2025-0010` | `TXN-2025-9999` |

This should be reviewed as a possible reference mismatch rather than automatically matched.

## Exception Priority

Not all reconciliation exceptions have the same operational risk.

Suggested priority:

| Priority      | Exception Type                 | Reason                                                       |
| ------------- | ------------------------------ | ------------------------------------------------------------ |
| High          | External-only transaction      | Cash movement may not be booked internally                   |
| High          | Amount mismatch                | Financial value differs between sources                      |
| High          | Currency mismatch              | May affect reporting and cash balances                       |
| Medium        | Internal-only transaction      | May be timing-related or missing externally                  |
| Medium        | Duplicate internal transaction | May overstate activity                                       |
| Medium        | Duplicate external transaction | May indicate file or provider issue                          |
| Low / Medium  | Date mismatch                  | Often timing-related, but should still be reviewed           |
| Medium / High | Aged open break                | Risk increases with age                                      |
| Medium        | REFERENCE_MISMATCH             | Possible same transaction, but normalized references differ. |


## Matching Hierarchy

The reconciliation logic should apply rules in the following order:

1. exact matches using normalized matching references,
2. amount mismatches,
3. date mismatches,
4. currency mismatches,
5. reference mismatches,
6. unmatched internal records,
7. unmatched external records,
8. duplicate internal records,
9. duplicate external records,
10. aged unresolved breaks,
11. resolved vs unresolved break summary.

This hierarchy helps avoid double-counting the same transaction across multiple exception categories.

## Reporting Outputs

The reconciliation rules will support the following reporting views:

* `vw_open_breaks`,
* `vw_monthly_reconciliation_summary`,
* `vw_aged_exceptions`,
* `vw_reconciliation_accuracy`.

These views will help summarize reconciliation quality, exception trends and operational risk.

## Business Relevance

The reconciliation rules in this project are designed to reflect common finance operations scenarios.

They demonstrate how SQL can be used to:

* validate transaction completeness,
* detect financial mismatches,
* support break investigation,
* monitor unresolved exceptions,
* provide audit-friendly reporting,
* improve operational control over financial data.

## Reference Handling

The reconciliation process distinguishes between raw source references and normalized matching references.

Raw references are stored as provided by each source:

- internal raw reference: `internal_transactions.transaction_reference`
- external raw reference: `external_transactions.external_reference`

Normalized matching references are used for reconciliation logic:

- internal matching reference: `internal_transactions.matching_reference`
- external matching reference: `external_transactions.matching_reference`

External statement providers may use different reference formats than the internal system. For example, a PSP or bank may add prefixes, suffixes or provider-specific identifiers.

Example:

| Source   | Raw Reference               | Matching Reference |
|----------|-----------------------------|--------------------|
| Internal | `TXN-2025-0004`             | `TXN-2025-0004`    |
| External | `PSP-CAPTURE-TXN-2025-0004` | `TXN-2025-0004`    |

This is treated as a valid normalized reference match, not a reference mismatch.