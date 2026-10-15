-- =====================================================================
-- setup/04_dbt.sql
-- Run as : ACCOUNTADMIN (the script switches roles itself)
-- Needs  : setup/01, 02 done
-- Re-run : safe
-- Purpose: let each deployer create its own dbt project object
--          INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_<ENV>_DBT
--   DEV   : created by data engineers (scripts/dbt_dev.sql)
--   STAGE / PROD : created and updated by the pipeline (step 7)
-- =====================================================================

USE ROLE SYSADMIN;
GRANT CREATE DBT PROJECT ON SCHEMA INFOJINI_ADMIN_DB.PROJECTS TO ROLE INFOJINI_DEV_DEPLOYER;
GRANT CREATE DBT PROJECT ON SCHEMA INFOJINI_ADMIN_DB.PROJECTS TO ROLE INFOJINI_STAGE_DEPLOYER;
GRANT CREATE DBT PROJECT ON SCHEMA INFOJINI_ADMIN_DB.PROJECTS TO ROLE INFOJINI_PROD_DEPLOYER;

SHOW GRANTS ON SCHEMA INFOJINI_ADMIN_DB.PROJECTS;   -- expect CREATE DBT PROJECT for the 3 deployers
