-- =====================================================================
-- scripts/dbt_dev.sql
-- Run as : your user (needs INFOJINI_DEV_DEPLOYER, e.g. via DATA_ENGINEER)
-- When   : after DCM deploy to DEV (dbt always runs AFTER DCM)
-- Purpose: deploy the dbt project to DEV from the Git repo and run it.
--          STAGE / PROD do the same through GitHub Actions (step 7).
-- =====================================================================

USE ROLE SYSADMIN;
ALTER GIT REPOSITORY INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO FETCH;   -- latest commits

USE ROLE INFOJINI_DEV_DEPLOYER;
USE WAREHOUSE INFOJINI_DEV_TRANSFORM_WH;

-- 1. Create the dbt project object once (later runs: the ALTER below)
CREATE DBT PROJECT IF NOT EXISTS INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_DEV_DBT
  FROM '@INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO/branches/main/sources/dbt/infojini'
  DEFAULT_TARGET = 'dev'
  COMMENT = 'INFOJINI dbt models - DEV';

-- 2. Pick up new commits (replaces the project files with the latest from main)
ALTER DBT PROJECT INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_DEV_DBT
  DEPLOY
  FROM '@INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO/branches/main/sources/dbt/infojini';

-- 3. Build = run models + tests
EXECUTE DBT PROJECT INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_DEV_DBT
  ARGS = 'build --target dev';

-- Checks
SHOW VIEWS  IN SCHEMA INFOJINI_DEV_SILVER_DB.STAGING;   -- STG_CUSTOMERS, STG_ORDERS, STG_PRODUCTS
SHOW TABLES IN SCHEMA INFOJINI_DEV_GOLD_DB.MART;        -- DIM_CUSTOMERS, FCT_ORDERS
SELECT * FROM INFOJINI_DEV_GOLD_DB.MART.FCT_ORDERS;     -- 6 rows

USE ROLE INFOJINI_DATA_SCIENTIST;                       -- READ role sees dbt tables (post-hook grant)
SELECT COUNT(*) FROM INFOJINI_DEV_GOLD_DB.MART.DIM_CUSTOMERS;   -- 5
