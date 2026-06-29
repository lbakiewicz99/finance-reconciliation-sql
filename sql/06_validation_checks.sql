-- ============================================================
-- Project: finance-reconciliation-sql
-- File: 06_validation_checks.sql
-- Purpose: Data quality and reconciliation logic validation checks
-- Database: PostgreSQL
--
-- Notes:
-- 1. Data integrity checks should normally return issue_count = 0.
-- 2. Reconciliation logic checks should normally return issue_count = 0.
-- 3. Operational control checks may return values above 0 because
--    sample data intentionally contains breaks and exceptions.
-- ============================================================

SET search_path TO finance_recon;

-- ============================================================
-- 1. Data integrity validation summary
-- These checks should normally return issue_count = 0.
-- ============================================================

SELECT
    'blank_internal_matching_reference' AS validation_check,
    COUNT(*) AS issue_count
FROM internal_transactions
WHERE internal_transactions.matching_reference IS NULL
   OR TRIM(internal_transactions.matching_reference) = ''

UNION ALL

SELECT
    'blank_external_matching_reference' AS validation_check,
    COUNT(*) AS issue_count
FROM external_transactions
WHERE external_transactions.matching_reference IS NULL
   OR TRIM(external_transactions.matching_reference) = ''

UNION ALL

SELECT
    'unsupported_fund_base_currency' AS validation_check,
    COUNT(*) AS issue_count
FROM funds
JOIN currencies
    ON funds.base_currency = currencies.currency_code
WHERE currencies.is_supported = FALSE

UNION ALL

SELECT
    'unsupported_account_currency' AS validation_check,
    COUNT(*) AS issue_count
FROM accounts
JOIN currencies
    ON accounts.currency_code = currencies.currency_code
WHERE currencies.is_supported = FALSE

UNION ALL

SELECT
    'unsupported_internal_transaction_currency' AS validation_check,
    COUNT(*) AS issue_count
FROM internal_transactions
JOIN currencies
    ON internal_transactions.currency_code = currencies.currency_code
WHERE currencies.is_supported = FALSE

UNION ALL

SELECT
    'unsupported_external_transaction_currency' AS validation_check,
    COUNT(*) AS issue_count
FROM external_transactions
JOIN currencies
    ON external_transactions.currency_code = currencies.currency_code
WHERE currencies.is_supported = FALSE

UNION ALL

SELECT
    'internal_transaction_account_fund_mismatch' AS validation_check,
    COUNT(*) AS issue_count
FROM internal_transactions
JOIN accounts
    ON internal_transactions.account_id = accounts.account_id
WHERE internal_transactions.fund_id <> accounts.fund_id

UNION ALL

SELECT
    'invalid_reconciliation_run_period' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_runs
WHERE reconciliation_runs.period_start_date > reconciliation_runs.period_end_date

UNION ALL

SELECT
    'manual_adjustment_without_reason' AS validation_check,
    COUNT(*) AS issue_count
FROM manual_adjustments
WHERE manual_adjustments.adjustment_reason IS NULL
   OR TRIM(manual_adjustments.adjustment_reason) = ''

ORDER BY validation_check;

-- ============================================================
-- 2. Reconciliation result validation summary
-- These checks should normally return issue_count = 0.
-- ============================================================

SELECT
    'open_or_escalated_break_missing_open_date' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_results
WHERE reconciliation_results.break_status IN ('OPEN', 'ESCALATED')
  AND reconciliation_results.break_open_date IS NULL

UNION ALL

SELECT
    'resolved_or_closed_break_missing_resolved_date' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_results
WHERE reconciliation_results.break_status IN (
        'RESOLVED',
        'CLOSED_AS_TIMING',
        'CLOSED_AS_VALID'
    )
  AND reconciliation_results.break_resolved_date IS NULL

UNION ALL

SELECT
    'resolved_date_before_open_date' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_results
WHERE reconciliation_results.break_open_date IS NOT NULL
  AND reconciliation_results.break_resolved_date IS NOT NULL
  AND reconciliation_results.break_resolved_date < reconciliation_results.break_open_date

UNION ALL

SELECT
    'not_applicable_break_not_matched' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_results
