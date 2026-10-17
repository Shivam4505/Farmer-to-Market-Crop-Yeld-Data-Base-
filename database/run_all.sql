-- ============================================================================
-- FARMER-TO-MARKET CROP YIELD & PRICING DATABASE
-- ADBMS Mini-Project — Master Execution Script
-- Script: run_all.sql
-- Description: Executes all Stage 1 SQL scripts in correct dependency order.
-- ============================================================================

SET ECHO OFF;
SET FEEDBACK ON;
SET SERVEROUTPUT ON;

PROMPT ================================================================================
PROMPT STEP 1: Creating Tables & Core EER Specialization Schema...
PROMPT ================================================================================
@@01_create_tables.sql;

PROMPT ================================================================================
PROMPT STEP 2: Creating Foreign Key Indexes & Performance Constraints...
PROMPT ================================================================================
@@02_constraints_indexes.sql;

PROMPT ================================================================================
PROMPT STEP 3: Creating PL/SQL Triggers (trg_validate_harvest, trg_price_alert)...
PROMPT ================================================================================
@@03_create_triggers.sql;

PROMPT ================================================================================
PROMPT STEP 4: Creating Stored Procedures, Functions, and Cursors...
PROMPT ================================================================================
@@04_create_procedures_functions.sql;

PROMPT ================================================================================
PROMPT STEP 5: Creating Analytical Views & Distributed Fragmentation Simulation...
PROMPT ================================================================================
@@05_create_views.sql;

PROMPT ================================================================================
PROMPT STEP 6: Seeding Comprehensive Sample Data & 30-Day Prices...
PROMPT ================================================================================
@@06_sample_data.sql;

PROMPT ================================================================================
PROMPT STEP 7: Executing Demonstration & Analytical Queries...
PROMPT ================================================================================
@@07_demo_queries.sql;

PROMPT ================================================================================
PROMPT STEP 8: Running Automated Test Suite & Generating Test Report...
PROMPT ================================================================================
@@08_test_cases.sql;

PROMPT ================================================================================
PROMPT STAGE 1 ORACLE DATABASE SETUP AND VERIFICATION COMPLETE!
PROMPT ================================================================================
