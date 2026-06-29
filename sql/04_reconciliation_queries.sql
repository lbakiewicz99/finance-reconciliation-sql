-- ============================================================
-- Project: finance-reconciliation-sql
-- File: 04_reconciliation_queries.sql
-- Purpose: Core reconciliation analysis queries
-- Database: PostgreSQL
-- ============================================================

SET search_path TO finance_recon;

-- ============================================================
-- 1. Matched transactions
-- Shows transactions that fully matched between internal and external data.
-- ============================================================

SELECT
    reconciliation_results.reconciliation_result_id,
    reconciliation_runs.run_date,
    funds.fund_code,
    accounts.account_number,
    internal_transactions.transaction_reference AS internal_reference,
    external_transactions.external_reference,
    internal_transactions.transaction_type,
    internal_transactions.direction,
    internal_transactions.currency_code,
    internal_transactions.amount AS internal_amount,
    external_transactions.amount AS external_amount,
    internal_transactions.settlement_date,
    external_transactions.value_date,
    exception_types.exception_code,
    reconciliation_results.match_status,
    reconciliation_results.break_status
FROM reconciliation_results
JOIN reconciliation_runs
    ON reconciliation_results.reconciliation_run_id = reconciliation_runs.reconciliation_run_id
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
JOIN internal_transactions
    ON reconciliation_results.internal_transaction_id = internal_transactions.internal_transaction_id
JOIN external_transactions
    ON reconciliation_results.external_transaction_id = external_transactions.external_transaction_id
JOIN funds
    ON internal_transactions.fund_id = funds.fund_id
JOIN accounts
    ON internal_transactions.account_id = accounts.account_id
WHERE exception_types.exception_code = 'MATCHED'
ORDER BY reconciliation_results.reconciliation_result_id;

-- ============================================================
-- 2. Unmatched internal records
-- Shows internal records with no corresponding external transaction.
-- ============================================================

SELECT
    reconciliation_results.reconciliation_result_id,
    reconciliation_runs.run_date,
    funds.fund_code,
    accounts.account_number,
    internal_transactions.internal_transaction_id,
    internal_transactions.transaction_reference,
    internal_transactions.transaction_type,
    internal_transactions.direction,
    internal_transactions.currency_code,
    internal_transactions.amount,
    internal_transactions.settlement_date,
    internal_transactions.booking_date,
    exception_types.exception_code,
    reconciliation_results.match_status,
    reconciliation_results.break_status,
    reconciliation_results.break_open_date,
    reconciliation_results.notes
FROM reconciliation_results
JOIN reconciliation_runs
    ON reconciliation_results.reconciliation_run_id = reconciliation_runs.reconciliation_run_id
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
JOIN internal_transactions
    ON reconciliation_results.internal_transaction_id = internal_transactions.internal_transaction_id
JOIN funds
    ON internal_transactions.fund_id = funds.fund_id
JOIN accounts
    ON internal_transactions.account_id = accounts.account_id
WHERE reconciliation_results.internal_transaction_id IS NOT NULL
  AND reconciliation_results.external_transaction_id IS NULL
  AND reconciliation_results.match_status = 'UNMATCHED'
ORDER BY
    reconciliation_results.break_open_date,
    internal_transactions.transaction_reference;

-- ============================================================
-- 3. Unmatched external records
-- Shows external statement records with no corresponding internal transaction.
-- ============================================================

SELECT
    reconciliation_results.reconciliation_result_id,
    reconciliation_runs.run_date,
    funds.fund_code,
    accounts.account_number,
    external_transactions.external_transaction_id,
    external_transactions.external_reference,
    external_transactions.statement_reference,
    external_transactions.transaction_type,
    external_transactions.direction,
    external_transactions.currency_code,
    external_transactions.amount,
    external_transactions.value_date,
    external_transactions.booking_date,
    external_transactions.counterparty,
    external_transactions.statement_source,
    exception_types.exception_code,
    reconciliation_results.match_status,
    reconciliation_results.break_status,
    reconciliation_results.break_open_date,
    reconciliation_results.notes
FROM reconciliation_results
JOIN reconciliation_runs
    ON reconciliation_results.reconciliation_run_id = reconciliation_runs.reconciliation_run_id
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
JOIN external_transactions
    ON reconciliation_results.external_transaction_id = external_transactions.external_transaction_id
JOIN accounts
    ON external_transactions.account_id = accounts.account_id
JOIN funds
    ON accounts.fund_id = funds.fund_id
