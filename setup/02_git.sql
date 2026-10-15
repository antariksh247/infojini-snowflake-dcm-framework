-- =====================================================================
-- setup/02_git.sql
-- Run as : ACCOUNTADMIN (the script switches roles itself)
-- Needs  : setup/01_platform.sql done
-- Re-run : safe
-- Purpose: let Snowflake read this GitHub repo
--   - API integration (public repo: no token / secret needed)
--   - Git repository object = Snowflake's read-only copy of the repo
--     (used by DCM "FROM '@...repo/branches/main/'" and as a fallback deploy path)
-- Snowsight Workspaces for developers use the same API integration.
-- =====================================================================

USE ROLE ACCOUNTADMIN;

CREATE API INTEGRATION IF NOT EXISTS INFOJINI_GITHUB_API
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/antariksh247')
  ENABLED = TRUE
  COMMENT = 'GitHub access for the INFOJINI framework repo (public, no secret)';

-- Who may use the integration
GRANT USAGE ON INTEGRATION INFOJINI_GITHUB_API TO ROLE SYSADMIN;                 -- creates the repo object
GRANT USAGE ON INTEGRATION INFOJINI_GITHUB_API TO ROLE INFOJINI_DATA_ENGINEER;   -- Snowsight Workspaces

-- ---------------------------------------------------------------------
-- Git repository object
-- ---------------------------------------------------------------------
USE ROLE SYSADMIN;

CREATE GIT REPOSITORY IF NOT EXISTS INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO
  API_INTEGRATION = INFOJINI_GITHUB_API
  ORIGIN = 'https://github.com/antariksh247/infojini-snowflake-dcm-framework.git'
  COMMENT = 'Read-only copy of the framework repo';

-- READ  = list / read files; WRITE = refresh the copy (FETCH). Nothing here can push to GitHub.
GRANT READ, WRITE ON GIT REPOSITORY INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO TO ROLE INFOJINI_DEV_DEPLOYER;
GRANT READ, WRITE ON GIT REPOSITORY INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO TO ROLE INFOJINI_STAGE_DEPLOYER;
GRANT READ, WRITE ON GIT REPOSITORY INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO TO ROLE INFOJINI_PROD_DEPLOYER;
GRANT READ        ON GIT REPOSITORY INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO TO ROLE INFOJINI_DATA_ENGINEER;

-- ---------------------------------------------------------------------
-- Checks
-- ---------------------------------------------------------------------
ALTER GIT REPOSITORY INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO FETCH;
SHOW GIT BRANCHES IN INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO;          -- expect: main
LS @INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO/branches/main/setup/;      -- expect: 01_platform.sql, 02_git.sql

USE ROLE INFOJINI_DATA_ENGINEER;
LS @INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO/branches/main/;            -- developer can read the repo