WHERE reconciliation_results.break_status = 'NOT_APPLICABLE'
  AND reconciliation_results.match_status <> 'MATCHED'

UNION ALL

SELECT
    'matched_result_with_break_dates' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_results
WHERE reconciliation_results.match_status = 'MATCHED'
  AND (
        reconciliation_results.break_open_date IS NOT NULL
        OR reconciliation_results.break_resolved_date IS NOT NULL
    )

UNION ALL

SELECT
    'matched_result_missing_transaction_side' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_results
WHERE reconciliation_results.match_status = 'MATCHED'
  AND (
        reconciliation_results.internal_transaction_id IS NULL
        OR reconciliation_results.external_transaction_id IS NULL
    )

UNION ALL

SELECT
    'matched_result_has_nonzero_amount_difference' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_results
WHERE reconciliation_results.match_status = 'MATCHED'
  AND COALESCE(reconciliation_results.amount_difference, 0) <> 0

UNION ALL

SELECT
    'matched_result_has_nonzero_date_difference' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_results
WHERE reconciliation_results.match_status = 'MATCHED'
  AND COALESCE(reconciliation_results.date_difference_days, 0) <> 0

UNION ALL

SELECT
    'mismatch_result_missing_transaction_side' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_results
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
WHERE exception_types.exception_code IN (
        'AMOUNT_MISMATCH',
        'DATE_MISMATCH',
        'CURRENCY_MISMATCH',
        'REFERENCE_MISMATCH'
    )
  AND (
        reconciliation_results.internal_transaction_id IS NULL
        OR reconciliation_results.external_transaction_id IS NULL
    )

UNION ALL

SELECT
    'exception_code_match_status_inconsistency' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_results
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
WHERE (
        exception_types.exception_code = 'MATCHED'
        AND reconciliation_results.match_status <> 'MATCHED'
    )
   OR (
        exception_types.exception_code IN (
            'UNMATCHED_INTERNAL',
            'UNMATCHED_EXTERNAL',
            'AGED_OPEN_BREAK'
        )
        AND reconciliation_results.match_status <> 'UNMATCHED'
    )
   OR (
        exception_types.exception_code IN (
            'AMOUNT_MISMATCH',
            'DATE_MISMATCH',
            'CURRENCY_MISMATCH',
            'REFERENCE_MISMATCH'
        )
        AND reconciliation_results.match_status <> 'MISMATCH'
    )
   OR (
        exception_types.exception_code IN (
            'DUPLICATE_INTERNAL',
            'DUPLICATE_EXTERNAL'
        )
        AND reconciliation_results.match_status <> 'DUPLICATE'
    )

UNION ALL

SELECT
    'amount_mismatch_difference_incorrect' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_results
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
JOIN internal_transactions
    ON reconciliation_results.internal_transaction_id = internal_transactions.internal_transaction_id
JOIN external_transactions
    ON reconciliation_results.external_transaction_id = external_transactions.external_transaction_id
WHERE exception_types.exception_code = 'AMOUNT_MISMATCH'
  AND (
        reconciliation_results.amount_difference IS NULL
        OR ABS(reconciliation_results.amount_difference)
            <> ABS(internal_transactions.amount - external_transactions.amount)
    )

UNION ALL

SELECT
    'date_mismatch_difference_incorrect' AS validation_check,
    COUNT(*) AS issue_count
FROM reconciliation_results
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
JOIN internal_transactions
    ON reconciliation_results.internal_transaction_id = internal_transactions.internal_transaction_id
JOIN external_transactions
    ON reconciliation_results.external_transaction_id = external_transactions.external_transaction_id
WHERE exception_types.exception_code = 'DATE_MISMATCH'
  AND (
        reconciliation_results.date_difference_days IS NULL
        OR reconciliation_results.date_difference_days
            <> ABS(internal_transactions.settlement_date - external_transactions.value_date)
    )

UNION ALL

SELECT
    'reference_mismatch_status_incorrect' AS validation_check,
    COUNT(*) AS issue_count
FROM vw_reconciliation_detail
WHERE vw_reconciliation_detail.exception_code = 'REFERENCE_MISMATCH'
  AND vw_reconciliation_detail.reference_status <> 'REFERENCE_MISMATCH'