WHERE reconciliation_results.internal_transaction_id IS NULL
  AND reconciliation_results.external_transaction_id IS NOT NULL
  AND reconciliation_results.match_status = 'UNMATCHED'
ORDER BY
    reconciliation_results.break_open_date,
    external_transactions.external_reference;

-- ============================================================
-- 4. Amount mismatches
-- Shows transactions where the same business transaction exists
-- in both sources, but the amount differs.
-- ============================================================

SELECT
    reconciliation_results.reconciliation_result_id,
    reconciliation_runs.run_date,
    funds.fund_code,
    accounts.account_number,
    internal_transactions.transaction_reference AS internal_reference,
    external_transactions.external_reference,
    internal_transactions.transaction_type,
    internal_transactions.direction,
    internal_transactions.currency_code,
    internal_transactions.amount AS internal_amount,
    external_transactions.amount AS external_amount,
    reconciliation_results.amount_difference,
    internal_transactions.settlement_date,
    external_transactions.value_date,
    reconciliation_results.break_status,
    reconciliation_results.break_open_date,
    reconciliation_results.break_resolved_date,
    reconciliation_results.notes
FROM reconciliation_results
JOIN reconciliation_runs
    ON reconciliation_results.reconciliation_run_id = reconciliation_runs.reconciliation_run_id
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
JOIN internal_transactions
    ON reconciliation_results.internal_transaction_id = internal_transactions.internal_transaction_id
JOIN external_transactions
    ON reconciliation_results.external_transaction_id = external_transactions.external_transaction_id
JOIN funds
    ON internal_transactions.fund_id = funds.fund_id
JOIN accounts
    ON internal_transactions.account_id = accounts.account_id
WHERE exception_types.exception_code = 'AMOUNT_MISMATCH'
ORDER BY reconciliation_results.reconciliation_result_id;

-- ============================================================
-- 5. Date mismatches
-- Shows transactions where amount and core reference data match,
-- but internal settlement date differs from external value date.
-- ============================================================

SELECT
    reconciliation_results.reconciliation_result_id,
    reconciliation_runs.run_date,
    funds.fund_code,
    accounts.account_number,
    internal_transactions.transaction_reference AS internal_reference,
    external_transactions.external_reference,
    internal_transactions.transaction_type,
    internal_transactions.direction,
    internal_transactions.currency_code,
    internal_transactions.amount AS internal_amount,
    external_transactions.amount AS external_amount,
    internal_transactions.settlement_date AS internal_settlement_date,
    external_transactions.value_date AS external_value_date,
    reconciliation_results.date_difference_days,
    reconciliation_results.break_status,
    reconciliation_results.break_open_date,
    reconciliation_results.break_resolved_date,
    reconciliation_results.notes
FROM reconciliation_results
JOIN reconciliation_runs
    ON reconciliation_results.reconciliation_run_id = reconciliation_runs.reconciliation_run_id
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
JOIN internal_transactions
    ON reconciliation_results.internal_transaction_id = internal_transactions.internal_transaction_id
JOIN external_transactions
    ON reconciliation_results.external_transaction_id = external_transactions.external_transaction_id
JOIN funds
    ON internal_transactions.fund_id = funds.fund_id
JOIN accounts
    ON internal_transactions.account_id = accounts.account_id
WHERE exception_types.exception_code = 'DATE_MISMATCH'
ORDER BY reconciliation_results.reconciliation_result_id;

-- ============================================================
-- 6. Currency mismatches
-- Shows transactions where reference/account/date/amount suggest
-- a match, but currency differs.
-- ============================================================

SELECT
    reconciliation_results.reconciliation_result_id,
    reconciliation_runs.run_date,
    funds.fund_code,
    accounts.account_number,
    internal_transactions.transaction_reference AS internal_reference,
    external_transactions.external_reference,
    internal_transactions.transaction_type,
    internal_transactions.direction,
    internal_transactions.currency_code AS internal_currency,
    external_transactions.currency_code AS external_currency,
    internal_transactions.amount AS internal_amount,
    external_transactions.amount AS external_amount,
    internal_transactions.settlement_date,
    external_transactions.value_date,
    reconciliation_results.break_status,
    reconciliation_results.notes
FROM reconciliation_results
JOIN reconciliation_runs
    ON reconciliation_results.reconciliation_run_id = reconciliation_runs.reconciliation_run_id
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
JOIN internal_transactions
    ON reconciliation_results.internal_transaction_id = internal_transactions.internal_transaction_id
JOIN external_transactions
    ON reconciliation_results.external_transaction_id = external_transactions.external_transaction_id
