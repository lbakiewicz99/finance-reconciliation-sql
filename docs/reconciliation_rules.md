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

An exact match occurs when an internal transaction and an external transaction have the same key reconciliation attributes.

A transaction is considered fully matched when the following fields align:

* account,
* currency,
* transaction reference,
* transaction type,
* amount,
* settlement date or value date,
* transaction direction.

Example:

| Field     | Internal Record | External Record |
| --------- | --------------- | --------------- |
| Reference | TXN-1001        | TXN-1001        |
| Account   | ACC-GBP-001     | ACC-GBP-001     |
| Currency  | GBP             | GBP             |
| Amount    | 1250.00         | 1250.00         |
| Date      | 2025-01-15      | 2025-01-15      |
| Direction | IN              | IN              |

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

## Exception Priority

Not all reconciliation exceptions have the same operational risk.

Suggested priority:

| Priority      | Exception Type                 | Reason                                             |
| ------------- | ------------------------------ | -------------------------------------------------- |
| High          | External-only transaction      | Cash movement may not be booked internally         |
| High          | Amount mismatch                | Financial value differs between sources            |
| High          | Currency mismatch              | May affect reporting and cash balances             |
| Medium        | Internal-only transaction      | May be timing-related or missing externally        |
| Medium        | Duplicate internal transaction | May overstate activity                             |
| Medium        | Duplicate external transaction | May indicate file or provider issue                |
| Low / Medium  | Date mismatch                  | Often timing-related, but should still be reviewed |
| Medium / High | Aged open break                | Risk increases with age                            |

## Matching Hierarchy

The reconciliation process should apply matching logic in a structured order:

1. Identify exact matches.
2. Identify possible matches with amount mismatches.
3. Identify possible matches with date mismatches.
4. Identify possible matches with currency mismatches.
5. Identify unmatched internal records.
6. Identify unmatched external records.
7. Identify duplicates.
8. Classify aged unresolved breaks.
9. Summarize resolved vs unresolved exceptions.

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
