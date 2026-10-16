-- Used by GitHub Actions after the DCM deploy (snow sql -f ... -D ...).
-- Variables: env (STAGE / PROD), target (stage / prod), git_ref (branches/main or tags/v1.0.0)
--
-- CREATE DBT PROJECT accepts Git *branch* paths only, not tags. So the exact
-- version (branch or tag) is first copied from the Git repo into an internal
-- stage per env, and the dbt project is deployed from that stage.

ALTER GIT REPOSITORY INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO FETCH;

CREATE STAGE IF NOT EXISTS INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_<% env %>_DBT_SRC
  COMMENT = 'Source files of the dbt project version deployed to <% env %>';

REMOVE @INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_<% env %>_DBT_SRC;

COPY FILES INTO @INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_<% env %>_DBT_SRC
  FROM @INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO/<% git_ref %>/sources/dbt/infojini/;

CREATE DBT PROJECT IF NOT EXISTS INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_<% env %>_DBT
  FROM '@INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_<% env %>_DBT_SRC'
  DEFAULT_TARGET = '<% target %>'
  COMMENT = 'INFOJINI dbt models - <% env %> (deployed by GitHub Actions)';

ALTER DBT PROJECT INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_<% env %>_DBT
  DEPLOY FROM '@INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_<% env %>_DBT_SRC';

EXECUTE DBT PROJECT INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_<% env %>_DBT
  ARGS = 'build --target <% target %>';
