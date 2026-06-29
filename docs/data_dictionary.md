
# Data Dictionary

## Overview

This document describes the planned database tables and key fields used in the `finance-reconciliation-sql` project.

The database is designed to support a finance reconciliation process between internal transaction records and external bank, custodian or payment provider statement records.

The data model includes reference tables, transaction tables, reconciliation run tracking, reconciliation results, exception classification and manual adjustment records.

## Table: `funds`

Stores basic information about funds included in the reconciliation process.

| Column          | Data Type | Description                                    | Example               |
| --------------- | --------- | ---------------------------------------------- | --------------------- |
| `fund_id`       | integer   | Unique fund identifier.                        | `1`                   |
| `fund_code`     | varchar   | Short business code used to identify the fund. | `FND_GBL_EQ`          |
| `fund_name`     | varchar   | Full fund name.                                | `Global Equity Fund`  |
| `base_currency` | char(3)   | Base currency of the fund.                     | `USD`                 |
| `is_active`     | boolean   | Indicates whether the fund is active.          | `true`                |
| `created_at`    | timestamp | Record creation timestamp.                     | `2025-01-01 09:00:00` |

## Table: `accounts`

Stores cash, custody or operational accounts used in the reconciliation process.

| Column           | Data Type | Description                              | Example                          |
| ---------------- | --------- | ---------------------------------------- | -------------------------------- |
| `account_id`     | integer   | Unique account identifier.               | `1`                              |
| `fund_id`        | integer   | Related fund identifier.                 | `1`                              |
| `account_number` | varchar   | Internal or external account number.     | `ACC-USD-001`                    |
| `account_name`   | varchar   | Account name or business label.          | `Global Equity USD Cash Account` |
| `account_type`   | varchar   | Type of account.                         | `CASH`                           |
| `currency_code`  | char(3)   | Account currency.                        | `USD`                            |
| `is_active`      | boolean   | Indicates whether the account is active. | `true`                           |

Possible `account_type` values:

* `CASH`
* `CUSTODY`
* `SETTLEMENT`
* `PSP`
* `FEE`

## Table: `currencies`

Stores currency reference data.

| Column           | Data Type | Description                                                                         | Example |
| ---------------- | --------- | ----------------------------------------------------------------------------------- | ------- |
| `currency_code`  | char(3)   | ISO currency code.                                                                  | `EUR`   |
| `currency_name`  | varchar   | Full currency name.                                                                 | `Euro`  |
| `decimal_places` | integer   | Number of decimal places used for the currency.                                     | `2`     |
| `is_supported`   | boolean   | Indicates whether the currency is currently supported by the reconciliation process.| `true`  |

## Table: `internal_transactions`

Stores transactions from the internal fund accounting or finance operations system.

| Column                    | Data Type | Description                                                                                                 | Example               |
| ------------------------- | --------- | ----------------------------------------------------------------------------------------------------------- | --------------------- |
| `internal_transaction_id` | integer   | Unique internal transaction identifier.                                                                     | `1001`                |
| `fund_id`                 | integer   | Fund linked to the transaction.                                                                             | `1`                   |
| `account_id`              | integer   | Account linked to the transaction.                                                                          | `1`                   |
| `transaction_reference`   | varchar   | Raw internal transaction reference from the internal system.                                                | `TXN-2025-0001`       |
| `matching_reference`      | varchar   | Normalized reference used for reconciliation matching. Usually equal to the internal transaction reference. | `TXN-2025-0001`       |
| `transaction_type`        | varchar   | Business type of transaction.                                                                               | `SUBSCRIPTION`        |
| `direction`               | varchar   | Cash or transaction direction.                                                                              | `IN`                  |
| `currency_code`           | char(3)   | Transaction currency.                                                                                       | `USD`                 |
| `amount`                  | numeric   | Transaction amount.                                                                                         | `125000.00`           |
| `trade_date`              | date      | Trade date or transaction initiation date.                                                                  | `2025-01-14`          |
| `settlement_date`         | date      | Expected settlement date.                                                                                   | `2025-01-15`          |
| `booking_date`            | date      | Date when the transaction was booked internally.                                                            | `2025-01-15`          |
| `source_system`           | varchar   | Name of the internal source system.                                                                         | `Multifonds`          |
| `transaction_status`      | varchar   | Internal transaction status.                                                                                | `BOOKED`              |
| `created_at`              | timestamp | Record creation timestamp.                                                                                  | `2025-01-15 08:30:00` |


Possible `transaction_type` values:

* `SUBSCRIPTION`
* `REDEMPTION`
* `CASH_TRANSFER`
* `FEE`
* `INTEREST`
* `DIVIDEND`
* `CORPORATE_ACTION`
* `FX`
* `ADJUSTMENT`

Possible `direction` values:

* `IN`
* `OUT`

Possible `transaction_status` values:

* `BOOKED`
* `PENDING`
* `CANCELLED`
* `ADJUSTED`

