-- Scheduling. task_state comes from manifest.yml:
--   DEV = SUSPENDED (run manually: EXECUTE TASK ...), STAGE / PROD = STARTED.
--
-- Daily dbt refresh. Runs the dbt project object of this env, i.e. exactly the
-- released version (deployed by the pipeline). Tables only: views hold no data,
-- they are (re)created only by the deploy-time `dbt build`.

DEFINE TASK {{ db('SILVER') }}.CORE.TSK_DBT_BUILD
  WAREHOUSE = '{{ wh('TRANSFORM') }}'
  SCHEDULE = '{{ task_schedule }}'
  COMMENT = 'Daily dbt build of tables + tests (views only rebuilt at deploy)'
  {{ task_state }}
AS
  EXECUTE DBT PROJECT INFOJINI_ADMIN_DB.PROJECTS.INFOJINI_{{ env }}_DBT
    ARGS = 'build --target {{ env | lower }} --exclude config.materialized:view';