ORDER BY validation_check;

-- ============================================================
-- 3. Detail checks: rows requiring investigation
-- These queries return detailed records only when something needs review.
-- ============================================================

-- Blank internal matching references.
SELECT
    internal_transactions.internal_transaction_id,
    internal_transactions.transaction_reference,
    internal_transactions.matching_reference
FROM internal_transactions
WHERE internal_transactions.matching_reference IS NULL
   OR TRIM(internal_transactions.matching_reference) = ''
ORDER BY internal_transactions.internal_transaction_id;

-- Blank external matching references.
SELECT
    external_transactions.external_transaction_id,
    external_transactions.external_reference,
    external_transactions.matching_reference
FROM external_transactions
WHERE external_transactions.matching_reference IS NULL
   OR TRIM(external_transactions.matching_reference) = ''
ORDER BY external_transactions.external_transaction_id;

-- Internal transactions where transaction fund and account fund do not align.
SELECT
    internal_transactions.internal_transaction_id,
    internal_transactions.fund_id AS transaction_fund_id,
    accounts.fund_id AS account_fund_id,
    internal_transactions.account_id,
    internal_transactions.transaction_reference
FROM internal_transactions
JOIN accounts
    ON internal_transactions.account_id = accounts.account_id
WHERE internal_transactions.fund_id <> accounts.fund_id
ORDER BY internal_transactions.internal_transaction_id;

-- Amount mismatch records where stored difference does not match actual difference.
SELECT
    reconciliation_results.reconciliation_result_id,
    internal_transactions.internal_transaction_id,
    external_transactions.external_transaction_id,
    internal_transactions.amount AS internal_amount,
    external_transactions.amount AS external_amount,
    reconciliation_results.amount_difference AS stored_amount_difference,
    ABS(internal_transactions.amount - external_transactions.amount) AS calculated_amount_difference
FROM reconciliation_results
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
JOIN internal_transactions
    ON reconciliation_results.internal_transaction_id = internal_transactions.internal_transaction_id
JOIN external_transactions
    ON reconciliation_results.external_transaction_id = external_transactions.external_transaction_id
WHERE exception_types.exception_code = 'AMOUNT_MISMATCH'
  AND (
        reconciliation_results.amount_difference IS NULL
        OR ABS(reconciliation_results.amount_difference)
            <> ABS(internal_transactions.amount - external_transactions.amount)
    )
ORDER BY reconciliation_results.reconciliation_result_id;

-- Date mismatch records where stored date difference does not match actual date difference.
SELECT
    reconciliation_results.reconciliation_result_id,
    internal_transactions.internal_transaction_id,
    external_transactions.external_transaction_id,
    internal_transactions.settlement_date,
    external_transactions.value_date,
    reconciliation_results.date_difference_days AS stored_date_difference_days,
    ABS(internal_transactions.settlement_date - external_transactions.value_date) AS calculated_date_difference_days
FROM reconciliation_results
JOIN exception_types
    ON reconciliation_results.exception_type_id = exception_types.exception_type_id
JOIN internal_transactions
    ON reconciliation_results.internal_transaction_id = internal_transactions.internal_transaction_id
JOIN external_transactions
    ON reconciliation_results.external_transaction_id = external_transactions.external_transaction_id
WHERE exception_types.exception_code = 'DATE_MISMATCH'
  AND (
        reconciliation_results.date_difference_days IS NULL
        OR reconciliation_results.date_difference_days
            <> ABS(internal_transactions.settlement_date - external_transactions.value_date)
    )
ORDER BY reconciliation_results.reconciliation_result_id;

-- ============================================================
-- 4. Operational control summary
-- These checks are not necessarily errors.
-- They show current reconciliation workload and risk areas.
-- ============================================================

