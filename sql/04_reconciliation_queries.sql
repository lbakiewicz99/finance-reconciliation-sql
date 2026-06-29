-- ============================================================
-- Project: finance-reconciliation-sql
-- File: 04_reconciliation_queries.sql
-- Purpose: Example reconciliation analysis queries
-- Database: PostgreSQL
--
-- Note:
-- These queries use reporting views created in 05_reporting_views.sql.
-- Run 05_reporting_views.sql before running this file.
-- ============================================================

SET search_path TO finance_recon;

-- ============================================================
-- 1. Full reconciliation detail
-- ============================================================

SELECT
    *
FROM vw_reconciliation_detail
ORDER BY reconciliation_result_id;

-- ============================================================
-- 2. Matched transactions
-- ============================================================

SELECT
    reconciliation_result_id,
    run_date,
    fund_code,
    account_number,
    internal_reference,
    external_reference,
    internal_matching_reference,
    external_matching_reference,
    reference_status,
    internal_amount,
    external_amount,
    internal_currency,
    external_currency
FROM vw_reconciliation_detail
WHERE exception_code = 'MATCHED'
ORDER BY reconciliation_result_id;

-- ============================================================
-- 3. Open breaks
-- ============================================================

SELECT
    reconciliation_result_id,
    run_date,
    exception_code,
    exception_priority,
    break_status,
    days_open,
    fund_code,
    account_number,
    internal_reference,
    external_reference,
    reference_status,
    internal_amount,
    external_amount,
    notes
FROM vw_open_breaks
ORDER BY
    CASE exception_priority
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END,
    days_open DESC,
    reconciliation_result_id;

-- ============================================================
-- 4. Aged exceptions
-- ============================================================

SELECT
    reconciliation_result_id,
    run_date,
    exception_code,
    exception_priority,
    break_status,
    break_open_date,
    days_open,
    aging_threshold_days,
    days_over_aging_threshold,
    aging_bucket,
    fund_code,
    account_number,
    internal_reference,
    external_reference,
    reference_status,
    notes
FROM vw_aged_exceptions
ORDER BY
    days_open DESC,
    reconciliation_result_id;

-- ============================================================
-- 5. Amount mismatches
-- ============================================================

SELECT
    reconciliation_result_id,
    run_date,
    fund_code,
    account_number,
    internal_reference,
    external_reference,
    reference_status,
    internal_amount,
    external_amount,
    amount_difference,
    break_status,
    notes
FROM vw_reconciliation_detail
WHERE exception_code = 'AMOUNT_MISMATCH'
ORDER BY reconciliation_result_id;

-- ============================================================
-- 6. Date mismatches
-- ============================================================

SELECT
    reconciliation_result_id,
    run_date,
    fund_code,
    account_number,
    internal_reference,
    external_reference,
    reference_status,
    internal_settlement_date,
    external_value_date,
    date_difference_days,
    break_status,
    notes
FROM vw_reconciliation_detail
WHERE exception_code = 'DATE_MISMATCH'
ORDER BY reconciliation_result_id;

-- ============================================================
-- 7. Currency mismatches
-- ============================================================

SELECT
    reconciliation_result_id,
    run_date,
    fund_code,
    account_number,
    internal_reference,
    external_reference,
    reference_status,
    internal_currency,
    external_currency,
    internal_amount,
    external_amount,
    break_status,
    notes
FROM vw_reconciliation_detail
WHERE exception_code = 'CURRENCY_MISMATCH'
ORDER BY reconciliation_result_id;

-- ============================================================
-- 8. Reference mismatches
-- ============================================================

SELECT
    reconciliation_result_id,
    run_date,
    fund_code,
    account_number,
    internal_reference,
    external_reference,
    internal_matching_reference,
    external_matching_reference,
    reference_status,
    internal_amount,
    external_amount,
    internal_currency,
    external_currency,
    break_status,
    notes
FROM vw_reconciliation_detail
WHERE exception_code = 'REFERENCE_MISMATCH'
ORDER BY reconciliation_result_id;

-- ============================================================
-- 9. Duplicate internal transactions
-- ============================================================

SELECT
    fund_id,
    account_id,
    transaction_reference,
    matching_reference,
    transaction_type,
    direction,
    currency_code,
    amount,
    settlement_date,
    COUNT(*) AS duplicate_count,
    STRING_AGG(
        internal_transaction_id::TEXT,
        ', '
        ORDER BY internal_transaction_id
    ) AS internal_transaction_ids
FROM internal_transactions
GROUP BY
    fund_id,
    account_id,
    transaction_reference,
    matching_reference,
    transaction_type,
    direction,
    currency_code,
    amount,
    settlement_date
HAVING COUNT(*) > 1
ORDER BY
    duplicate_count DESC,
    transaction_reference;

-- ============================================================
-- 10. Duplicate external transactions
-- ============================================================

SELECT
    account_id,
    external_reference,
    matching_reference,
    statement_reference,
    transaction_type,
    direction,
    currency_code,
    amount,
    value_date,
    COUNT(*) AS duplicate_count,
    STRING_AGG(
        external_transaction_id::TEXT,
        ', '
        ORDER BY external_transaction_id
    ) AS external_transaction_ids
FROM external_transactions
GROUP BY
    account_id,
    external_reference,
    matching_reference,
    statement_reference,
    transaction_type,
    direction,
    currency_code,
    amount,
    value_date
HAVING COUNT(*) > 1
ORDER BY
    duplicate_count DESC,
    external_reference;

-- ============================================================
-- 11. Monthly reconciliation summary
-- ============================================================

SELECT
    *
FROM vw_monthly_reconciliation_summary
ORDER BY reconciliation_month_start_date;

-- ============================================================
-- 12. Exception summary
-- ============================================================

SELECT
    *
FROM vw_exception_summary
ORDER BY
    CASE exception_priority
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END,
    exception_count DESC;

-- ============================================================
-- 13. Reconciliation accuracy by run
-- ============================================================

SELECT
    *
FROM vw_reconciliation_accuracy
ORDER BY run_date;