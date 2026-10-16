-- Task SILVER_DB.CORE.TSK_DBT_BUILD : daily dbt refresh.
-- Runs the dbt project object of this env = exactly the released version.
-- Tables only: views hold no data, they are (re)built by the deploy-time `dbt build`.
-- State from manifest.yml (task_state): STAGE = SUSPENDED, PROD = STARTED.

DEFINE TASK {{ db('SILVER') }}.CORE.TSK_DBT_BUILD
  WAREHOUSE = '{{ wh('TRANSFORM') }}'
  SCHEDULE = '{{ task_schedule }}'
  COMMENT = 'Daily dbt build of tables + tests (views only rebuilt at deploy)'
  {{ task_state }}
AS
  EXECUTE DBT PROJECT INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_{{ env }}_DBT
    ARGS = 'build --target {{ env | lower }} --exclude config.materialized:view';
