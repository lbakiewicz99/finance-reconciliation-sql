-- ============================================================
-- Project: finance-reconciliation-sql
-- File: 02_create_tables.sql
-- Purpose: Create relational tables for finance reconciliation
-- Database: PostgreSQL
-- ============================================================

SET search_path TO finance_recon;

-- ============================================================
-- Reference table: currencies
-- Stores currencies supported by the reconciliation process.
-- ============================================================

CREATE TABLE IF NOT EXISTS currencies (
    currency_code CHAR(3) PRIMARY KEY,
    currency_name VARCHAR(100) NOT NULL,
    decimal_places INTEGER NOT NULL DEFAULT 2,
    is_supported BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_currencies_decimal_places
        CHECK (decimal_places BETWEEN 0 AND 6)
);

-- ============================================================
-- Reference table: funds
-- Stores funds included in the reconciliation process.
-- ============================================================

CREATE TABLE IF NOT EXISTS funds (
    fund_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fund_code VARCHAR(50) NOT NULL UNIQUE,
    fund_name VARCHAR(255) NOT NULL,
    base_currency CHAR(3) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_funds_base_currency
        FOREIGN KEY (base_currency)
        REFERENCES currencies(currency_code)
);

-- ============================================================
-- Reference table: accounts
-- Stores cash, custody, settlement and PSP accounts.
-- ============================================================

CREATE TABLE IF NOT EXISTS accounts (
    account_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fund_id INTEGER NOT NULL,
    account_number VARCHAR(100) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_accounts_fund
        FOREIGN KEY (fund_id)
        REFERENCES funds(fund_id),

    CONSTRAINT fk_accounts_currency
        FOREIGN KEY (currency_code)
        REFERENCES currencies(currency_code),

    CONSTRAINT uq_accounts_fund_account_number
        UNIQUE (fund_id, account_number),

    CONSTRAINT chk_accounts_account_type
        CHECK (account_type IN (
            'CASH',
            'CUSTODY',
            'SETTLEMENT',
            'PSP',
            'FEE'
        ))
);

-- ============================================================
-- Transaction table: internal_transactions
-- Stores transactions from the internal finance / fund accounting system.
-- Amounts are stored as positive values. Direction indicates IN / OUT.
-- ============================================================

CREATE TABLE IF NOT EXISTS internal_transactions (
    internal_transaction_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fund_id INTEGER NOT NULL,
    account_id INTEGER NOT NULL,
    transaction_reference VARCHAR(100) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    amount NUMERIC(18, 2) NOT NULL,
    trade_date DATE,
    settlement_date DATE NOT NULL,
    booking_date DATE NOT NULL,
    source_system VARCHAR(100) NOT NULL DEFAULT 'Multifonds',
    transaction_status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_internal_transactions_fund
        FOREIGN KEY (fund_id)
        REFERENCES funds(fund_id),

    CONSTRAINT fk_internal_transactions_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id),

    CONSTRAINT fk_internal_transactions_currency
        FOREIGN KEY (currency_code)
        REFERENCES currencies(currency_code),

    CONSTRAINT chk_internal_transactions_amount
        CHECK (amount >= 0),

    CONSTRAINT chk_internal_transactions_direction
        CHECK (direction IN ('IN', 'OUT')),

    CONSTRAINT chk_internal_transactions_type
        CHECK (transaction_type IN (
            'SUBSCRIPTION',
            'REDEMPTION',
            'CASH_TRANSFER',
            'FEE',
            'INTEREST',
            'DIVIDEND',
            'CORPORATE_ACTION',
            'FX',
            'ADJUSTMENT'
        )),

    CONSTRAINT chk_internal_transactions_status
        CHECK (transaction_status IN (
            'BOOKED',
            'PENDING',
            'CANCELLED',
            'ADJUSTED'
        ))
);

-- ============================================================
-- Transaction table: external_transactions
-- Stores transactions from external statements.
-- Examples: bank statement, custodian statement, PSP file.
-- ============================================================

CREATE TABLE IF NOT EXISTS external_transactions (
    external_transaction_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id INTEGER NOT NULL,
    external_reference VARCHAR(100) NOT NULL,
    statement_reference VARCHAR(100) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    amount NUMERIC(18, 2) NOT NULL,
    value_date DATE NOT NULL,
    booking_date DATE NOT NULL,
    counterparty VARCHAR(255),
    statement_source VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_external_transactions_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id),

    CONSTRAINT fk_external_transactions_currency
        FOREIGN KEY (currency_code)
        REFERENCES currencies(currency_code),

    CONSTRAINT chk_external_transactions_amount
        CHECK (amount >= 0),

    CONSTRAINT chk_external_transactions_direction
        CHECK (direction IN ('IN', 'OUT')),

    CONSTRAINT chk_external_transactions_type
        CHECK (transaction_type IN (
            'SUBSCRIPTION',
            'REDEMPTION',
            'CASH_TRANSFER',
            'FEE',
            'INTEREST',
            'DIVIDEND',
            'CORPORATE_ACTION',
            'FX',
            'ADJUSTMENT'
        )),

    CONSTRAINT chk_external_statement_source
        CHECK (statement_source IN (
            'Bank',
            'Custodian',
            'PSP',
            'Broker',
            'Transfer Agent'
        ))
);