## Table: `external_transactions`

Stores transactions received from an external statement source such as a bank, custodian or payment provider.

| Column                    | Data Type | Description                                                                                        | Example                     |
| ------------------------- | --------- | -------------------------------------------------------------------------------------------------- | --------------------------- |
| `external_transaction_id` | integer   | Unique external transaction identifier.                                                            | `5001`                      |
| `account_id`              | integer   | Account linked to the external statement line.                                                     | `1`                         |
| `external_reference`      | varchar   | Raw external transaction reference from the statement source.                                      | `PSP-CAPTURE-TXN-2025-0004` |
| `matching_reference`      | varchar   | Normalized or extracted reference used to match the external record against internal transactions. | `TXN-2025-0004`             |
| `statement_reference`     | varchar   | Statement or file reference.                                                                       | `BNK-STMT-20250115-001`     |
| `transaction_type`        | varchar   | External transaction type or mapped transaction category.                                          | `SUBSCRIPTION`              |
| `direction`               | varchar   | Cash or transaction direction.                                                                     | `IN`                        |
| `currency_code`           | char(3)   | Transaction currency.                                                                              | `USD`                       |
| `amount`                  | numeric   | Transaction amount from the external source.                                                       | `125000.00`                 |
| `value_date`              | date      | External value date.                                                                               | `2025-01-15`                |
| `booking_date`            | date      | External booking date.                                                                             | `2025-01-15`                |
| `counterparty`            | varchar   | Counterparty or payer/payee information.                                                           | `Investor A`                |
| `statement_source`        | varchar   | Source of the external statement.                                                                  | `Bank`                      |
| `created_at`              | timestamp | Record creation timestamp.                                                                         | `2025-01-15 09:00:00`       |


Possible `statement_source` values:

* `Bank`
* `Custodian`
* `PSP`
* `Broker`
* `Transfer Agent`

## Reference Matching Logic

The project separates raw source references from normalized matching references.

Raw references are stored exactly as they appear in the source systems:

* `internal_transactions.transaction_reference`
* `external_transactions.external_reference`

Matching references are normalized values used by the reconciliation process:

* `internal_transactions.matching_reference`
* `external_transactions.matching_reference`

This reflects a common reconciliation scenario where external providers may add prefixes, suffixes or provider-specific formatting to transaction references.

Example:

| Source                 | Raw Reference               | Matching Reference |
| ---------------------- | --------------------------- | ------------------ |
| Internal system        | `TXN-2025-0004`             | `TXN-2025-0004`    |
| External PSP statement | `PSP-CAPTURE-TXN-2025-0004` | `TXN-2025-0004`    |

In this case, the raw references differ, but the normalized matching references align. Therefore, the transaction can still be reconciled.

A reference mismatch occurs only when the normalized matching references differ while other transaction attributes suggest that the records may refer to the same business event.


## Table: `reconciliation_runs`

Stores metadata about each reconciliation run.

| Column                  | Data Type | Description                                 | Example               |
| ----------------------- | --------- | ------------------------------------------- | --------------------- |
| `reconciliation_run_id` | integer   | Unique reconciliation run identifier.       | `1`                   |
| `run_date`              | date      | Date when the reconciliation was performed. | `2025-01-16`          |
| `period_start_date`     | date      | Start date of the reconciled period.        | `2025-01-01`          |
| `period_end_date`       | date      | End date of the reconciled period.          | `2025-01-31`          |
| `run_status`            | varchar   | Status of the reconciliation run.           | `COMPLETED`           |
| `created_by`            | varchar   | User or process that created the run.       | `analyst_user`        |
| `created_at`            | timestamp | Record creation timestamp.                  | `2025-01-16 10:00:00` |

Possible `run_status` values:

* `STARTED`
* `COMPLETED`
* `FAILED`
* `REVIEWED`

## Table: `exception_types`

Stores standard reconciliation exception categories.

| Column                  | Data Type | Description                            | Example                                 |
| ----------------------- | --------- | -------------------------------------- | --------------------------------------- |
| `exception_type_id`     | integer   | Unique exception type identifier.      | `1`                                     |
| `exception_code`        | varchar   | Short exception code.                  | `AMOUNT_MISMATCH`                       |
| `exception_name`        | varchar   | Business-friendly exception name.      | `Amount mismatch`                       |
| `exception_description` | text      | Description of the exception type.     | `Internal and external amounts differ.` |
| `exception_priority`    | varchar   | Operational priority of the exception. | `High`                                  |

Planned exception codes:

* `MATCHED`
* `UNMATCHED_INTERNAL`
* `UNMATCHED_EXTERNAL`
* `AMOUNT_MISMATCH`
* `DATE_MISMATCH`
* `CURRENCY_MISMATCH`
* `DUPLICATE_INTERNAL`
* `DUPLICATE_EXTERNAL`
* `AGED_OPEN_BREAK`
* `REFERENCE_MISMATCH`

