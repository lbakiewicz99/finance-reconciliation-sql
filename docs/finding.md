# Findings

## Overview

This document summarizes the key findings produced by the `finance-reconciliation-sql` project.

The project simulates a reconciliation process between internal finance or fund accounting transaction records and external statement records received from banks, custodians or payment service providers.

The sample dataset intentionally includes matched transactions, unmatched records, mismatches, duplicate transactions, aged breaks and manually resolved exceptions.

## Reconciliation Accuracy

The reconciliation accuracy view shows the percentage of fully matched records per reconciliation run.

Based on the sample data:

| Reconciliation Run | Period End Date | Total Results | Matched Count | Exception Count | Accuracy |
| ------------------ | --------------: | ------------: | ------------: | --------------: | -------: |
| January 2025       |      2025-01-31 |            13 |             2 |              11 |   15.38% |
| February 2025      |      2025-02-28 |             1 |             1 |               0 |  100.00% |

January has a low reconciliation accuracy because the sample dataset intentionally includes multiple operational breaks and exception scenarios.

February contains one clean matched transaction.

## Open Breaks

The open breaks view identifies currently unresolved or escalated reconciliation results.

The sample data includes open or escalated breaks across several exception types:

* unmatched internal transactions,
* currency mismatches,
* duplicate internal transactions,
* duplicate external transactions,
* aged open breaks,
* reference mismatches.

These records represent the current reconciliation workload that would require investigation by an operations or reconciliation analyst.

## Aged Exceptions

Aged exceptions are unresolved breaks that have remained open for more than 5 calendar days.

The project calculates:

* `days_open`,
* `aging_threshold_days`,
* `days_over_aging_threshold`,
* `aging_bucket`.

This allows analysts to distinguish between recently aged breaks and long-outstanding unresolved exceptions.

In the sample data, aged exception values are high because the sample transaction dates are from 2025 and the aging calculation uses `CURRENT_DATE`.

## Exception Summary

The exception summary view groups reconciliation results by exception type.

The sample data includes the following exception categories:

| Exception Type       | Description                                                                    |
| -------------------- | ------------------------------------------------------------------------------ |
| `UNMATCHED_INTERNAL` | Internal transaction exists without a matching external statement line.        |
| `UNMATCHED_EXTERNAL` | External statement line exists without a matching internal transaction.        |
| `AMOUNT_MISMATCH`    | Internal and external amounts differ.                                          |
| `DATE_MISMATCH`      | Internal settlement date and external value date differ.                       |
| `CURRENCY_MISMATCH`  | Internal and external currencies differ.                                       |
| `REFERENCE_MISMATCH` | Normalized references differ despite other fields suggesting a possible match. |
| `DUPLICATE_INTERNAL` | Duplicate transaction detected in internal data.                               |
| `DUPLICATE_EXTERNAL` | Duplicate transaction detected in external data.                               |
| `AGED_OPEN_BREAK`    | Unresolved break older than the defined aging threshold.                       |

## Duplicate Detection

The validation checks identify:

* one internal duplicate group,
* one external duplicate group.

Duplicate detection is based on key business fields such as:

* account,
* transaction reference,
* matching reference,
* transaction type,
* direction,
* currency,
* amount,
* settlement date or value date.

The project does not prevent duplicate records at table level because duplicates are part of the reconciliation scenarios being tested.

## Reference Matching Logic

The project separates raw references from normalized matching references.

Raw references are stored as received from source systems:

* `internal_transactions.transaction_reference`,
* `external_transactions.external_reference`.

Matching references are normalized values used for reconciliation logic:

* `internal_transactions.matching_reference`,
* `external_transactions.matching_reference`.

This reflects realistic reconciliation cases where external sources may add prefixes, suffixes or provider-specific formatting to references.

Example:

| Source                 | Raw Reference               | Matching Reference |
| ---------------------- | --------------------------- | ------------------ |
| Internal system        | `TXN-2025-0004`             | `TXN-2025-0004`    |
| External PSP statement | `PSP-CAPTURE-TXN-2025-0004` | `TXN-2025-0004`    |

The raw references differ, but the normalized matching reference allows the transaction to be reconciled.

## Validation Results

The validation checks confirm that the sample dataset is internally consistent.

The data integrity checks return zero issues for:

* blank internal matching references,
* blank external matching references,
* unsupported currencies,
* fund and account mismatches,
* invalid reconciliation periods,
* manual adjustments without reasons.

The reconciliation result checks return zero issues for:

* missing break dates,
* inconsistent match statuses,
* incorrect amount differences,
* incorrect date differences,
* reference mismatch status logic,
* matched records with unexpected break data.

This confirms that the sample data is intentionally designed and logically consistent.

## Business Interpretation

The sample reconciliation process highlights several operational risks:

1. **Unmatched transactions** may indicate missing bookings, delayed statement lines or incomplete system feeds.
2. **Amount mismatches** may indicate fees, incorrect booking values or external processing deductions.
3. **Date mismatches** may indicate timing differences between internal settlement dates and external value dates.
4. **Currency mismatches** may indicate booking errors, mapping issues or incorrect account usage.
5. **Reference mismatches** may indicate incorrect mapping, external formatting issues or potential false-positive matches.
6. **Duplicate records** may indicate source system issues, duplicate file loads or manual booking errors.
7. **Aged open breaks** represent unresolved operational risk and should be prioritized.

## Recommended Analyst Actions

A reconciliation analyst reviewing this output would typically:

1. investigate high-priority open breaks first,
2. review aged exceptions by `days_over_aging_threshold`,
3. confirm whether duplicate records are valid or erroneous,
4. review reference mismatches against source documents,
5. validate amount differences against fee schedules or PSP deductions,
6. confirm date mismatches as timing differences where appropriate,
7. document manual adjustments and resolution notes.

## Conclusion

The project demonstrates how SQL can support a finance reconciliation workflow by combining:

* relational data modelling,
* transaction-level matching,
* exception classification,
* operational break reporting,
* aging analysis,
* data quality validation,
* business-focused interpretation.

The findings show that the SQL model can identify both clean matches and realistic operational exceptions in a controlled sample dataset.
