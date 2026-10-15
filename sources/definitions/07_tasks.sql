-- Scheduling. task_state comes from manifest.yml:
--   DEV = SUSPENDED (run manually: EXECUTE TASK ...), STAGE / PROD = STARTED.

DEFINE TASK {{ db('SILVER') }}.CORE.TSK_DAILY_LOAD
  WAREHOUSE = '{{ wh('TRANSFORM') }}'
  SCHEDULE = '{{ task_schedule }}'
  COMMENT = 'Daily load: Bronze -> Silver customers'
  {{ task_state }}
AS
  CALL {{ db('SILVER') }}.CORE.SP_LOAD_CUSTOMERS();