## Table: `reconciliation_results`

Stores reconciliation outcomes for matched transactions and exceptions.

| Column                     | Data Type | Description                                             | Example                              |
| -------------------------- | --------- | ------------------------------------------------------- | ------------------------------------ |
| `reconciliation_result_id` | integer   | Unique reconciliation result identifier.                | `1`                                  |
| `reconciliation_run_id`    | integer   | Related reconciliation run.                             | `1`                                  |
| `internal_transaction_id`  | integer   | Related internal transaction, if applicable.            | `1001`                               |
| `external_transaction_id`  | integer   | Related external transaction, if applicable.            | `5001`                               |
| `exception_type_id`        | integer   | Related exception type.                                 | `1`                                  |
| `match_status`             | varchar   | Reconciliation match status.                            | `MATCHED`                            |
| `break_status`             | varchar   | Break resolution status.                                | `RESOLVED`                           |
| `break_open_date`          | date      | Date when the break was first identified.               | `2025-01-16`                         |
| `break_resolved_date`      | date      | Date when the break was resolved.                       | `2025-01-18`                         |
| `amount_difference`        | numeric   | Difference between internal and external amount.        | `5.00`                               |
| `date_difference_days`     | integer   | Difference between internal and external dates in days. | `1`                                  |
| `notes`                    | text      | Analyst or system notes.                                | `External amount includes bank fee.` |
| `created_at`               | timestamp | Record creation timestamp.                              | `2025-01-16 10:15:00`                |

Possible `match_status` values:

* `MATCHED`
* `UNMATCHED`
* `MISMATCH`
* `DUPLICATE`

Possible `break_status` values:

* `NOT_APPLICABLE`
* `OPEN`
* `RESOLVED`
* `CLOSED_AS_TIMING`
* `CLOSED_AS_VALID`
* `ESCALATED`

## Table: `manual_adjustments`

Stores manual actions taken to resolve reconciliation breaks.

| Column                     | Data Type | Description                                      | Example                               |
| -------------------------- | --------- | ------------------------------------------------ | ------------------------------------- |
| `manual_adjustment_id`     | integer   | Unique manual adjustment identifier.             | `1`                                   |
| `reconciliation_result_id` | integer   | Related reconciliation result.                   | `10`                                  |
| `adjustment_date`          | date      | Date when the adjustment was made.               | `2025-01-18`                          |
| `adjustment_type`          | varchar   | Type of manual adjustment.                       | `INTERNAL_BOOKING_CORRECTION`         |
| `adjustment_amount`        | numeric   | Amount related to the adjustment, if applicable. | `5.00`                                |
| `adjustment_reason`        | text      | Business reason for the adjustment.              | `Bank fee was not booked internally.` |
| `adjusted_by`              | varchar   | User who performed or recorded the adjustment.   | `operations_analyst`                  |
| `created_at`               | timestamp | Record creation timestamp.                       | `2025-01-18 14:30:00`                 |

Possible `adjustment_type` values:

* `INTERNAL_BOOKING_CORRECTION`
* `EXTERNAL_REFERENCE_UPDATE`
* `DATE_CORRECTION`
* `AMOUNT_CORRECTION`
* `MANUAL_MATCH`
* `TIMING_DIFFERENCE_CONFIRMED`
* `WRITE_OFF`
* `OTHER`

## Key Relationships

The planned relationships between tables are:

| Parent Table             | Child Table              | Relationship                                                       |
| ------------------------ | ------------------------ | ------------------------------------------------------------------ |
| `funds`                  | `accounts`               | One fund can have many accounts.                                   |
| `funds`                  | `internal_transactions`  | One fund can have many internal transactions.                      |
| `accounts`               | `internal_transactions`  | One account can have many internal transactions.                   |
| `accounts`               | `external_transactions`  | One account can have many external transactions.                   |
| `currencies`             | `funds`                  | One currency can be the base currency for many funds.              |
| `currencies`             | `accounts`               | One currency can be used by many accounts.                         |
| `currencies`             | `internal_transactions`  | One currency can be used by many internal transactions.            |
| `currencies`             | `external_transactions`  | One currency can be used by many external transactions.            |
| `reconciliation_runs`    | `reconciliation_results` | One reconciliation run can produce many reconciliation results.    |
| `exception_types`        | `reconciliation_results` | One exception type can be assigned to many reconciliation results. |
| `reconciliation_results` | `manual_adjustments`     | One reconciliation result can have many manual adjustments.        |

## Business Notes

The database model is intentionally simplified, but it reflects common finance operations concepts:

* funds and accounts provide business context,
* internal transactions represent system-booked activity,
* external transactions represent third-party statement data,
* reconciliation runs track processing cycles,
* reconciliation results store match and exception outcomes,
* exception types standardize break classification,
* manual adjustments document operational resolution actions.

The model is designed to support both transaction-level investigation and summary reporting.
