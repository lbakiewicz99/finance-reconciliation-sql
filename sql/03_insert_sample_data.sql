-- ============================================================
-- Project: finance-reconciliation-sql
-- File: 03_insert_sample_data.sql
-- Purpose: Insert realistic sample data for finance reconciliation
-- Database: PostgreSQL
-- ============================================================

SET search_path TO finance_recon;

-- ============================================================
-- Reset sample data
-- WARNING: This removes existing records from project tables.
-- ============================================================

TRUNCATE TABLE
    manual_adjustments,
    reconciliation_results,
    exception_types,
    reconciliation_runs,
    external_transactions,
    internal_transactions,
    accounts,
    funds,
    currencies
RESTART IDENTITY CASCADE;

-- ============================================================
-- Reference data: currencies
-- ============================================================

INSERT INTO currencies (
    currency_code,
    currency_name,
    decimal_places,
    is_supported
)
VALUES
    ('USD', 'US Dollar', 2, TRUE),
    ('EUR', 'Euro', 2, TRUE),
    ('GBP', 'British Pound', 2, TRUE),
    ('CHF', 'Swiss Franc', 2, FALSE);

-- ============================================================
-- Reference data: funds
-- ============================================================

INSERT INTO funds (
    fund_id,
    fund_code,
    fund_name,
    base_currency,
    is_active
)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'FND_GBL_EQ', 'Global Equity Fund', 'USD', TRUE),
    (2, 'FND_EUR_BND', 'European Bond Fund', 'EUR', TRUE),
    (3, 'FND_UK_INC', 'UK Income Fund', 'GBP', TRUE);

-- ============================================================
-- Reference data: accounts
-- ============================================================

INSERT INTO accounts (
    account_id,
    fund_id,
    account_number,
    account_name,
    account_type,
    currency_code,
    is_active
)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 'ACC-USD-001', 'Global Equity USD Cash Account', 'CASH', 'USD', TRUE),
    (2, 1, 'ACC-EUR-001', 'Global Equity EUR Cash Account', 'CASH', 'EUR', TRUE),
    (3, 2, 'ACC-EUR-002', 'European Bond EUR Cash Account', 'CASH', 'EUR', TRUE),
    (4, 3, 'ACC-GBP-001', 'UK Income GBP Cash Account', 'CASH', 'GBP', TRUE),
    (5, 1, 'ACC-USD-PSP', 'Global Equity USD PSP Account', 'PSP', 'USD', TRUE);

-- ============================================================
-- Reference data: exception types
-- ============================================================

INSERT INTO exception_types (
    exception_type_id,
    exception_code,
    exception_name,
    exception_description,
    exception_priority
)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'MATCHED', 'Matched transaction', 'Internal and external records fully match.', 'Low'),
    (2, 'UNMATCHED_INTERNAL', 'Unmatched internal transaction', 'Internal record has no matching external record.', 'Medium'),
    (3, 'UNMATCHED_EXTERNAL', 'Unmatched external transaction', 'External record has no matching internal record.', 'High'),
    (4, 'AMOUNT_MISMATCH', 'Amount mismatch', 'Internal and external amounts differ.', 'High'),
    (5, 'DATE_MISMATCH', 'Date mismatch', 'Internal settlement date and external value date differ.', 'Medium'),
    (6, 'CURRENCY_MISMATCH', 'Currency mismatch', 'Internal and external currencies differ.', 'High'),
    (7, 'DUPLICATE_INTERNAL', 'Duplicate internal transaction', 'Duplicate transaction detected in internal records.', 'Medium'),
    (8, 'DUPLICATE_EXTERNAL', 'Duplicate external transaction', 'Duplicate transaction detected in external records.', 'Medium'),
    (9, 'AGED_OPEN_BREAK', 'Aged open break', 'Unresolved break older than the defined aging threshold.', 'High');

-- ============================================================
-- Process data: reconciliation runs
-- ============================================================

INSERT INTO reconciliation_runs (
    reconciliation_run_id,
    run_date,
    period_start_date,
    period_end_date,
    run_status,
    created_by
)
OVERRIDING SYSTEM VALUE
VALUES
    (1, '2025-01-31', '2025-01-01', '2025-01-31', 'COMPLETED', 'operations_analyst'),
    (2, '2025-02-28', '2025-02-01', '2025-02-28', 'COMPLETED', 'operations_analyst');

-- ============================================================
-- Transaction data: internal transactions
-- ============================================================

