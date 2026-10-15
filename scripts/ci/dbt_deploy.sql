-- Used by GitHub Actions after the DCM deploy (snow sql -f ... -D ...).
-- Variables: env (STAGE / PROD), target (stage / prod), git_ref (branches/main or tags/v1.0.0)

ALTER GIT REPOSITORY INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO FETCH;

CREATE DBT PROJECT IF NOT EXISTS INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_<% env %>_DBT
  FROM '@INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO/<% git_ref %>/sources/dbt/infojini'
  DEFAULT_TARGET = '<% target %>'
  COMMENT = 'INFOJINI dbt models - <% env %> (deployed by GitHub Actions)';

ALTER DBT PROJECT INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_<% env %>_DBT
  DEPLOY FROM '@INFOJINI_ADMIN_DB.INTEGRATIONS.INFOJINI_REPO/<% git_ref %>/sources/dbt/infojini';

EXECUTE DBT PROJECT INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_<% env %>_DBT
  ARGS = 'build --target <% target %>';
