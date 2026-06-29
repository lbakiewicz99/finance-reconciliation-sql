-- ============================================================
-- Project: finance-reconciliation-sql
-- File: 05_reporting_views.sql
-- Purpose: Create reporting views for reconciliation analysis
-- Database: PostgreSQL
-- ============================================================

SET search_path TO finance_recon;

-- ============================================================
-- Base view: vw_reconciliation_detail
-- Purpose:
-- Provides one clean transaction-level reconciliation dataset.
-- Other reporting views should build on this view instead of
-- repeating join and reference comparison logic.
-- ============================================================

CREATE OR REPLACE VIEW vw_reconciliation_detail AS
SELECT
    reconciliation_results.reconciliation_result_id,
    reconciliation_runs.reconciliation_run_id,
    reconciliation_runs.run_date,
    reconciliation_runs.period_start_date,
    reconciliation_runs.period_end_date,
    reconciliation_runs.run_status,

    exception_types.exception_code,
    exception_types.exception_name,
    exception_types.exception_priority,

    reconciliation_results.match_status,
    reconciliation_results.break_status,
    reconciliation_results.break_open_date,
    reconciliation_results.break_resolved_date,

    CASE
        WHEN reconciliation_results.break_open_date IS NULL
            THEN NULL
        ELSE CURRENT_DATE - reconciliation_results.break_open_date
    END AS days_open,

    funds.fund_id,
    funds.fund_code,
    funds.fund_name,

    accounts.account_id,
    accounts.account_number,
    accounts.account_name,
    accounts.account_type,

    internal_transactions.internal_transaction_id,
    external_transactions.external_transaction_id,

    internal_transactions.transaction_reference AS internal_reference,
    external_transactions.external_reference,

    internal_transactions.matching_reference AS internal_matching_reference,
    external_transactions.matching_reference AS external_matching_reference,

    CASE
        WHEN internal_transactions.internal_transaction_id IS NOT NULL
            AND external_transactions.external_transaction_id IS NULL
            THEN 'INTERNAL_ONLY'

        WHEN internal_transactions.internal_transaction_id IS NULL
            AND external_transactions.external_transaction_id IS NOT NULL
            THEN 'EXTERNAL_ONLY'

        WHEN internal_transactions.transaction_reference = external_transactions.external_reference
            THEN 'EXACT_REFERENCE_MATCH'

        WHEN internal_transactions.matching_reference = external_transactions.matching_reference
            THEN 'NORMALIZED_REFERENCE_MATCH'

        WHEN internal_transactions.matching_reference <> external_transactions.matching_reference
            THEN 'REFERENCE_MISMATCH'

        ELSE 'UNKNOWN'
    END AS reference_status,

    internal_transactions.transaction_type AS internal_transaction_type,
    external_transactions.transaction_type AS external_transaction_type,

    internal_transactions.direction AS internal_direction,
    external_transactions.direction AS external_direction,

    internal_transactions.currency_code AS internal_currency,
    external_transactions.currency_code AS external_currency,

    internal_transactions.amount AS internal_amount,
    external_transactions.amount AS external_amount,

    internal_transactions.trade_date AS internal_trade_date,
    internal_transactions.settlement_date AS internal_settlement_date,
    internal_transactions.booking_date AS internal_booking_date,

    external_transactions.value_date AS external_value_date,
    external_transactions.booking_date AS external_booking_date,

    reconciliation_results.amount_difference,
    reconciliation_results.date_difference_days,
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
LEFT JOIN accounts
    ON COALESCE(
        internal_transactions.account_id,
        external_transactions.account_id
    ) = accounts.account_id
LEFT JOIN funds
    ON accounts.fund_id = funds.fund_id;

-- ============================================================
-- View: vw_open_breaks
-- Purpose:
-- Shows all currently open or escalated breaks.
-- ============================================================

CREATE OR REPLACE VIEW vw_open_breaks AS
SELECT
    reconciliation_result_id,
    run_date,
    period_start_date,
    period_end_date,

    exception_code,
    exception_name,
    exception_priority,

    match_status,
    break_status,
    break_open_date,
    days_open,

    fund_code,
    fund_name,
    account_number,
    account_name,

    internal_transaction_id,
    external_transaction_id,

    internal_reference,
    external_reference,
    internal_matching_reference,
    external_matching_reference,
    reference_status,

    internal_transaction_type,
    external_transaction_type,

    internal_direction,
    external_direction,

    internal_currency,
    external_currency,

    internal_amount,
    external_amount,

    amount_difference,
    date_difference_days,
    notes
FROM vw_reconciliation_detail
WHERE break_status IN ('OPEN', 'ESCALATED');

-- ============================================================
-- View: vw_aged_exceptions
-- Purpose:
-- Shows unresolved breaks older than 5 calendar days.
-- Adds aging severity fields to support prioritization.
-- ============================================================

