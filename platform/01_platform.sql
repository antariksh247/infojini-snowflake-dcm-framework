-- =====================================================================
-- platform/01_platform.sql
-- Run as : ACCOUNTADMIN (the script switches roles itself)
-- Re-run : safe
-- Purpose: one-time platform setup for project INFOJINI (outside DCM)
--   - cost guard
--   - account roles: deployers, loader, functional roles (incl. INFOJINI_DATA_ADMIN)
--   - visibility grants so the data admin can debug STAGE/PROD deploys
--   - admin database (DCM project objects + Git integration live here)
--   - admin + load warehouses
--   - privileges the deployer roles need to run DCM
--   - the 2 DCM project objects: INFOJINI_STAGE / INFOJINI_PROD
--     (DEV is a free playground, not managed by DCM: platform/06_dev_playground.sql)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Cost guard (trial): suspend all warehouses at 30 credits / month
-- ---------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

CREATE RESOURCE MONITOR IF NOT EXISTS INFOJINI_RM
  WITH CREDIT_QUOTA = 30
       FREQUENCY = MONTHLY
       START_TIMESTAMP = IMMEDIATELY
  TRIGGERS ON 75 PERCENT DO NOTIFY
           ON 100 PERCENT DO SUSPEND;

ALTER ACCOUNT SET RESOURCE_MONITOR = INFOJINI_RM;

-- ---------------------------------------------------------------------
-- 2. Account roles
-- ---------------------------------------------------------------------
USE ROLE SECURITYADMIN;

-- Deployers: own everything DCM creates in their environment
CREATE ROLE IF NOT EXISTS INFOJINI_DEV_DEPLOYER   COMMENT = 'Owns the INFOJINI DEV playground. Held by data engineers';
CREATE ROLE IF NOT EXISTS INFOJINI_STAGE_DEPLOYER COMMENT = 'Owns INFOJINI STAGE objects. Held only by the CI service user';
CREATE ROLE IF NOT EXISTS INFOJINI_PROD_DEPLOYER  COMMENT = 'Owns INFOJINI PROD objects. Held only by the CI service user';

-- System role for ingestion (writes Bronze)
CREATE ROLE IF NOT EXISTS INFOJINI_LOADER         COMMENT = 'Writes INFOJINI Bronze (Fivetran / share / loads)';

-- Functional roles: held by people (or BI / app service users)
CREATE ROLE IF NOT EXISTS INFOJINI_DATA_ADMIN     COMMENT = 'Project lead: DEV + full visibility of STAGE/PROD deploys, no STAGE/PROD deploy rights';
CREATE ROLE IF NOT EXISTS INFOJINI_DATA_ENGINEER  COMMENT = 'Builds in DEV, reads STAGE / PROD';
CREATE ROLE IF NOT EXISTS INFOJINI_DATA_SCIENTIST COMMENT = 'Reads data, own sandbox in DEV';
CREATE ROLE IF NOT EXISTS INFOJINI_ANALYST        COMMENT = 'Reads Gold in STAGE / PROD';
CREATE ROLE IF NOT EXISTS INFOJINI_BI_SERVICE     COMMENT = 'Power BI / BI tools: reads PROD Gold';
CREATE ROLE IF NOT EXISTS INFOJINI_APP_USER       COMMENT = 'Uses the Streamlit app';

-- Hierarchy
--   data engineers own the DEV playground (create / change anything there)
--   data admin can do everything a data engineer can
GRANT ROLE INFOJINI_DEV_DEPLOYER  TO ROLE INFOJINI_DATA_ENGINEER;
GRANT ROLE INFOJINI_DATA_ENGINEER TO ROLE INFOJINI_DATA_ADMIN;

-- Functional and loader roles roll up to SYSADMIN.
-- STAGE / PROD deployers do NOT: no person should inherit them.
GRANT ROLE INFOJINI_DATA_ADMIN     TO ROLE SYSADMIN;
GRANT ROLE INFOJINI_DATA_SCIENTIST TO ROLE SYSADMIN;
GRANT ROLE INFOJINI_ANALYST        TO ROLE SYSADMIN;
GRANT ROLE INFOJINI_BI_SERVICE     TO ROLE SYSADMIN;
GRANT ROLE INFOJINI_APP_USER       TO ROLE SYSADMIN;
GRANT ROLE INFOJINI_LOADER         TO ROLE SYSADMIN;