JOIN funds
    ON internal_transactions.fund_id = funds.fund_id
JOIN accounts
    ON internal_transactions.account_id = accounts.account_id
WHERE exception_types.exception_code = 'CURRENCY_MISMATCH'
ORDER BY reconciliation_results.reconciliation_result_id;

-- ============================================================
-- 7. Duplicate detection: internal transactions
-- Detects duplicate internal records based on key business fields.
-- ============================================================

SELECT
    internal_transactions.fund_id,
    internal_transactions.account_id,
    internal_transactions.transaction_reference,
    internal_transactions.transaction_type,
    internal_transactions.direction,
    internal_transactions.currency_code,
    internal_transactions.amount,
    internal_transactions.settlement_date,
    COUNT(*) AS duplicate_count,
    STRING_AGG(
        internal_transactions.internal_transaction_id::TEXT,
        ', '
        ORDER BY internal_transactions.internal_transaction_id
    ) AS internal_transaction_ids
FROM internal_transactions
GROUP BY
    internal_transactions.fund_id,
    internal_transactions.account_id,
    internal_transactions.transaction_reference,
    internal_transactions.transaction_type,
    internal_transactions.direction,
    internal_transactions.currency_code,
    internal_transactions.amount,
    internal_transactions.settlement_date
HAVING COUNT(*) > 1
ORDER BY
    duplicate_count DESC,
    internal_transactions.transaction_reference;

-- ============================================================
-- 8. Duplicate detection: external transactions
-- Detects duplicate external statement records based on key fields.
-- ============================================================

SELECT
    external_transactions.account_id,
    external_transactions.external_reference,
    external_transactions.statement_reference,
    external_transactions.transaction_type,
    external_transactions.direction,
    external_transactions.currency_code,
    external_transactions.amount,
    external_transactions.value_date,
    COUNT(*) AS duplicate_count,
    STRING_AGG(
        external_transactions.external_transaction_id::TEXT,
        ', '
        ORDER BY external_transactions.external_transaction_id
    ) AS external_transaction_ids
FROM external_transactions
GROUP BY
    external_transactions.account_id,
    external_transactions.external_reference,
    external_transactions.statement_reference,
    external_transactions.transaction_type,
    external_transactions.direction,
    external_transactions.currency_code,
    external_transactions.amount,
    external_transactions.value_date
HAVING COUNT(*) > 1
ORDER BY
    duplicate_count DESC,
    external_transactions.external_reference;

-- ============================================================
-- 9. Aged open breaks
-- Shows unresolved breaks that have remained open for more than
-- 5 calendar days.
-- ============================================================

SELECT
    reconciliation_results.reconciliation_result_id,
    reconciliation_runs.run_date,
    exception_types.exception_code,
    exception_types.exception_name,
    reconciliation_results.match_status,
    reconciliation_results.break_status,
    reconciliation_results.break_open_date,
    CURRENT_DATE - reconciliation_results.break_open_date AS days_open,
    reconciliation_results.internal_transaction_id,
    reconciliation_results.external_transaction_id,
    reconciliation_results.notes
FROM reconciliation_results
JOIN reconciliation_runs
    ON reconciliation_results.reconciliation_run_id = reconciliation_runs.reconciliation_run_id
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
WHERE reconciliation_results.break_status IN ('OPEN', 'ESCALATED')
  AND reconciliation_results.break_open_date IS NOT NULL
  AND CURRENT_DATE - reconciliation_results.break_open_date > 5
ORDER BY
    days_open DESC,
    reconciliation_results.reconciliation_result_id;

-- ============================================================
-- 10. Monthly reconciliation summary
-- Summarizes reconciliation quality by reconciliation period.
-- ============================================================

SELECT
    DATE_TRUNC('month', reconciliation_runs.period_end_date)::DATE AS reconciliation_month,
    COUNT(*) AS total_results,
    COUNT(*) FILTER (
        WHERE reconciliation_results.match_status = 'MATCHED'
    ) AS matched_count,
    COUNT(*) FILTER (
        WHERE reconciliation_results.match_status = 'UNMATCHED'
    ) AS unmatched_count,
    COUNT(*) FILTER (
        WHERE reconciliation_results.match_status = 'MISMATCH'
    ) AS mismatch_count,
    COUNT(*) FILTER (
        WHERE reconciliation_results.match_status = 'DUPLICATE'
    ) AS duplicate_count,
    COUNT(*) FILTER (
        WHERE reconciliation_results.break_status IN ('OPEN', 'ESCALATED')
    ) AS open_break_count,
    COUNT(*) FILTER (
        WHERE reconciliation_results.break_status IN (
            'RESOLVED',
            'CLOSED_AS_TIMING',
            'CLOSED_AS_VALID'
        )
    ) AS closed_break_count,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE reconciliation_results.match_status = 'MATCHED'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS reconciliation_accuracy_pct
