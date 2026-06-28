Project Overview

finance-reconciliation-sql is a SQL portfolio project that simulates a real-world reconciliation process between internal fund accounting records and external financial statements received from a bank, custodian or payment service provider.

The project is designed to demonstrate how SQL can be used to identify matched transactions, operational breaks, mismatches, duplicates and unresolved exceptions in a finance operations environment.

Business Context

Financial institutions, asset servicers and fund accounting teams rely on daily reconciliation processes to ensure that transactions recorded in internal systems are consistent with external records provided by banks, custodians or payment providers.

In a typical finance operations process, internal systems may contain records related to:

subscriptions and redemptions,
cash transfers,
settlement movements,
fees,
interest,
corporate actions,
payments,
fund accounting adjustments.

External statement files may come from:

banks,
custodians,
payment service providers,
brokers,
transfer agents,
other third-party platforms.

The reconciliation process helps confirm whether all expected transactions have been correctly processed, settled and recorded.

Business Problem

Differences between internal and external records can create operational risk, reporting issues and delays in financial close processes.

Common reconciliation issues include:

transactions recorded internally but missing from the external statement,
transactions present externally but not booked internally,
amount mismatches,
settlement date or value date mismatches,
duplicate records,
incorrect account mapping,
currency mismatches,
unresolved breaks that remain open for several business days.

These exceptions need to be identified, classified, investigated and resolved.

Project Objective

The objective of this project is to build a PostgreSQL-based reconciliation model that can:

store internal and external transaction records,
compare records using defined reconciliation rules,
identify matched and unmatched transactions,
classify reconciliation exceptions,
track reconciliation runs,
report open and resolved breaks,
calculate reconciliation accuracy,
provide monthly reconciliation summaries.
Scope

The project focuses on SQL-based reconciliation logic and reporting.

The initial scope includes:

relational database design,
realistic sample data,
transaction matching logic,
exception detection,
reporting views,
business-focused documentation.

The project does not initially include:

application UI,
automated file ingestion,
Python pipelines,
dashboarding tools,
Docker deployment.

These may be added later as optional enhancements.

Key Business Questions

The reconciliation process should help answer the following questions:

Which transactions are fully matched between internal and external records?
Which internal transactions are missing from the external statement?
Which external transactions are missing from the internal system?
Are there any amount mismatches?
Are there any date mismatches?
Are duplicate records present in either data source?
Which reconciliation breaks are still unresolved?
How old are the open breaks?
What are the most common exception types?
What is the monthly reconciliation accuracy?


A well-designed reconciliation process helps reduce operational risk by identifying discrepancies early and providing a structured way to investigate and resolve them.

This project demonstrates how SQL can support:

daily operational controls,
exception management,
financial data validation,
reporting accuracy,
process monitoring,
business analysis,
auditability of reconciliation outcomes.
Portfolio Relevance

This project is intended to demonstrate practical SQL skills in a finance operations context.

It combines:

relational data modelling,
SQL joins and aggregations,
exception logic,
operational reporting,
data quality checks,
business-oriented documentation.

The goal is to show not only technical SQL ability, but also an understanding of how reconciliation supports real financial operations.