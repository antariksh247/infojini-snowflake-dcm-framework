-- =====================================================================
-- platform/06_dev_playground.sql
-- Run as : ACCOUNTADMIN (the script switches roles itself)
-- Needs  : platform/01_platform.sql done
-- Re-run : safe (IF NOT EXISTS everywhere; never touches existing objects)
-- Purpose: the DEV playground = free development environment.
--   - NOT managed by DCM: developers create / change objects by hand
--     (worksheets, CREATE OR REPLACE ...) and run dbt with --target dev.
--   - Same database / schema / warehouse names as STAGE / PROD with DEV in the name,
--     so code written here moves to the repo with only the names swapped.
--   - Owned by INFOJINI_DEV_DEPLOYER, which data engineers inherit.
-- =====================================================================

USE ROLE INFOJINI_DEV_DEPLOYER;
USE WAREHOUSE INFOJINI_ADMIN_WH;

CREATE WAREHOUSE IF NOT EXISTS INFOJINI_DEV_TRANSFORM_WH
  WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE
  COMMENT = 'INFOJINI DEV playground warehouse';

CREATE DATABASE IF NOT EXISTS INFOJINI_DEV_SILVER_DB DATA_RETENTION_TIME_IN_DAYS = 1
  COMMENT = 'INFOJINI DEV playground - Silver (not managed by DCM)';
CREATE SCHEMA IF NOT EXISTS INFOJINI_DEV_SILVER_DB.STAGING;
CREATE SCHEMA IF NOT EXISTS INFOJINI_DEV_SILVER_DB.CORE;

CREATE DATABASE IF NOT EXISTS INFOJINI_DEV_GOLD_DB DATA_RETENTION_TIME_IN_DAYS = 1
  COMMENT = 'INFOJINI DEV playground - Gold (not managed by DCM)';
CREATE SCHEMA IF NOT EXISTS INFOJINI_DEV_GOLD_DB.MART;
CREATE SCHEMA IF NOT EXISTS INFOJINI_DEV_GOLD_DB.APP;

-- Database roles so the dbt post-hooks (grant_read / grant_app) also work in DEV
CREATE DATABASE ROLE IF NOT EXISTS INFOJINI_DEV_SILVER_DB.READ;
CREATE DATABASE ROLE IF NOT EXISTS INFOJINI_DEV_GOLD_DB.READ;
CREATE DATABASE ROLE IF NOT EXISTS INFOJINI_DEV_GOLD_DB.APP;

-- Scientists can read DEV
GRANT USAGE ON WAREHOUSE INFOJINI_DEV_TRANSFORM_WH TO ROLE INFOJINI_DATA_SCIENTIST;
GRANT DATABASE ROLE INFOJINI_DEV_SILVER_DB.READ TO ROLE INFOJINI_DATA_SCIENTIST;
GRANT DATABASE ROLE INFOJINI_DEV_GOLD_DB.READ   TO ROLE INFOJINI_DATA_SCIENTIST;

-- Checks
SHOW DATABASES LIKE 'INFOJINI_DEV%';     -- SILVER_DB, GOLD_DB
SHOW WAREHOUSES LIKE 'INFOJINI_DEV%';    -- TRANSFORM_WH