FROM reconciliation_results
JOIN reconciliation_runs
    ON reconciliation_results.reconciliation_run_id = reconciliation_runs.reconciliation_run_id
GROUP BY DATE_TRUNC('month', reconciliation_runs.period_end_date)::DATE
ORDER BY reconciliation_month;

-- ============================================================
-- 11. Exceptions by type
-- Shows volume and status split by exception category.
-- ============================================================

SELECT
    exception_types.exception_code,
    exception_types.exception_name,
    exception_types.exception_priority,
    COUNT(*) AS exception_count,
    COUNT(*) FILTER (
        WHERE reconciliation_results.break_status IN ('OPEN', 'ESCALATED')
    ) AS open_count,
    COUNT(*) FILTER (
        WHERE reconciliation_results.break_status IN (
            'RESOLVED',
            'CLOSED_AS_TIMING',
            'CLOSED_AS_VALID'
        )
    ) AS closed_count,
    ROUND(AVG(reconciliation_results.amount_difference), 2) AS avg_amount_difference,
    MAX(reconciliation_results.break_open_date) AS latest_break_open_date
FROM reconciliation_results
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
WHERE exception_types.exception_code <> 'MATCHED'
GROUP BY
    exception_types.exception_code,
    exception_types.exception_name,
    exception_types.exception_priority
ORDER BY
    CASE exception_types.exception_priority
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END,
    exception_count DESC;

-- ============================================================
-- 12. Resolved vs unresolved breaks
-- Summarizes break resolution status.
-- ============================================================

SELECT
    CASE
        WHEN reconciliation_results.break_status IN (
            'RESOLVED',
            'CLOSED_AS_TIMING',
            'CLOSED_AS_VALID'
        )
            THEN 'RESOLVED_OR_CLOSED'
        WHEN reconciliation_results.break_status IN ('OPEN', 'ESCALATED')
            THEN 'UNRESOLVED'
        WHEN reconciliation_results.break_status = 'NOT_APPLICABLE'
            THEN 'NOT_APPLICABLE'
        ELSE 'OTHER'
    END AS resolution_group,
    COUNT(*) AS result_count
FROM reconciliation_results
GROUP BY
    CASE
        WHEN reconciliation_results.break_status IN (
            'RESOLVED',
            'CLOSED_AS_TIMING',
            'CLOSED_AS_VALID'
        )
            THEN 'RESOLVED_OR_CLOSED'
        WHEN reconciliation_results.break_status IN ('OPEN', 'ESCALATED')
            THEN 'UNRESOLVED'
        WHEN reconciliation_results.break_status = 'NOT_APPLICABLE'
            THEN 'NOT_APPLICABLE'
        ELSE 'OTHER'
    END
ORDER BY result_count DESC;

-- ============================================================
-- 13. Open breaks detail
-- Practical operational view of all currently open or escalated breaks.
-- ============================================================

SELECT
    reconciliation_results.reconciliation_result_id,
    reconciliation_runs.run_date,
    exception_types.exception_code,
    exception_types.exception_priority,
    reconciliation_results.match_status,
    reconciliation_results.break_status,
    reconciliation_results.break_open_date,
    CURRENT_DATE - reconciliation_results.break_open_date AS days_open,
    COALESCE(
        internal_transactions.transaction_reference,
        external_transactions.external_reference
    ) AS transaction_reference,
    COALESCE(
        internal_transactions.currency_code,
        external_transactions.currency_code
    ) AS currency_code,
    COALESCE(
        internal_transactions.amount,
        external_transactions.amount
    ) AS amount,
    reconciliation_results.notes
FROM reconciliation_results
JOIN reconciliation_runs
    ON reconciliation_results.reconciliation_run_id = reconciliation_runs.reconciliation_run_id
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
LEFT JOIN internal_transactions
    ON reconciliation_results.internal_transaction_id = internal_transactions.internal_transaction_id
LEFT JOIN external_transactions
    ON reconciliation_results.external_transaction_id = external_transactions.external_transaction_id
WHERE reconciliation_results.break_status IN ('OPEN', 'ESCALATED')
ORDER BY
    CASE exception_types.exception_priority
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END,
    days_open DESC;