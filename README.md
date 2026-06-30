# Finance Reconciliation SQL Project

## Overview

`finance-reconciliation-sql` is a PostgreSQL portfolio project that simulates a real-world finance reconciliation process.

The project compares internal finance or fund accounting transaction records against external statement records received from banks, custodians or payment service providers.

It demonstrates how SQL can be used to:

* design a relational reconciliation data model,
* store internal and external transaction data,
* identify matched and unmatched records,
* classify reconciliation exceptions,
* detect duplicates,
* calculate reconciliation accuracy,
* monitor aged open breaks,
* validate data quality,
* produce operational reporting views.

## Business Context

Finance operations, fund accounting and reconciliation teams rely on daily controls to ensure that transactions recorded in internal systems match external records from third-party providers.

Common reconciliation issues include:

* internal transactions missing from external statements,
* external statement lines missing from internal systems,
* amount mismatches,
* settlement date or value date mismatches,
* currency mismatches,
* reference mismatches,
* duplicate records,
* aged unresolved breaks.

This project models those scenarios using PostgreSQL.

### Project scope

This project focuses on SQL-based reconciliation logic and business-facing reporting outputs for a simulated finance operations environment.

Included:

* relational data model for funds, accounts, internal transactions, external transactions, reconciliation runs, exception types, reconciliation results, and manual adjustments;
* sample data covering matched transactions, unmatched items, amount mismatches, currency mismatches, duplicate transactions, aged breaks, and reference mismatches;
* SQL reconciliation queries comparing internal finance records against external bank, custodian, or PSP statement data;
* reporting views for reconciliation detail, open breaks, aged exceptions, monthly summary, exception summary, and reconciliation accuracy;
* validation checks for data integrity and reconciliation result consistency;
* exported CSV examples for reviewer-friendly output inspection;
* lightweight Streamlit dashboard reading exported CSV files from `output_examples/`.

The Streamlit dashboard is intentionally lightweight and uses exported CSV outputs, keeping the core reconciliation logic transparent and reviewable in SQL.

Not included:

* production-grade ETL pipelines;
* real bank, custodian, PSP, or fund accounting system integrations;
* live database connection from the Streamlit dashboard;
* user authentication, authorization, or role-based access control;
* write-back workflows for resolving breaks from the UI;
* automated scheduling, orchestration, or alerting;
* cloud deployment or containerized production infrastructure;
* sensitive, personal, or real client transaction data.


## Technologies Used

* PostgreSQL
* SQL
* psql command-line client
* Git / GitHub
* Python
* Streamlit
* pandas

## Repository Structure

```text
finance-reconciliation-sql/
├── app/
│   └── streamlit_app.py
│
├── requirements.txt
│
├── README.md
│
├── docs/
│   ├── business_case.md
│   ├── data_dictionary.md
│   ├── reconciliation_rules.md
│   └── findings.md
│
├── sql/
│   ├── 01_create_schema.sql
│   ├── 02_create_tables.sql
│   ├── 03_insert_sample_data.sql
│   ├── 04_reconciliation_queries.sql
│   ├── 05_reporting_views.sql
│   └── 06_validation_checks.sql
│
├── sample_data/
├── output_examples/
└── images/
```

## Data Model

The main tables are:

| Table                    | Purpose                                                                  |
| ------------------------ | ------------------------------------------------------------------------ |
| `currencies`             | Stores supported currency reference data.                                |
| `funds`                  | Stores fund reference data.                                              |
| `accounts`               | Stores cash, custody, settlement and PSP accounts.                       |
| `internal_transactions`  | Stores transactions from the internal finance or fund accounting system. |
| `external_transactions`  | Stores transactions from external statements.                            |
| `reconciliation_runs`    | Stores reconciliation run metadata.                                      |
| `exception_types`        | Stores standardized reconciliation exception categories.                 |
| `reconciliation_results` | Stores transaction-level match and exception outcomes.                   |
| `manual_adjustments`     | Stores manual actions used to resolve breaks.                            |

## Reference Matching Logic

The project separates raw references from normalized matching references.

Raw references are stored as received from each source:

* `internal_transactions.transaction_reference`,
* `external_transactions.external_reference`.

Matching references are normalized values used for reconciliation:

* `internal_transactions.matching_reference`,
* `external_transactions.matching_reference`.

This reflects realistic scenarios where external sources may add prefixes, suffixes or provider-specific formatting.

Example:

| Source                 | Raw Reference               | Matching Reference |
| ---------------------- | --------------------------- | ------------------ |
| Internal system        | `TXN-2025-0004`             | `TXN-2025-0004`    |
| External PSP statement | `PSP-CAPTURE-TXN-2025-0004` | `TXN-2025-0004`    |

The raw references differ, but the normalized matching reference allows the transaction to be reconciled.

## Reconciliation Scenarios Covered

The sample data includes:

| Scenario           | Description                                                                        |
| ------------------ | ---------------------------------------------------------------------------------- |
| Exact match        | Internal and external records fully match.                                         |
| Unmatched internal | Internal transaction has no external match.                                        |
| Unmatched external | External transaction has no internal match.                                        |
| Amount mismatch    | Internal and external amounts differ.                                              |
| Date mismatch      | Internal settlement date differs from external value date.                         |
| Currency mismatch  | Internal and external currencies differ.                                           |
| Reference mismatch | Normalized references differ despite other attributes suggesting a possible match. |
| Duplicate internal | Duplicate transaction detected in internal records.                                |
| Duplicate external | Duplicate transaction detected in external records.                                |
| Aged open break    | Unresolved break older than the aging threshold.                                   |

## Reporting Views

The project creates the following reporting views:

| View                                | Purpose                                           |
| ----------------------------------- | ------------------------------------------------- |
| `vw_reconciliation_detail`          | Base transaction-level reconciliation dataset.    |
| `vw_open_breaks`                    | Open or escalated reconciliation breaks.          |
| `vw_aged_exceptions`                | Unresolved breaks older than the aging threshold. |
| `vw_monthly_reconciliation_summary` | Monthly reconciliation performance summary.       |
| `vw_exception_summary`              | Exception summary by exception type.              |
| `vw_reconciliation_accuracy`        | Reconciliation accuracy by run.                   |

## Validation Checks

The validation script includes checks for:

* blank matching references,
* unsupported currencies,
* fund and account mismatches,
* invalid reconciliation periods,
* missing manual adjustment reasons,
* missing break dates,
* inconsistent match statuses,
* incorrect amount difference calculations,
* incorrect date difference calculations,
* reference mismatch logic,
* duplicate groups,
* high-priority open breaks,
* aged exceptions.

Validation checks are split into:

1. data integrity checks,
2. reconciliation result logic checks,
3. operational control checks.

Data integrity and reconciliation result checks should normally return zero issues.

Operational controls may return values above zero because the sample data intentionally contains open breaks, duplicates and mismatches.


### Dashboard preview

![Streamlit Dashboard](images/streamlit_dashboard.png)
![Streamlit Dashboard](images/streamlit_dashboard-2.png)
![Streamlit Dashboard](images/streamlit_dashboard-3.png)
![Streamlit Dashboard](images/streamlit_dashboard-4.png)
![Streamlit Dashboard](images/streamlit_dashboard-5.png)
![Streamlit Dashboard](images/streamlit_dashboard-6.png)


## How to Run

### 1. Create the database

From the terminal:

```bash
sudo -u postgres createdb finance_reconciliation
```

### 2. Open psql

From the project root:

```bash
sudo -u postgres psql -d finance_reconciliation
```

### 3. Run the SQL scripts

Inside `psql`:

```sql
\i sql/01_create_schema.sql
\i sql/02_create_tables.sql
\i sql/03_insert_sample_data.sql
\i sql/05_reporting_views.sql
\i sql/04_reconciliation_queries.sql
\i sql/06_validation_checks.sql
```

Note: `05_reporting_views.sql` should be run before `04_reconciliation_queries.sql` because the analysis queries use the reporting views.

## Example Queries

Set the schema search path:

```sql
SET search_path TO finance_recon;
```

View reconciliation accuracy:

```sql
SELECT *
FROM vw_reconciliation_accuracy;
```

View open breaks:

```sql
SELECT *
FROM vw_open_breaks;
```

View aged exceptions:

```sql
SELECT
    reconciliation_result_id,
    exception_code,
    break_status,
    break_open_date,
    days_open,
    aging_threshold_days,
    days_over_aging_threshold,
    aging_bucket
FROM vw_aged_exceptions
ORDER BY
    days_over_aging_threshold DESC,
    reconciliation_result_id;
```

View exception summary:

```sql
SELECT *
FROM vw_exception_summary;
```

## Sample Findings

The sample reconciliation dataset produces:

| Control                                | Result |
| -------------------------------------- | -----: |
| Open or escalated breaks               |      8 |
| Aged exceptions                        |      8 |
| High-priority open or escalated breaks |      2 |
| Internal duplicate groups              |      1 |
| External duplicate groups              |      1 |
| Reference mismatches                   |      1 |

The data integrity validation checks return zero issues, confirming that the sample data is internally consistent.

## Key SQL Concepts Demonstrated

This project demonstrates:

* schema creation,
* primary keys,
* foreign keys,
* check constraints,
* identity columns,
* normalized reference matching,
* joins,
* left joins,
* aggregation,
* `FILTER` with aggregate functions,
* `CASE` expressions,
* `COALESCE`,
* date calculations,
* duplicate detection,
* reporting views,
* validation queries.

## Portfolio Relevance

This project is relevant for roles such as:

* Reconciliation Analyst,
* Finance Operations Analyst,
* Fund Accounting Analyst,
* Payments Operations Analyst,
* Portfolio Data Analyst,
* Business Analyst in financial services,
* Junior Data Analyst working with financial data.

It demonstrates both SQL capability and understanding of real finance operations controls.

The Streamlit dashboard demonstrates how SQL reconciliation outputs can be translated into a simple business-facing control view. This is relevant for finance operations, fund accounting, payments operations, and reconciliation analyst roles where stakeholders need quick visibility into open breaks, aged exceptions, match quality, and operational risk.

## Documentation

Additional documentation is available in the `docs/` folder:

| Document                  | Description                                                    |
| ------------------------- | -------------------------------------------------------------- |
| `business_case.md`        | Business context and project objective.                        |
| `data_dictionary.md`      | Table and field definitions.                                   |
| `reconciliation_rules.md` | Matching and exception rules.                                  |
| `findings.md`             | Summary of reconciliation results and business interpretation. |


## Output Examples

The `output_examples/` folder contains CSV exports generated from the reporting views.

These files allow reviewers to inspect sample reconciliation outputs without running the database locally.

Included examples:

- `matched_transactions_example.csv`
- `open_breaks_example.csv`
- `monthly_summary_example.csv`
- `aged_exceptions_example.csv`


## Optional Streamlit dashboard

This project includes a lightweight Streamlit dashboard for reviewing reconciliation outputs generated by the SQL layer.

The dashboard reads exported CSV files from `output_examples/`, so reviewers can open the UI without connecting to PostgreSQL or recreating the local database.

Dashboard features:

* KPI cards for open breaks, aged exceptions, high priority breaks, reference mismatches, and matched transactions;
* monthly reconciliation summary;
* result mix by month chart;
* filtered open breaks table;
* open breaks by exception type chart;
* filtered aged exceptions table;
* aged exceptions by aging bucket chart;
* matched transactions table;
* methodology notes explaining the reconciliation approach.

Run the dashboard from the project root:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
streamlit run app/streamlit_app.py
```

The dashboard uses these CSV files:

output_examples/
├── aged_exceptions_example.csv
├── matched_transactions_example.csv
├── monthly_summary_example.csv
└── open_breaks_example.csv


PostgreSQL remains the source of truth for reconciliation logic. The Streamlit dashboard is only a portfolio-friendly presentation layer for business review.



## Status

Current project status:

* database schema completed,
* sample data completed,
* reporting views completed,
* reconciliation analysis queries completed,
* validation checks completed,
* documentation in progress.