CREATE OR REPLACE VIEW vw_aged_exceptions AS
SELECT
    reconciliation_result_id,
    run_date,
    exception_code,
    exception_name,
    exception_priority,

    match_status,
    break_status,
    break_open_date,
    days_open,

    fund_code,
    account_number,

    internal_reference,
    external_reference,
    internal_matching_reference,
    external_matching_reference,
    reference_status,

    internal_currency,
    external_currency,

    internal_amount,
    external_amount,

    notes,

    5 AS aging_threshold_days,

    days_open - 5 AS days_over_aging_threshold,

    CASE
        WHEN days_open BETWEEN 6 AND 10
            THEN 'AGED_6_TO_10_DAYS'
        WHEN days_open BETWEEN 11 AND 30
            THEN 'AGED_11_TO_30_DAYS'
        WHEN days_open BETWEEN 31 AND 90
            THEN 'AGED_31_TO_90_DAYS'
        WHEN days_open > 90
            THEN 'AGED_OVER_90_DAYS'
        ELSE 'NOT_AGED'
    END AS aging_bucket
FROM vw_reconciliation_detail
WHERE break_status IN ('OPEN', 'ESCALATED')
  AND days_open > 5;

-- ============================================================
-- View: vw_monthly_reconciliation_summary
-- Purpose:
-- Summarizes reconciliation results by month.
-- ============================================================

CREATE OR REPLACE VIEW vw_monthly_reconciliation_summary AS
SELECT
    DATE_TRUNC('month', period_end_date)::DATE AS reconciliation_month_start_date,

    COUNT(*) AS total_results,

    COUNT(*) FILTER (
        WHERE match_status = 'MATCHED'
    ) AS matched_count,

    COUNT(*) FILTER (
        WHERE match_status = 'UNMATCHED'
    ) AS unmatched_count,

    COUNT(*) FILTER (
        WHERE match_status = 'MISMATCH'
    ) AS mismatch_count,

    COUNT(*) FILTER (
        WHERE match_status = 'DUPLICATE'
    ) AS duplicate_count,

    COUNT(*) FILTER (
        WHERE break_status IN ('OPEN', 'ESCALATED')
    ) AS open_break_count,

    COUNT(*) FILTER (
        WHERE break_status IN (
            'RESOLVED',
            'CLOSED_AS_TIMING',
            'CLOSED_AS_VALID'
        )
    ) AS closed_break_count,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE match_status = 'MATCHED'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS reconciliation_accuracy_pct
FROM vw_reconciliation_detail
GROUP BY DATE_TRUNC('month', period_end_date)::DATE;

-- ============================================================
-- View: vw_exception_summary
-- Purpose:
-- Summarizes reconciliation exceptions by type.
-- Matched records are excluded.
-- ============================================================

CREATE OR REPLACE VIEW vw_exception_summary AS
SELECT
    exception_code,
    exception_name,
    exception_priority,

    COUNT(*) AS exception_count,

    COUNT(*) FILTER (
        WHERE break_status IN ('OPEN', 'ESCALATED')
    ) AS open_count,

    COUNT(*) FILTER (
        WHERE break_status IN (
            'RESOLVED',
            'CLOSED_AS_TIMING',
            'CLOSED_AS_VALID'
        )
    ) AS closed_count,

    ROUND(
        AVG(amount_difference),
        2
    ) AS average_amount_difference,

    MIN(break_open_date) AS earliest_break_open_date,
    MAX(break_open_date) AS latest_break_open_date
FROM vw_reconciliation_detail
WHERE exception_code <> 'MATCHED'
GROUP BY
    exception_code,
    exception_name,
    exception_priority;

-- ============================================================
-- View: vw_reconciliation_accuracy
-- Purpose:
-- Shows reconciliation accuracy by reconciliation run.
-- ============================================================

CREATE OR REPLACE VIEW vw_reconciliation_accuracy AS
SELECT
    reconciliation_run_id,
    run_date,
    period_start_date,
    period_end_date,
    run_status,

    COUNT(*) AS total_results,

    COUNT(*) FILTER (
        WHERE match_status = 'MATCHED'
    ) AS matched_count,

    COUNT(*) FILTER (
        WHERE match_status <> 'MATCHED'
    ) AS exception_count,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE match_status = 'MATCHED'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS reconciliation_accuracy_pct,

    COUNT(*) FILTER (
        WHERE break_status IN ('OPEN', 'ESCALATED')
    ) AS unresolved_break_count,

    COUNT(*) FILTER (
        WHERE break_status IN (
            'RESOLVED',
            'CLOSED_AS_TIMING',
            'CLOSED_AS_VALID'
        )
    ) AS resolved_or_closed_break_count
FROM vw_reconciliation_detail
GROUP BY
    reconciliation_run_id,
    run_date,
    period_start_date,
    period_end_date,
    run_status;