-- ============================================================
-- Process table: reconciliation_runs
-- Stores metadata about each reconciliation process execution.
-- ============================================================

CREATE TABLE IF NOT EXISTS reconciliation_runs (
    reconciliation_run_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    run_date DATE NOT NULL,
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,
    run_status VARCHAR(50) NOT NULL,
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_reconciliation_runs_period
        CHECK (period_start_date <= period_end_date),

    CONSTRAINT chk_reconciliation_runs_status
        CHECK (run_status IN (
            'STARTED',
            'COMPLETED',
            'FAILED',
            'REVIEWED'
        ))
);

-- ============================================================
-- Reference table: exception_types
-- Stores standardized reconciliation exception categories.
-- ============================================================

CREATE TABLE IF NOT EXISTS exception_types (
    exception_type_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    exception_code VARCHAR(100) NOT NULL UNIQUE,
    exception_name VARCHAR(255) NOT NULL,
    exception_description TEXT,
    exception_priority VARCHAR(50) NOT NULL,

    CONSTRAINT chk_exception_types_priority
        CHECK (priority IN (
            'Low',
            'Medium',
            'High'
        ))
);

-- ============================================================
-- Result table: reconciliation_results
-- Stores transaction-level reconciliation outcomes.
-- A result may link to:
-- - both internal and external transactions for matches/mismatches,
-- - only internal transaction for internal-only breaks,
-- - only external transaction for external-only breaks.
-- ============================================================

CREATE TABLE IF NOT EXISTS reconciliation_results (
    reconciliation_result_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reconciliation_run_id INTEGER NOT NULL,
    internal_transaction_id INTEGER,
    external_transaction_id INTEGER,
    exception_type_id INTEGER NOT NULL,
    match_status VARCHAR(50) NOT NULL,
    break_status VARCHAR(50) NOT NULL,
    break_open_date DATE,
    break_resolved_date DATE,
    amount_difference NUMERIC(18, 2),
    date_difference_days INTEGER,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reconciliation_results_run
        FOREIGN KEY (reconciliation_run_id)
        REFERENCES reconciliation_runs(reconciliation_run_id),

    CONSTRAINT fk_reconciliation_results_internal_transaction
        FOREIGN KEY (internal_transaction_id)
        REFERENCES internal_transactions(internal_transaction_id),

    CONSTRAINT fk_reconciliation_results_external_transaction
        FOREIGN KEY (external_transaction_id)
        REFERENCES external_transactions(external_transaction_id),

    CONSTRAINT fk_reconciliation_results_exception_type
        FOREIGN KEY (exception_type_id)
        REFERENCES exception_types(exception_type_id),

    CONSTRAINT chk_reconciliation_results_has_transaction
        CHECK (
            internal_transaction_id IS NOT NULL
            OR external_transaction_id IS NOT NULL
        ),

    CONSTRAINT chk_reconciliation_results_match_status
        CHECK (match_status IN (
            'MATCHED',
            'UNMATCHED',
            'MISMATCH',
            'DUPLICATE'
        )),

    CONSTRAINT chk_reconciliation_results_break_status
        CHECK (break_status IN (
            'NOT_APPLICABLE',
            'OPEN',
            'RESOLVED',
            'CLOSED_AS_TIMING',
            'CLOSED_AS_VALID',
            'ESCALATED'
        )),

    CONSTRAINT chk_reconciliation_results_break_dates
        CHECK (
            break_resolved_date IS NULL
            OR break_open_date IS NULL
            OR break_open_date <= break_resolved_date
        )
);

-- ============================================================
-- Action table: manual_adjustments
-- Stores manual actions used to resolve reconciliation breaks.
-- ============================================================

CREATE TABLE IF NOT EXISTS manual_adjustments (
    manual_adjustment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reconciliation_result_id INTEGER NOT NULL,
    adjustment_date DATE NOT NULL,
    adjustment_type VARCHAR(100) NOT NULL,
    adjustment_amount NUMERIC(18, 2),
    adjustment_reason TEXT NOT NULL,
    adjusted_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_manual_adjustments_reconciliation_result
        FOREIGN KEY (reconciliation_result_id)
        REFERENCES reconciliation_results(reconciliation_result_id),

    CONSTRAINT chk_manual_adjustments_amount
        CHECK (
            adjustment_amount IS NULL
            OR adjustment_amount >= 0
        ),

    CONSTRAINT chk_manual_adjustments_type
        CHECK (adjustment_type IN (
            'INTERNAL_BOOKING_CORRECTION',
            'EXTERNAL_REFERENCE_UPDATE',
            'DATE_CORRECTION',
            'AMOUNT_CORRECTION',
            'MANUAL_MATCH',
            'TIMING_DIFFERENCE_CONFIRMED',
            'WRITE_OFF',
            'OTHER'
        ))
);