-- ---------------------------------------------------------------------
-- 3. Admin database + warehouses
-- ---------------------------------------------------------------------
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS INFOJINI_ADMIN_DB COMMENT = 'INFOJINI platform: DCM project objects, Git integration';
CREATE SCHEMA IF NOT EXISTS INFOJINI_ADMIN_DB.PROJECTS     COMMENT = 'DCM project objects (one per environment)';
CREATE SCHEMA IF NOT EXISTS INFOJINI_ADMIN_DB.INTEGRATIONS COMMENT = 'Git repository object and secrets';
DROP SCHEMA IF EXISTS INFOJINI_ADMIN_DB.PUBLIC;

CREATE WAREHOUSE IF NOT EXISTS INFOJINI_ADMIN_WH
  WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE
  COMMENT = 'DCM plan / deploy and CI';

CREATE WAREHOUSE IF NOT EXISTS INFOJINI_LOAD_WH
  WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Bronze loading (simulates Fivetran in the POC)';

-- ---------------------------------------------------------------------
-- 4. What the deployer roles need to run DCM
-- ---------------------------------------------------------------------
-- Admin database: create the DCM project object; CREATE STAGE is used by
-- Snowflake CLI to upload project files during plan / deploy
GRANT USAGE ON DATABASE INFOJINI_ADMIN_DB TO ROLE INFOJINI_DEV_DEPLOYER;
GRANT USAGE ON DATABASE INFOJINI_ADMIN_DB TO ROLE INFOJINI_STAGE_DEPLOYER;
GRANT USAGE ON DATABASE INFOJINI_ADMIN_DB TO ROLE INFOJINI_PROD_DEPLOYER;

GRANT USAGE, CREATE STAGE ON SCHEMA INFOJINI_ADMIN_DB.PROJECTS TO ROLE INFOJINI_DEV_DEPLOYER;
GRANT USAGE, CREATE DCM PROJECT, CREATE STAGE ON SCHEMA INFOJINI_ADMIN_DB.PROJECTS TO ROLE INFOJINI_STAGE_DEPLOYER;
GRANT USAGE, CREATE DCM PROJECT, CREATE STAGE ON SCHEMA INFOJINI_ADMIN_DB.PROJECTS TO ROLE INFOJINI_PROD_DEPLOYER;

GRANT USAGE ON SCHEMA INFOJINI_ADMIN_DB.INTEGRATIONS TO ROLE INFOJINI_DEV_DEPLOYER;
GRANT USAGE ON SCHEMA INFOJINI_ADMIN_DB.INTEGRATIONS TO ROLE INFOJINI_STAGE_DEPLOYER;
GRANT USAGE ON SCHEMA INFOJINI_ADMIN_DB.INTEGRATIONS TO ROLE INFOJINI_PROD_DEPLOYER;

-- Read the admin database (see DCM projects, deployment history)
GRANT USAGE ON DATABASE INFOJINI_ADMIN_DB         TO ROLE INFOJINI_DATA_ENGINEER;
GRANT USAGE ON SCHEMA INFOJINI_ADMIN_DB.PROJECTS  TO ROLE INFOJINI_DATA_ENGINEER;

-- Warehouses
GRANT USAGE, MONITOR ON WAREHOUSE INFOJINI_ADMIN_WH TO ROLE INFOJINI_DEV_DEPLOYER;
GRANT USAGE, MONITOR ON WAREHOUSE INFOJINI_ADMIN_WH TO ROLE INFOJINI_STAGE_DEPLOYER;
GRANT USAGE, MONITOR ON WAREHOUSE INFOJINI_ADMIN_WH TO ROLE INFOJINI_PROD_DEPLOYER;
GRANT USAGE ON WAREHOUSE INFOJINI_LOAD_WH TO ROLE INFOJINI_LOADER;

-- Account-level: DCM creates databases + warehouses, tasks must be able to run
USE ROLE ACCOUNTADMIN;
GRANT CREATE DATABASE, CREATE WAREHOUSE, EXECUTE TASK ON ACCOUNT TO ROLE INFOJINI_DEV_DEPLOYER;
GRANT CREATE DATABASE, CREATE WAREHOUSE, EXECUTE TASK ON ACCOUNT TO ROLE INFOJINI_STAGE_DEPLOYER;
GRANT CREATE DATABASE, CREATE WAREHOUSE, EXECUTE TASK ON ACCOUNT TO ROLE INFOJINI_PROD_DEPLOYER;

