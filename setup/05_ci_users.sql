-- =====================================================================
-- setup/05_ci_users.sql
-- Run as : ACCOUNTADMIN (the script switches roles itself)
-- Needs  : setup/01 done
-- Re-run : safe
-- Purpose: GitHub Actions service users, one per pipeline environment.
--   Auth = OIDC (workload identity): no password, no key, no GitHub secret.
--   GitHub sends a token whose subject names the repo + GitHub Environment;
--   Snowflake only accepts it if it matches SUBJECT exactly (case-sensitive).
--   STAGE user can only act as STAGE deployer, PROD user only as PROD deployer.
-- =====================================================================

USE ROLE USERADMIN;

CREATE USER IF NOT EXISTS INFOJINI_STAGE_CI_SVC
  TYPE = SERVICE
  DEFAULT_ROLE = INFOJINI_STAGE_DEPLOYER
  DEFAULT_WAREHOUSE = INFOJINI_ADMIN_WH
  WORKLOAD_IDENTITY = (
    TYPE = OIDC
    ISSUER = 'https://token.actions.githubusercontent.com'
    SUBJECT = 'repo:antariksh247/infojini-snowflake-dcm-framework:environment:INFOJINI_STAGE'
  )
  COMMENT = 'GitHub Actions: deploys STAGE (GitHub Environment INFOJINI_STAGE)';

CREATE USER IF NOT EXISTS INFOJINI_PROD_CI_SVC
  TYPE = SERVICE
  DEFAULT_ROLE = INFOJINI_PROD_DEPLOYER
  DEFAULT_WAREHOUSE = INFOJINI_ADMIN_WH
  WORKLOAD_IDENTITY = (
    TYPE = OIDC
    ISSUER = 'https://token.actions.githubusercontent.com'
    SUBJECT = 'repo:antariksh247/infojini-snowflake-dcm-framework:environment:INFOJINI_PROD'
  )
  COMMENT = 'GitHub Actions: deploys PROD (GitHub Environment INFOJINI_PROD)';

USE ROLE SECURITYADMIN;
GRANT ROLE INFOJINI_STAGE_DEPLOYER TO USER INFOJINI_STAGE_CI_SVC;
GRANT ROLE INFOJINI_PROD_DEPLOYER  TO USER INFOJINI_PROD_CI_SVC;

-- Checks
SHOW USERS LIKE 'INFOJINI%CI_SVC';                 -- 2 users, type SERVICE
SHOW GRANTS TO USER INFOJINI_STAGE_CI_SVC;         -- only INFOJINI_STAGE_DEPLOYER
SHOW GRANTS TO USER INFOJINI_PROD_CI_SVC;          -- only INFOJINI_PROD_DEPLOYER
SHOW GRANTS OF ROLE INFOJINI_PROD_DEPLOYER;        -- only the PROD CI user (no people)

-- ---------------------------------------------------------------------
-- Fallback ONLY if OIDC fails on this account: key-pair auth.
--   1. locally: openssl genrsa 2048 | openssl pkcs8 -topk8 -nocrypt -out ci_key.p8
--               openssl rsa -in ci_key.p8 -pubout -out ci_key.pub
--   2. ALTER USER INFOJINI_STAGE_CI_SVC SET RSA_PUBLIC_KEY = '<ci_key.pub without header/footer>';
--   3. GitHub: Environment secret SNOWFLAKE_PRIVATE_KEY_RAW = content of ci_key.p8
--   (never commit the .p8 file)
-- ---------------------------------------------------------------------