INSERT INTO internal_transactions (
    internal_transaction_id,
    fund_id,
    account_id,
    transaction_reference,
    transaction_type,
    direction,
    currency_code,
    amount,
    trade_date,
    settlement_date,
    booking_date,
    source_system,
    transaction_status
)
OVERRIDING SYSTEM VALUE
VALUES
    -- Exact match
    (1001, 1, 1, 'TXN-2025-0001', 'SUBSCRIPTION', 'IN', 'USD', 125000.00, '2025-01-14', '2025-01-15', '2025-01-15', 'Multifonds', 'BOOKED'),

    -- Exact match
    (1002, 2, 3, 'TXN-2025-0002', 'REDEMPTION', 'OUT', 'EUR', 50000.00, '2025-01-15', '2025-01-16', '2025-01-16', 'Multifonds', 'BOOKED'),

    -- Internal only
    (1003, 1, 1, 'TXN-2025-0003', 'FEE', 'OUT', 'USD', 750.00, '2025-01-16', '2025-01-17', '2025-01-17', 'Multifonds', 'BOOKED'),

    -- Amount mismatch
    (1004, 1, 5, 'TXN-2025-0004', 'SUBSCRIPTION', 'IN', 'USD', 10000.00, '2025-01-17', '2025-01-20', '2025-01-20', 'Multifonds', 'BOOKED'),

    -- Date mismatch
    (1005, 3, 4, 'TXN-2025-0005', 'DIVIDEND', 'IN', 'GBP', 2500.00, '2025-01-18', '2025-01-20', '2025-01-20', 'Multifonds', 'BOOKED'),

    -- Currency mismatch
    (1006, 1, 2, 'TXN-2025-0006', 'CASH_TRANSFER', 'IN', 'EUR', 3000.00, '2025-01-21', '2025-01-22', '2025-01-22', 'Multifonds', 'BOOKED'),

    -- Duplicate internal records
    (1007, 2, 3, 'TXN-2025-0007', 'INTEREST', 'IN', 'EUR', 125.50, '2025-01-23', '2025-01-24', '2025-01-24', 'Multifonds', 'BOOKED'),
    (1008, 2, 3, 'TXN-2025-0007', 'INTEREST', 'IN', 'EUR', 125.50, '2025-01-23', '2025-01-24', '2025-01-24', 'Multifonds', 'BOOKED'),

    -- Aged open break
    (1009, 1, 1, 'TXN-2025-0008', 'CASH_TRANSFER', 'OUT', 'USD', 45000.00, '2025-01-05', '2025-01-06', '2025-01-06', 'Multifonds', 'BOOKED'),

    -- February exact match
    (1010, 3, 4, 'TXN-2025-0009', 'SUBSCRIPTION', 'IN', 'GBP', 15000.00, '2025-02-10', '2025-02-11', '2025-02-11', 'Multifonds', 'BOOKED');

-- ============================================================
-- Transaction data: external transactions
-- ============================================================

INSERT INTO external_transactions (
    external_transaction_id,
    account_id,
    external_reference,
    statement_reference,
    transaction_type,
    direction,
    currency_code,
    amount,
    value_date,
    booking_date,
    counterparty,
    statement_source
)
OVERRIDING SYSTEM VALUE
VALUES
    -- Exact match for 1001
    (5001, 1, 'TXN-2025-0001', 'BNK-STMT-20250115-001', 'SUBSCRIPTION', 'IN', 'USD', 125000.00, '2025-01-15', '2025-01-15', 'Investor A', 'Bank'),

    -- Exact match for 1002
    (5002, 3, 'TXN-2025-0002', 'CUST-STMT-20250116-001', 'REDEMPTION', 'OUT', 'EUR', 50000.00, '2025-01-16', '2025-01-16', 'Investor B', 'Custodian'),

    -- External only
    (5003, 1, 'TXN-2025-EXT1', 'BNK-STMT-20250117-001', 'FEE', 'OUT', 'USD', 120.00, '2025-01-17', '2025-01-17', 'Bank Fee', 'Bank'),

    -- Amount mismatch for 1004
    (5004, 5, 'TXN-2025-0004', 'PSP-STMT-20250120-001', 'SUBSCRIPTION', 'IN', 'USD', 9995.00, '2025-01-20', '2025-01-20', 'Investor C', 'PSP'),

    -- Date mismatch for 1005
    (5005, 4, 'TXN-2025-0005', 'BNK-STMT-20250121-001', 'DIVIDEND', 'IN', 'GBP', 2500.00, '2025-01-21', '2025-01-21', 'Dividend Agent', 'Bank'),

    -- Currency mismatch for 1006
    (5006, 2, 'TXN-2025-0006', 'BNK-STMT-20250122-001', 'CASH_TRANSFER', 'IN', 'USD', 3000.00, '2025-01-22', '2025-01-22', 'Treasury Transfer', 'Bank'),

    -- External record matching duplicated internal records
    (5007, 3, 'TXN-2025-0007', 'CUST-STMT-20250124-001', 'INTEREST', 'IN', 'EUR', 125.50, '2025-01-24', '2025-01-24', 'Custodian Interest', 'Custodian'),

    -- Duplicate external records
    (5008, 1, 'TXN-2025-EXT2', 'BNK-STMT-20250125-001', 'FEE', 'OUT', 'USD', 35.00, '2025-01-25', '2025-01-25', 'Bank Fee', 'Bank'),
    (5009, 1, 'TXN-2025-EXT2', 'BNK-STMT-20250125-001', 'FEE', 'OUT', 'USD', 35.00, '2025-01-25', '2025-01-25', 'Bank Fee', 'Bank'),

    -- February exact match
    (5010, 4, 'TXN-2025-0009', 'BNK-STMT-20250211-001', 'SUBSCRIPTION', 'IN', 'GBP', 15000.00, '2025-02-11', '2025-02-11', 'Investor D', 'Bank');

