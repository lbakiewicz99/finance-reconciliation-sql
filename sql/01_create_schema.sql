-- ============================================================
-- Project: finance-reconciliation-sql
-- File: 01_create_schema.sql
-- Purpose: Create dedicated PostgreSQL schema for the project
-- ============================================================

-- Drop schema only if you want to fully reset the project database.
-- Keep this commented by default to avoid accidental data loss.
-- DROP SCHEMA IF EXISTS finance_recon CASCADE;

CREATE SCHEMA IF NOT EXISTS finance_recon;

-- Set default search path for the current session.
SET search_path TO finance_recon;