WITH internal_duplicate_groups AS (
    SELECT
        internal_transactions.fund_id,
        internal_transactions.account_id,
        internal_transactions.transaction_reference,
        internal_transactions.matching_reference,
        internal_transactions.transaction_type,
        internal_transactions.direction,
        internal_transactions.currency_code,
        internal_transactions.amount,
        internal_transactions.settlement_date,
        COUNT(*) AS duplicate_count
    FROM internal_transactions
    GROUP BY
        internal_transactions.fund_id,
        internal_transactions.account_id,
        internal_transactions.transaction_reference,
        internal_transactions.matching_reference,
        internal_transactions.transaction_type,
        internal_transactions.direction,
        internal_transactions.currency_code,
        internal_transactions.amount,
        internal_transactions.settlement_date
    HAVING COUNT(*) > 1
),

external_duplicate_groups AS (
    SELECT
        external_transactions.account_id,
        external_transactions.external_reference,
        external_transactions.matching_reference,
        external_transactions.statement_reference,
        external_transactions.transaction_type,
        external_transactions.direction,
        external_transactions.currency_code,
        external_transactions.amount,
        external_transactions.value_date,
        COUNT(*) AS duplicate_count
    FROM external_transactions
    GROUP BY
        external_transactions.account_id,
        external_transactions.external_reference,
        external_transactions.matching_reference,
        external_transactions.statement_reference,
        external_transactions.transaction_type,
        external_transactions.direction,
        external_transactions.currency_code,
        external_transactions.amount,
        external_transactions.value_date
    HAVING COUNT(*) > 1
)

SELECT
    'open_or_escalated_breaks' AS control_check,
    COUNT(*) AS result_count
FROM vw_open_breaks

UNION ALL

SELECT
    'aged_exceptions' AS control_check,
    COUNT(*) AS result_count
FROM vw_aged_exceptions

UNION ALL

SELECT
    'high_priority_open_or_escalated_breaks' AS control_check,
    COUNT(*) AS result_count
FROM vw_open_breaks
WHERE vw_open_breaks.exception_priority = 'High'

UNION ALL

SELECT
    'reference_mismatches' AS control_check,
    COUNT(*) AS result_count
FROM vw_reconciliation_detail
WHERE vw_reconciliation_detail.exception_code = 'REFERENCE_MISMATCH'

UNION ALL

SELECT
    'internal_duplicate_groups' AS control_check,
    COUNT(*) AS result_count
FROM internal_duplicate_groups

UNION ALL

SELECT
    'external_duplicate_groups' AS control_check,
    COUNT(*) AS result_count
FROM external_duplicate_groups

ORDER BY control_check;

-- ============================================================
-- 5. Operational detail: prioritized open breaks
-- ============================================================

SELECT
    vw_open_breaks.reconciliation_result_id,
    vw_open_breaks.exception_code,
    vw_open_breaks.exception_priority,
    vw_open_breaks.break_status,
    vw_open_breaks.days_open,
    vw_open_breaks.fund_code,
    vw_open_breaks.account_number,
    vw_open_breaks.internal_reference,
    vw_open_breaks.external_reference,
    vw_open_breaks.reference_status,
    vw_open_breaks.internal_amount,
    vw_open_breaks.external_amount,
    vw_open_breaks.notes
FROM vw_open_breaks
ORDER BY
    CASE vw_open_breaks.exception_priority
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END,
    vw_open_breaks.days_open DESC,
    vw_open_breaks.reconciliation_result_id;

-- ============================================================
-- 6. Operational detail: aged exceptions ordered by severity
-- ============================================================

SELECT
    vw_aged_exceptions.reconciliation_result_id,
    vw_aged_exceptions.exception_code,
    vw_aged_exceptions.exception_priority,
    vw_aged_exceptions.break_status,
    vw_aged_exceptions.break_open_date,
    vw_aged_exceptions.days_open,
    vw_aged_exceptions.aging_threshold_days,
    vw_aged_exceptions.days_over_aging_threshold,
    vw_aged_exceptions.aging_bucket,
    vw_aged_exceptions.fund_code,
    vw_aged_exceptions.account_number,
    vw_aged_exceptions.internal_reference,
    vw_aged_exceptions.external_reference,
    vw_aged_exceptions.reference_status,
    vw_aged_exceptions.notes
FROM vw_aged_exceptions
ORDER BY
    vw_aged_exceptions.days_over_aging_threshold DESC,
    vw_aged_exceptions.reconciliation_result_id;