-- ============================================================
-- Reconciliation results
-- These rows simulate transaction-level reconciliation outcomes.
-- ============================================================

INSERT INTO reconciliation_results (
    reconciliation_result_id,
    reconciliation_run_id,
    internal_transaction_id,
    external_transaction_id,
    exception_type_id,
    match_status,
    break_status,
    break_open_date,
    break_resolved_date,
    amount_difference,
    date_difference_days,
    notes
)
OVERRIDING SYSTEM VALUE
VALUES
    -- Exact matches
    (1, 1, 1001, 5001, 1, 'MATCHED', 'NOT_APPLICABLE', NULL, NULL, 0.00, 0, 'Exact match.'),
    (2, 1, 1002, 5002, 1, 'MATCHED', 'NOT_APPLICABLE', NULL, NULL, 0.00, 0, 'Exact match.'),

    -- Internal only
    (3, 1, 1003, NULL, 2, 'UNMATCHED', 'OPEN', '2025-01-31', NULL, NULL, NULL, 'Internal fee booking missing from external bank statement.'),

    -- External only
    (4, 1, NULL, 5003, 3, 'UNMATCHED', 'RESOLVED', '2025-01-31', '2025-02-02', NULL, NULL, 'External bank fee later confirmed and booked internally.'),

    -- Amount mismatch
    (5, 1, 1004, 5004, 4, 'MISMATCH', 'RESOLVED', '2025-01-31', '2025-02-01', 5.00, 0, 'External PSP amount is lower due to processing fee.'),

    -- Date mismatch
    (6, 1, 1005, 5005, 5, 'MISMATCH', 'CLOSED_AS_TIMING', '2025-01-31', '2025-02-01', 0.00, 1, 'One-day value date difference confirmed as timing issue.'),

    -- Currency mismatch
    (7, 1, 1006, 5006, 6, 'MISMATCH', 'ESCALATED', '2025-01-31', NULL, 0.00, 0, 'Currency differs between internal and external records.'),

    -- Duplicate internal
    (8, 1, 1007, 5007, 7, 'DUPLICATE', 'OPEN', '2025-01-31', NULL, 0.00, 0, 'Duplicate internal interest transaction detected.'),
    (9, 1, 1008, 5007, 7, 'DUPLICATE', 'OPEN', '2025-01-31', NULL, 0.00, 0, 'Duplicate internal interest transaction detected.'),

    -- Aged open break
    (10, 1, 1009, NULL, 9, 'UNMATCHED', 'OPEN', '2025-01-06', NULL, NULL, NULL, 'Aged open internal cash transfer break.'),

    -- Duplicate external
    (11, 1, NULL, 5008, 8, 'DUPLICATE', 'OPEN', '2025-01-31', NULL, NULL, NULL, 'Duplicate external bank fee statement line detected.'),
    (12, 1, NULL, 5009, 8, 'DUPLICATE', 'OPEN', '2025-01-31', NULL, NULL, NULL, 'Duplicate external bank fee statement line detected.'),

    -- February exact match
    (13, 2, 1010, 5010, 1, 'MATCHED', 'NOT_APPLICABLE', NULL, NULL, 0.00, 0, 'Exact match.');

-- ============================================================
-- Manual adjustments
-- ============================================================

INSERT INTO manual_adjustments (
    manual_adjustment_id,
    reconciliation_result_id,
    adjustment_date,
    adjustment_type,
    adjustment_amount,
    adjustment_reason,
    adjusted_by
)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 4, '2025-02-02', 'INTERNAL_BOOKING_CORRECTION', 120.00, 'Bank fee was posted externally and later booked internally.', 'operations_analyst'),
    (2, 5, '2025-02-01', 'AMOUNT_CORRECTION', 5.00, 'PSP processing fee difference was confirmed and adjusted.', 'operations_analyst'),
    (3, 6, '2025-02-01', 'TIMING_DIFFERENCE_CONFIRMED', NULL, 'One-day date difference confirmed as valid timing difference.', 'operations_analyst');