-- ---------------------------------------------------------------------
-- 5. Visibility for the data admin (debug failed pipelines without deploy rights)
--    - MONITOR EXECUTION : task runs / history of every task in the account
--    - USAGE_VIEWER      : ACCOUNT_USAGE query / login / warehouse history
--                          (e.g. every statement the CI service user ran)
--    - GOVERNANCE_VIEWER : ACCESS_HISTORY, grants, policies
--    - MONITOR on the DCM projects is granted in section 6
-- ---------------------------------------------------------------------
GRANT MONITOR EXECUTION ON ACCOUNT TO ROLE INFOJINI_DATA_ADMIN;
GRANT DATABASE ROLE SNOWFLAKE.USAGE_VIEWER      TO ROLE INFOJINI_DATA_ADMIN;
GRANT DATABASE ROLE SNOWFLAKE.GOVERNANCE_VIEWER TO ROLE INFOJINI_DATA_ADMIN;
GRANT USAGE, MONITOR ON WAREHOUSE INFOJINI_ADMIN_WH TO ROLE INFOJINI_DATA_ADMIN;

-- ---------------------------------------------------------------------
-- 6. Your user + DCM project objects (one per environment)
--    INFOJINI_DATA_ADMIN gives you DEV (via data engineer -> DEV deployer = DEV owner).
--    STAGE / PROD deployers are granted to you ONLY for the few lines that
--    create their project objects, then revoked at the end of this section.
-- ---------------------------------------------------------------------
USE ROLE SECURITYADMIN;
SET MY_USER = CURRENT_USER();
GRANT ROLE INFOJINI_DATA_ADMIN     TO USER IDENTIFIER($MY_USER);
GRANT ROLE INFOJINI_LOADER         TO USER IDENTIFIER($MY_USER);
GRANT ROLE INFOJINI_STAGE_DEPLOYER TO USER IDENTIFIER($MY_USER);   -- temporary, revoked below
GRANT ROLE INFOJINI_PROD_DEPLOYER  TO USER IDENTIFIER($MY_USER);   -- temporary, revoked below

USE ROLE INFOJINI_STAGE_DEPLOYER;
USE WAREHOUSE INFOJINI_ADMIN_WH;
CREATE DCM PROJECT IF NOT EXISTS INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_STAGE
  COMMENT = 'INFOJINI STAGE - deployed by GitHub Actions on merge to main';
GRANT MONITOR ON DCM PROJECT INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_STAGE TO ROLE INFOJINI_DATA_ENGINEER;  -- data admin inherits

USE ROLE INFOJINI_PROD_DEPLOYER;
CREATE DCM PROJECT IF NOT EXISTS INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_PROD
  COMMENT = 'INFOJINI PROD - deployed by GitHub Actions on release tag + approval';
GRANT MONITOR ON DCM PROJECT INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_PROD TO ROLE INFOJINI_DATA_ENGINEER;   -- data admin inherits

-- Remove the temporary STAGE / PROD deployer grants from your user
USE ROLE SECURITYADMIN;
REVOKE ROLE INFOJINI_STAGE_DEPLOYER FROM USER IDENTIFIER($MY_USER);
REVOKE ROLE INFOJINI_PROD_DEPLOYER  FROM USER IDENTIFIER($MY_USER);

-- ---------------------------------------------------------------------
-- 7. Checks
-- ---------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;
SHOW DCM PROJECTS IN SCHEMA INFOJINI_ADMIN_DB.PROJECTS;   -- expect INFOJINI_STAGE, INFOJINI_PROD
SHOW ROLES LIKE 'INFOJINI%';                              -- expect 10
SHOW WAREHOUSES LIKE 'INFOJINI%';                         -- expect 2
SHOW GRANTS TO USER IDENTIFIER($MY_USER);                 -- expect INFOJINI_DATA_ADMIN + INFOJINI_LOADER, NO stage/prod deployer

-- As data admin: you can SEE stage / prod projects but not deploy them
USE ROLE INFOJINI_DATA_ADMIN;
SHOW DCM PROJECTS IN SCHEMA INFOJINI_ADMIN_DB.PROJECTS;   -- expect to see STAGE and PROD
